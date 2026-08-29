@icon("uid://cn3dcg1gr2oo4")
extends Node
class_name PlayState

const COMPENSATION: float = 1.0 / 30.0
const DELTA_LENIENCY: float = 0.01

@onready var song_data: Song
@onready var vocals: AudioStreamPlayer
@onready var instrumental: AudioStreamPlayer
@onready var strums: Array = []

@export_group("Nodes")
## The host song script. Usually the parent of this node.
@export var host: Node

@export_group("Resources")
@export var note_skin: NoteSkin
@export var ui_skin: UISkin

@export_group("Scenes")
## The next scene to enter after the song/playlist is finished.
## [br][br][color=khaki]NOTE[/color] this does not apply when [member GameManager.play_mode] is [constant GameManager.PLAY_MODE.CHARTING_MODE].
@export_file('*.tscn') var next_scene: String = ""

@export_group("Data")
## The minimum amount of health the player can have before they "die"
@export var health_min: float = 0.0
## The maximum amount of health the player can have.
@export var health_max: float = 100.0

## The default "bop" strength to be applied to the main camera.
@export_custom(PROPERTY_HINT_LINK, 'x') var camera_bop_strength: Vector2 = Vector2(0.03, 0.03)
## The default "bop" strength to be applied to the ui instance.
@export_custom(PROPERTY_HINT_LINK, 'x') var ui_bop_strength: Vector2 = Vector2(0.015, 0.015)

var song_starting:bool = false
var song_started: bool = false
var song_start_offset: float = -4.0
var song_start_time: float = 0.0
# So it turns out that the track ID's are not sequential and can be whatever number they want, I did this so it'd be easier
var vocal_tracks: Array = []
var vocal_streams: Array = []

var position_delta: float = 0.0
var position_lerp: float = 0.0
var sync_timer: float = 0.0
var song_speed: float = 1.0
var scroll_speed: float = 1.0
# The index of the latest loaded note
var current_note: int = -1
# The index of the latest loaded event
var current_event: int = -1
var output_latency: float = AudioServer.get_output_latency()

var chart: Chart

## Flag enabled whenever the player has "died"
var died: bool = false

## The UI node that requires a list: [code]strums[/code].
@onready var ui: BasicUI
## Camera with built-in functions.
@onready var camera: CameraController

var health: float = health_max * 0.5 : set = set_health

func set_health(v: float):
	v = clampf(v, health_min, health_max)
	
	Signals.play_health_changed.emit(v, v - health)
	health = v

var song_stats: NoahStats = NoahStats.new()

var score: float : 
	get():
		return song_stats.score

var misses: int :
	get():
		return song_stats.misses

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	song_data = GameManager.current_song
	
	ui = get_tree().get_first_node_in_group(&"ui")
	camera = get_tree().get_first_node_in_group(&"cameras")
	
	if !ui:
		printerr("(%s):" % name, " There was no ui within the ui group.")
	
	if !camera:
		printerr("(%s):" % name,' There was no CameraController within the camera group.')
	
	if !host:
		printerr("(%s):" % name,'A Host was not assigned.')
	
	assert(song_data, "A song was not set correctly.")
	
	# This delay is so variables initialize
	if host:
		await host.ready
	
	# Creating the Audio Tracks
	vocals = AudioStreamPlayer.new()
	vocals.stream = AudioStreamPolyphonic.new()
	vocals.stream.polyphony = song_data.vocals.size()
	vocals.set_bus(&"Music")
	for v in song_data.vocals:
		vocal_streams.append(SoundManager.get_stream(v))
	add_child(vocals)
	
	instrumental = AudioStreamPlayer.new()
	instrumental.stream = SoundManager.get_stream(song_data.instrumental)
	instrumental.connect("finished", finished_song)
	instrumental.pitch_scale = song_speed
	instrumental.set_bus(&"Music")
	add_child(instrumental)
	
	vocals.play()
	
	GameManager.reset_conductor()
	
	strums = get_tree().get_nodes_in_group(&"strums")
	
	GameManager.song_scene = LoadingScreen.scene
	
	chart = Chart.load(song_data.difficulties[GameManager.difficulty].chart)
	
	if not song_data.events.is_empty() and ResourceLoader.exists(song_data.events):
		var ext_events = load(song_data.events)
		if ext_events is ChartEvents:
			chart.merge_events_into_this(ext_events)
		else:
			ext_events.free()
	
	song_speed = SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "song_speed")
	
	match GameManager.play_mode:
		GameManager.PLAY_MODE.CHARTING:
			if SettingsManager.get_value(SettingsManager.SEC_CHART, "start_at_current_position"):
				play_song(ChartEditor.song_position)
			else:
				play_song(0)
		
		_:
			play_song(0)
	
	Global.set_window_title("Playing: " + song_data.title)
	
	if SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "botplay"):
		if OS.is_debug_build():
			get_tree().call_group(&"strums", "set_auto_play", true)
			get_tree().call_group(&"strums", "set_press", false)
	
	scroll_speed = chart.scroll_speed * SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "scroll_speed_scale")
	
	get_tree().call_group(&"strums", "set_scroll_speed", scroll_speed)
	get_tree().call_group(&"strums", "set_skin", note_skin)
	get_tree().call_group(&"strums", "set_offset",
	SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "offset"))
	
	if SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "downscroll"):
		get_tree().call_group(&"strums", "set_scroll", -1)
	
	Signals.play_note_hit.connect(note_hit)
	Signals.play_note_holding.connect(note_holding)
	Signals.play_note_miss.connect(note_miss)
	
	Signals.play_setup_finished.emit()

func _process(delta) -> void:
	if health <= health_min and !died:
		GameManager.deaths += 1
		
		GameManager.song_scene = get_tree().current_scene.scene_file_path
		Signals.play_died.emit()
		died = true
	
	# Why is this a thing I have to do
	if is_inside_tree():
		get_tree().call_group(&"note", &"update")
	
	if !song_started and song_starting:
		song_start_offset += delta
		GameManager.song_position = song_start_offset
		GameManager.conductor.time = GameManager.song_position
		
		if song_start_offset >= max(chart.offset, song_start_time):
			play_audios(song_start_time)
			song_starting = false
	else:
		GameManager.song_position = instrumental.get_playback_position() + \
				AudioServer.get_time_since_last_mix() - output_latency
		
		GameManager.conductor.offset = chart.get_tempo_time_at(GameManager.song_position)
		GameManager.conductor.offset += chart.offset
		
		# Idk how exactly this works I stole this code from sqirradotdev
		position_delta = abs(position_lerp - GameManager.song_position)
		position_lerp += delta * instrumental.pitch_scale
		
		if delta > COMPENSATION or sync_timer <= 0.0 or position_delta >= DELTA_LENIENCY * instrumental.pitch_scale:
			if position_delta >= 0.025 * instrumental.pitch_scale:
				position_lerp = GameManager.song_position
			sync_timer = 0.5
		
		GameManager.song_position = position_lerp
		sync_timer -= delta
	
	GameManager.conductor.tempo = chart.get_tempo_at(GameManager.song_position)
	var meter: Array = chart.get_meter_at(GameManager.song_position)
	if meter.is_empty():
		printerr("(PlayState): ", "Chart has no time signatures.")
	else:
		GameManager.conductor.numerator = meter[0]
		GameManager.conductor.denominator = meter[1]
	
	# Instead of before where I would do a linear search per section, a faster method
	# would just be to iterate through as the song is playing, making it faster
	var notes_list = chart.get_notes_data()
	
	if notes_list.size() > 0:
		if current_note < notes_list.size():
			var note = notes_list[current_note]
			
			var spawn_time = GameManager.song_position + GameManager.conductor.seconds_per_beat * 4
			if scroll_speed < 1:
				spawn_time /= scroll_speed 
			
			if note[0] <= (spawn_time):
				var time: float = note[0]
				var lane: int = note[1]
				var length: float = note[2]
				var type: Variant = note[3]
				
				Signals.play_create_note.emit(time, lane, length, type, chart.get_tempo_at(time))
				current_note += 1
	
	if instrumental.playing:
		var events_list = chart.get_events_data()
		if events_list.size() > 0:
			if current_event < events_list.size():
				var event = events_list[current_event]
				if event[0] <= GameManager.song_position:
					var time: float = event[0]
					var event_name: String = event[1]
					var event_parameters: Array = event[2]
					
					print("(PlayState): Song Event: \"", event_name, "\" ", str(event_parameters))
					basic_event(time, event_name, event_parameters)
					current_event += 1


func play_song(time: float):
	await Signals.play_song_ready_to_start
	
	song_starting = true
	
	GameManager.last_song_stats.reset()
	
	GameManager.conductor.stream_player = instrumental
	GameManager.conductor.tempo = chart.get_tempo_at(-chart.offset + time)
	GameManager.conductor.seconds_per_beat = 60.0 / GameManager.conductor.tempo
	
	GameManager.conductor.offset = chart.offset + SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "offset")
	
	song_started = false
	song_start_time = time + chart.offset
	song_start_offset = song_start_time - (GameManager.conductor.seconds_per_beat * 4)
	GameManager.song_position = song_start_offset
	GameManager.conductor.time = song_start_time
	
	if time >= GameManager.conductor.seconds_per_beat * 4:
		play_audios(song_start_offset)
	else:
		if !ui_skin.countdown.is_empty() and ui:
			var countdown_instance: AnimationPlayer = load(ui_skin.countdown).instantiate()
			
			countdown_instance.speed_scale = chart.get_tempo_at(time - chart.offset) / 60.0
			
			ui.add_child(countdown_instance)
			countdown_instance.seek(time)
	
	var notes_list = chart.get_notes_data()
	current_note = bsearch_left_range(notes_list, time)
	current_event = 0

# This if for actually playing the audio tracks, the reason this is a function is because
# I also call it in the process function for when the song starts before 4 beats are possible.
func play_audios(time: float):
	var playback = vocals.get_stream_playback()
	
	for stream in vocal_streams:
		vocal_tracks.append(playback.play_stream(stream, time, \
		0.0, song_speed))
	instrumental.play(time)
	instrumental.pitch_scale = song_speed
	if not song_started:
		Signals.play_song_start.emit()
	song_started = true

# Binary Search of notes and events, gives the index of the note nearest to the given time
func bsearch_left_range(value_set: Array, left_range: float) -> int:
	var length = value_set.size()
	if (length == 0):
		return -1
	if (value_set[length - 1][0] < left_range):
		return -1
	
	var low: int = 0
	var high: int = length - 1
	
	while (low <= high):
		var mid: int = (low + high) / 2
		
		if (value_set[mid][0] >= left_range):
			high = mid - 1
		else:
			low = mid + 1
	
	return high + 1


func score_note(hit_time: float):
	var factor: float = 1.0 - (1.0 / (1.0 + exp(-Constants.SCORING_SLOPE * ((abs(hit_time) - Constants.SCORING_OFFSET) * 1000))))
	var add: float = Constants.MAX_SCORE_GAIN * factor + Constants.MIN_SCORE_GAIN
	add = clamp(add, Constants.MIN_SCORE_GAIN, Constants.MAX_SCORE_GAIN)
	song_stats.score += add
	Signals.play_stats_changed.emit(song_stats)


func basic_event(time: float, event_name: String, event_parameters: Array):
	match event_name:
		"camera_position":
			if host:
				if host.camera_positions.size() == 0:
					printerr('(PlayState): no camera_positions exist')
					return
				
				if camera:
					var index: int = int(event_parameters[0])
					var marker = host.camera_positions[index]
					if !marker:
						printerr("(PlayState): Marker does not exist at index: ", index)
						return
					
					var easing = event_parameters.get(2)
					if !easing or easing.is_empty():
						easing = "classic"
					
					if easing.to_lower() == "classic":
						camera.go_to_marker(marker)
					else:
						camera.tween_to_marker(marker, Global.string_to_time(event_parameters.get(1)) / song_speed, event_parameters.get(2))
		
		"camera_bop":
			if camera:
				var camera_bop: float = camera_bop_strength.x
				if not event_parameters[0].is_empty():
					camera_bop = float(event_parameters[0])
				
				camera.bump(camera_bop)
			
			if ui:
				var ui_bop: float = ui_bop_strength.x
				if not event_parameters[1].is_empty():
					ui_bop = float(event_parameters[1])
				
				ui.bump(Vector2.ONE * ui_bop)
		
		"psych_camera_zoom":
			if camera:
				var new_zoom = Vector2(float(event_parameters[0]), float(event_parameters[0]))
				camera.target_zoom = new_zoom
		
		"camera_zoom":
			if camera:
				var new_zoom = Vector2(float(event_parameters[0]), float(event_parameters[0]))
				var zoom_time = Global.string_to_time(event_parameters[1])
				var _ease: String = "CLASSIC"
				
				var ease_string = event_parameters.get(2)
				if ease_string:
					_ease = ease_string
				
				if _ease.to_lower() == "classic":
					camera.target_zoom = new_zoom
				else:
					camera.tween_zoom(new_zoom, zoom_time / song_speed, _ease)
		
		"bop_rate", "bop_delay":
			if host:
				host.bop_rate = int(event_parameters[0])
		
		"bop_strength":
			camera_bop_strength = Vector2.ONE * float(event_parameters[0])
			ui_bop_strength = Vector2.ONE * float(event_parameters[1])
		
		"set_smoothing", 'lerping':
			var smoothing: bool = event_parameters[0] == "true"
			
			if camera:
				camera.zoom_smoothing = smoothing
			
			if ui:
				ui.zoom_smoothing = smoothing
		
		"scroll_speed":
			var tween_time: float = Global.string_to_time(event_parameters[1])
			
			scroll_speed = float(event_parameters[0]) * SettingsManager.get_value(
				SettingsManager.SEC_GAMEPLAY, "scroll_speed_scale")
			
			for strum in strums:
				for lane in strum.strums.size() - 1:
					create_tween().tween_method(
						strum.set_scroll_speed, strum.get_scroll_speed(lane), scroll_speed, tween_time / song_speed)
		
		"camera_shake":
			if camera:
				camera.shake(int(event_parameters[0]), Global.string_to_time(event_parameters[1]) / song_speed)
	
	Signals.play_new_event.emit(time, event_name, event_parameters)

func finished_song():
	Signals.play_song_finished.emit()
	var scene_to_enter: String = next_scene
	
	match GameManager.play_mode:
		GameManager.PLAY_MODE.FREEPLAY:
			GameManager.save_and_refresh_stats(song_stats)
		GameManager.PLAY_MODE.PLAYLIST:
			GameManager.save_and_refresh_stats(song_stats)
			if GameManager.week_songs.size() != GameManager.current_week_song:
				scene_to_enter = GameManager.week_songs[GameManager.current_week_song].scene
		GameManager.PLAY_MODE.CHARTING:
			scene_to_enter = Constants.CHART_EDITOR_SCENE
	
	if scene_to_enter.is_empty() or not ResourceLoader.exists(scene_to_enter):
		printerr("(PlayState): next_scene at %s was not found. falling back to ChartEditor." % scene_to_enter)
		scene_to_enter = Constants.CHART_EDITOR_SCENE
	
	Global.change_scene_to(scene_to_enter)

# Strum Util
func note_hit(note: Note, lane: int, hit_time: float, strum_manager: StrumManager):
	var playback: AudioStreamPlayback = vocals.get_stream_playback()
	if vocal_tracks.size() == 1:
		playback.set_stream_volume(vocal_tracks[0], linear_to_db(1.0))
	elif vocal_tracks.size() > strum_manager.id:
		playback.set_stream_volume(vocal_tracks[strum_manager.id], linear_to_db(1.0))
	
	if !strum_manager.enemy_slot:
		if SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "hit_sounds"):
			SoundManager.hit.play()
		
		if note.mine:
			Signals.play_note_miss.emit(note, lane, strum_manager)
			return
		
		if note.scoreable:
			score_note(hit_time)
		
		song_stats.total_notes += 1
		match NoahStats.get_hit_rating(hit_time):
			NoahStats.HIT_RATING.SICK:
				song_stats.sicks += 1
				health += Constants.HEALTH_GAIN * note.health_mult
				strum_manager.create_splash(lane, note.splash_animation)
				if note.scoreable:
					add_combo()
			NoahStats.HIT_RATING.GOOD:
				song_stats.goods += 1
				health += Constants.HEALTH_GAIN * note.health_mult
				if note.scoreable:
					add_combo()
			NoahStats.HIT_RATING.BAD:
				song_stats.bads += 1
				health -= Constants.BAD_HIT_HEALTH_PENALTY * note.health_mult
				if note.scoreable:
					reset_combo()
			NoahStats.HIT_RATING.SHIT:
				song_stats.shits += 1
				health -= Constants.BAD_HIT_HEALTH_PENALTY * note.health_mult
				if note.scoreable:
					reset_combo()
			_:
				note_miss(note, lane, strum_manager)


func note_holding(note: Note, lane: int, hold_difference: float, strum_manager: StrumManager):
	var playback: AudioStreamPlayback = vocals.get_stream_playback()
	if vocal_tracks.size() > strum_manager.id:
		playback.set_stream_volume(vocal_tracks[strum_manager.id],  linear_to_db(1.0))
	
	if !strum_manager.enemy_slot:
		health += hold_difference * Constants.HOLD_HEALTH_GAIN_PER_SECOND
		
		if note.scoreable:
			song_stats.score += hold_difference * Constants.HOLD_SCORE_GAIN_PER_SECOND
			Signals.play_stats_changed.emit(song_stats)


func note_miss(note: Note, lane: int, strum_manager: StrumManager):
	var playback: AudioStreamPlayback = vocals.get_stream_playback()
	if vocal_tracks.size() > strum_manager.id:
		if (note and !note.mine) or !note:
			playback.set_stream_volume(vocal_tracks[strum_manager.id], linear_to_db(0.0))
	
	if !strum_manager.enemy_slot:
		# Ghost tapping
		if not note:
			song_stats.score -= Constants.SPAM_SCORE_PENALTY
			Signals.play_stats_changed.emit(song_stats)
			
			health -= Constants.SPAM_HEALTH_PENALTY
		elif note.scoreable:
			if note.mine and !note.hit:
				return
			
			song_stats.score -= Constants.SPAM_SCORE_PENALTY
			
			health -= min(Constants.MISS_BASE_HEALTH_PENALTY + (song_stats.combo / Constants.COMBO_SLOPE) + (note.length * Constants.HOLD_HEALTH_GAIN_PER_SECOND),
			Constants.MISS_MAX_HEALTH_PENALTY) * note.damage_mult
			reset_combo()
			
			song_stats.misses += 1
			song_stats.total_notes += 1
			
			Signals.play_stats_changed.emit(song_stats)
			Signals.play_combo_break.emit()


func add_combo():
	song_stats.combo += 1
	
	if song_stats.combo > song_stats.max_combo:
		song_stats.max_combo = song_stats.combo
	Signals.play_stats_changed.emit(song_stats)

func reset_combo():
	song_stats.combo = 0
	Signals.play_stats_changed.emit(song_stats)
