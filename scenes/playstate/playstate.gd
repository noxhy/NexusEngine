@icon( "res://assets/sprites/nodes/play_state.png" )
extends Node
class_name PlayState

const COMPENSATION = 1.0 / 30.0
const SCORING_SLOPE = 0.08
const SCORING_OFFSET = 0.05499
const MIN_SCORE = 9
const MAX_SCORE = 500

signal create_note( time: float, lane: int, note_length: float, note_type: int, tempo: float )
signal new_event( time: float, event_name: String, event_parameters: Array )
signal combo_break()
signal setup_finished()

@onready var rating_node = preload( "res://scenes/instances/playstate/rating.tscn" )
@onready var combo_numbers_handeler_node = preload( "res://scenes/instances/playstate/combo_numbers_handeler.tscn" )
@onready var countdown_node = preload( "res://scenes/playstate/countdown.tscn" )

@export_group("Nodes")

@export var host: Node2D
@export var ui: CanvasLayer
@export var camera: PlayStateCamera
@export var conductor: Conductor
@export var music_host: Node

@export_group("Positions")

@export var rating_position: Marker2D
@export var combo_position: Marker2D

@export_group("Resources")

@export var song_data: Song
@export var note_skin: NoteSkin
@export var ui_skin: UISkin

@export_group("Values")

@export var combo_scale_multiplier = Vector2( 1, 1 )

@export_group("Scenes")

@export var death_scene = "res://scenes/playstate/death_screen.tscn"
var death_stats = {
	
	"death_screen" = death_scene,
	"player_scale" = Vector2( 1, 1 ),
	"player_position" = Vector2( 640, 360 ),
	"camera_zoom" = Vector2( 1, 1 ),
	
}

@export var pause_scene = "res://scenes/playstate/pause_menu.tscn"
@export var next_scene = "res://scenes/story mode/story_mode.tscn"

var strums: Array = []
var characters: Array = []

# How often the damera bops. Based off the step rate in the conductor.
var bop_rate: int = 16

var song_started: bool = false
var song_start_offset: float = -4.0
var song_start_time: float = 0.0
# So it turns out that the track ID's are not sequential and can be whatever number they want, I did this so it'd be easier
var vocal_tracks: Array = []

var song_position: float = 0.0
var position_delta: float = 0.0
var position_lerp: float = 0.0
var sync_timer: float = 0.0
var song_speed: float = 1.0

# The index of the latest loaded note
var current_note: int = -1
# The index of the latest loaded event
var current_event: int = -1

var chart: Chart

var accuracy: float
var timings_sum: float
var entries: float = 0
var misses: int = 0
var score: int = 0
var health: float = 50.0
var combo: int = 0

var camera_bop_strength = Vector2( 0.05, 0.05 )
var ui_bop_strength = Vector2( 0.025, 0.025 )

var self_delta: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# This delay is so variables initialize
	await host.ready
	
	Global.song_scene = Global.new_scene
	
	chart = load(song_data.difficulties[GameHandeler.difficulty].chart)
	
	music_host.get_node("Instrumental").stream = song_data.instrumental
	music_host.get_node("Instrumental").connect( "finished", song_finished )
	
	song_speed = SettingsHandeler.get_setting( "song_speed" )
	# This is to prevent null references
	music_host.get_node("Vocals").play()
	music_host.get_node("Instrumental").pitch_scale = song_speed
	
	music_host.get_node("Hit Sound").stream = note_skin.hit_sound
	
	host.ui_skin = ui_skin
	
	ui.set_credits( song_data.title, song_data.artist )
	play_song( 0.0 )
	
	pause_scene = ui_skin.pause_scene
	
	strums = ui.strums
	
	if SettingsHandeler.get_setting("botplay"):
		
		for strum in strums:
			
			strum.set_auto_play( true )
			strum.set_press( false )
	
	if SettingsHandeler.get_setting( "downscroll" ): ui.downscroll_ui()
	# Streamer mode is supposed to be for when you're recording a video or streaming
	# If you wanted a spook like where the game says your user's name I recommend utilizing this
	if SettingsHandeler.get_setting( "streamer_mode" ): ui.streamer_ui()
	
	for strum in ui.strums:
		
		strum.set_scroll_speed( chart.scroll_speed * SettingsHandeler.get_setting( "scroll_speed_scale" ) )
		strum.connect( "note_hit", host.note_hit )
		strum.connect( "note_holding", host.note_holding )
		strum.connect( "note_miss", host.note_miss )
		strum.set_offset( chart.offset + SettingsHandeler.get_setting( "offset" ) )
		strum.set_skin( note_skin )
		
		if SettingsHandeler.get_setting( "downscroll" ): strum.set_scroll( -1 )
	
	emit_signal("setup_finished")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	accuracy = ( timings_sum / entries ) if entries != 0.0 else 0.0
	self_delta = delta
	
	health = clamp( health, 0.0, 100.0 )
	ui.target_health = health
	
	if health <= 0:
		
		GameHandeler.deaths += 1
		death_stats.camera_zoom = camera.zoom
		Global.song_scene = get_tree().current_scene.scene_file_path
		Global.death_stats = death_stats
		get_tree().change_scene_to_file( death_scene )


func _process(delta):
	
	var window_title = song_data.title
	
	var song_position = int( music_host.get_node("Instrumental").get_playback_position() )
	var song_end_position = int( music_host.get_node("Instrumental").stream.get_length() )
	
	window_title += " - " + Global.float_to_time( song_position )
	window_title += " / " + Global.float_to_time( song_end_position )
	
	Global.set_window_title( window_title )
	
	if Input.is_action_just_pressed( "ui_cancel" ) || Input.is_action_just_pressed( "ui_accept" ):
		
		var pause_scene_instance = load( pause_scene ).instantiate()
		
		pause_scene_instance.song_title = song_data.title
		pause_scene_instance.credits = song_data.artist
		if GameHandeler.freeplay: pause_scene_instance.deaths = GameHandeler.deaths
		
		else: pause_scene_instance.deaths = GameHandeler.week_deaths
		
		host.add_child( pause_scene_instance )
		get_tree().paused = true
	
	elif Input.is_action_just_pressed("kill"): health = 0
	
	
	if !song_started:
		
		song_start_offset += delta
		song_position = song_start_offset
		
		if song_start_offset >= song_start_time:
			
			play_audios( song_start_time )
			ui.show_credits()
	else:
		
		song_position = music_host.get_node("Instrumental").get_playback_position() + \
				AudioServer.get_time_since_last_mix() - \
				AudioServer.get_output_latency()
	
	# Idk how exactly this works I stole this code from sqirradotdev
	
	position_delta = abs( position_lerp - song_position )
	position_lerp += delta * music_host.get_node("Instrumental").pitch_scale
	
	if delta > COMPENSATION || sync_timer <= 0.0 || position_delta >= 0.01 * music_host.get_node("Instrumental").pitch_scale:
		
		if position_delta >= 0.025 * music_host.get_node("Instrumental").pitch_scale: position_lerp = song_position
		sync_timer = 0.5
	
	sync_timer -= delta
	conductor.tempo = get_tempo_at( clamp( song_position, 0, music_host.get_node("Instrumental").stream.get_length() ) )
	
	
	# Instead of before where I would do a linear search per section, a faster method
	# would just be to iterate through as the song is playing, making it faster
	var notes_list = chart.get_notes_data()
	
	if current_note < notes_list.size():
		
		var note = notes_list[current_note]
		
		if note[0] <= ( song_position + conductor.seconds_per_beat * 4 ):
			
			var time: float = note[0]
			var lane: int = note[1]
			var length: float = note[2]
			var type: int = note[3]
			
			emit_signal( "create_note", time, lane, length, type, get_tempo_at( time ) )
			current_note += 1
	
	for strum in strums:
		
		strum.set_tempo( conductor.tempo )
		strum.set_song_position( position_lerp )
		strum.set_song_speed( music_host.get_node("Instrumental").pitch_scale )
	
	if music_host.get_node("Instrumental").playing:
		
		var events_list = chart.get_events_data()
		
		if current_event < events_list.size():
			
			var event = events_list[current_event]
			
			if event[0] <= song_position:
				
				var time: float = event[0]
				var event_name: String = event[1]
				var event_parameters: Array = event[2]
				
				print( "Song Event: ", event_name, " ", str(event_parameters) )
				basic_event( time, event_name, event_parameters )
				current_event += 1


#
# Util
#

##  Gets the tempo at a certain time in seconds
func get_tempo_at(time: float) -> float:
	
	var tempo_dict = chart.get_tempos_data()
	var keys = tempo_dict.keys()
	
	var tempo_output = 0.0
	
	for i in keys.size():
		var dict_time = keys[i]
		
		if time >= dict_time:
			tempo_output = tempo_dict.get(keys[i])
		else:
			continue
	
	return tempo_output


func play_song( time: float ):
	
	GameHandeler.started_song()
	conductor.tempo = get_tempo_at( -chart.offset + time )
	conductor.seconds_per_beat = 60.0 / conductor.tempo
	conductor.offset = chart.offset + SettingsHandeler.get_setting( "offset" )
	var seconds_per_beat = ( 60.0 / conductor.tempo )
	
	song_started = false
	song_start_time = time - chart.offset
	song_start_offset = song_start_time - ( seconds_per_beat * 4 )
	
	if time >= seconds_per_beat * 4: play_audios( time )
	
	else:
		
		var countdown_instance = countdown_node.instantiate()
		
		countdown_instance.speed_scale = get_tempo_at( -chart.offset + time ) / 60.0
		
		ui.add_child( countdown_instance )
		
		countdown_instance.play( ui_skin.countdown_animation )
		countdown_instance.seek( time )
	
	var notes_list = chart.get_notes_data()
	current_note = bsearch_left_range( notes_list, notes_list.size(), time )
	var events_list = chart.get_events_data()
	current_event = bsearch_left_range( events_list, events_list.size(), time )


# This if for actually playing the audio tracks, the reason this is a function is because
# I also call it in the process function for when the song starts before 4 beats are possible.
func play_audios( time: float ):
	
	music_host.get_node("Vocals").stream.polyphony = song_data.vocals.size()
	var playback = music_host.get_node("Vocals").get_stream_playback()
	for stream in song_data.vocals:
		
		vocal_tracks.append( playback.play_stream( stream, -chart.offset + song_start_offset, \
		0.0, song_speed ) )
	music_host.get_node("Instrumental").play( -chart.offset + song_start_offset )
	song_started = true


## Binary Search of notes and events, gives the index of the note nearest to the given time
func bsearch_left_range( value_set: Array, length: int, left_range: float ) -> int:
	
	if ( length == 0 ): return -1
	if ( value_set[ length - 1 ][0] < left_range ): return -1
	
	var low: int = 0
	var high: int = length - 1
	
	while ( low <= high ):
		
		var mid: int = low + int( ( high - low ) / 2 )
		
		if ( value_set[mid][0] >= left_range ): high = mid - 1
		else: low = mid + 1
	
	return high + 1



func get_rating( time: float ) -> String:
	
	var rating: String
	
	var ratings = [
		# [ time <= 0.0125, "epic" ], This is useless now because of how gold perfect works
		# im keeping it tho just in case people want it
		[ time <= 0.045, "sick" ],
		[ time <= 0.090, "good" ],
		[ time <= 0.135, "bad" ],
		[ time <= 0.160, "shit" ],
		[ true, "miss" ],
	]
	
	for condition in ratings:
		
		if condition[0]:
			
			rating = condition[1]
			break
	
	return rating


func score_note( hit_time: float ):
	
	var factor: float = 1.0 - ( 1.0 / ( 1.0 + exp( -SCORING_SLOPE * ( ( hit_time - SCORING_OFFSET ) * 1000 ) ) ) )
	var add: int = int( MAX_SCORE * factor + MIN_SCORE )
	add = clamp( add, MIN_SCORE, MAX_SCORE )
	score += add


func basic_event( time: float, event_name: String, event_parameters: Array ):
	
	if event_name == "camera_position":
		
		var camera_position = host.camera_positions[ int( event_parameters[0] ) ].global_position
		camera_position += ui.offset
		if camera_position != null: camera.position = camera_position
	
	elif event_name == "camera_bop":
		
		var camera_bop = float( event_parameters[0] )
		var ui_bop = float( event_parameters[1] )
		
		camera.zoom += Vector2( camera_bop, camera_bop )
		ui.scale += Vector2( ui_bop, ui_bop )
	
	elif event_name == "camera_zoom":
		
		var new_zoom = Vector2( float( event_parameters[0] ), float( event_parameters[0] ) )
		var zoom_time = 0 if event_parameters[1] == "" else float( event_parameters[1] )
		
		var tween = create_tween()
		tween.set_trans( Tween.TRANS_CUBIC ).set_ease( Tween.EASE_OUT )
		tween.tween_property( camera, "target_zoom", new_zoom, zoom_time * song_speed )
	
	elif event_name == "bop_delay" || event_name == "bop_rate":
		bop_rate = int( event_parameters[0] )
	
	elif event_name == "camera_bop_strength":
		camera_bop_strength = Vector2( float( event_parameters[0] ), float( event_parameters[0] ) )
	
	elif event_name == "ui_bop_strength":
		ui_bop_strength = Vector2( float( event_parameters[0] ), float( event_parameters[0] ) )
	
	elif event_name == "lerping":
		
		var lerping = true if event_parameters[0] == "true" else false
		ui.lerping = lerping
		camera.lerping = lerping
	
	elif event_name == "scroll_speed":
		
		var scroll_speed = float( event_parameters[0] )
		var tween_time = 0 if event_parameters[1] == "" else float( event_parameters[1] )
		
		for strum in strums:
			
			for lane in strum.strums.size() - 1:
				
				var tween = create_tween()
				tween.set_trans( Tween.TRANS_CUBIC ).set_ease( Tween.EASE_OUT )
				var scroll_speed_scale: float = SettingsHandeler.get_setting( "scroll_speed_scale" )
				tween.tween_method( strum.set_scroll_speed, strum.get_scroll_speed( lane ), scroll_speed * scroll_speed_scale, tween_time * song_speed )
	
	elif event_name == "camera_shake":
		
		camera.shake( int( event_parameters[0] ), float( event_parameters[1] ) )
	
	emit_signal( "new_event", time, event_name, event_parameters )


func song_finished():
	
	GameHandeler.finished_song(score)
	Transitions.transition("down")
	
	await get_tree().create_timer(1).timeout
	
	if GameHandeler.freeplay:
		
		GameHandeler.reset_stats()
		if GameHandeler.play_mode == GameHandeler.PLAY_MODE.CHARTING: get_tree().change_scene_to_file("res://scenes/chart editor/chart_editor.tscn")
		else: get_tree().change_scene_to_file("res://scenes/freeplay/freeplay.tscn")
	else:
		
		Global.change_scene_to( next_scene )


# Conductor Util


func new_beat(current_beat, measure_relative):
	
	ui.icon_bop( conductor.seconds_per_beat * 0.5 * ( 1 / music_host.get_node("Instrumental").pitch_scale ) )


func new_step(current_step, measure_relative):
	
	if current_step % bop_rate == 0:
		
		camera.zoom += camera_bop_strength
		if SettingsHandeler.get_setting( "ui_bops" ): ui.scale += ui_bop_strength


# Strum Util


func note_hit(time, lane, note_type, hit_time, strum_handeler):
	
	var playback = music_host.get_node("Vocals").get_stream_playback()
	if vocal_tracks.size() > strum_handeler.id: playback.set_stream_volume( vocal_tracks[strum_handeler.id], 0.0 )
	
	if !strum_handeler.enemy_slot:
		
		if SettingsHandeler.get_setting("hit_sounds"): music_host.get_node("Hit Sound").play()
		
		var rating = get_rating(abs(hit_time))
		var strum_node = strum_handeler.get_strum(lane)
		
		GameHandeler.tallies[rating] += 1
		GameHandeler.tallies["total_notes"] += 1
		score_note(hit_time)
		
		if rating == "epic":
			
			health += 2
			timings_sum += 1
			strum_handeler.create_splash( lane, strum_node.strum_name + " splash" )
		
		elif rating == "sick":
			
			health += 1
			timings_sum += 0.9825
			strum_handeler.create_splash( lane, strum_node.strum_name + " splash" )
		
		elif rating == "good":
			timings_sum += 0.65
		
		elif rating == "bad":
			
			health -= 0.5
			timings_sum += 0.25
			combo = -1
			
			note_miss( time, lane, 0, -1, hit_time, strum_handeler )
			emit_signal("combo_break")
		
		elif rating == "shit":
			
			health -= 1
			timings_sum += -1
			combo = -1
			
			note_miss( time, lane, 0, -1, hit_time, strum_handeler )
			emit_signal("combo_break")
		
		else:
			
			note_miss( time, lane, 0, note_type, hit_time, strum_handeler )
		
		entries += 1
		combo += 1
		if combo > GameHandeler.tallies["max_combo"]: GameHandeler.tallies["max_combo"] = combo
		
		accuracy = ( timings_sum / entries )
		if ( GameHandeler.tallies.epic + GameHandeler.tallies.sick ) == GameHandeler.tallies.total_notes:
			rating = "fc_" + rating
		
		show_combo( rating, combo )
		
		update_ui_stats()


func note_holding(time, lane, note_type, strum_handeler):
	
	var playback = music_host.get_node("Vocals").get_stream_playback()
	if vocal_tracks.size() > strum_handeler.id: playback.set_stream_volume( vocal_tracks[strum_handeler.id], 0.0 )
	
	if !strum_handeler.enemy_slot:
		
		health += self_delta * 5
		score += round( self_delta * ( MAX_SCORE / 4.0 ) )
		
		timings_sum += self_delta
		entries += self_delta
		
		accuracy = ( timings_sum / entries )
		
		update_ui_stats()


func note_miss(time, lane, length, note_type, hit_time, strum_handeler):
	
	var playback = music_host.get_node("Vocals").get_stream_playback()
	if vocal_tracks.size() > strum_handeler.id: playback.set_stream_volume( vocal_tracks[strum_handeler.id], -80.0 )
	
	if !strum_handeler.enemy_slot:
		
		if note_type == -1:
			
			score -= 10
			health -= ( 1 + clamp( combo / 20.0, 0, 20 ) ) * ( length + 1 )
			update_ui_stats()
		
		else:
			
			score -= 10
			health -= ( 4 + clamp( combo / 20.0, 0, 20 ) ) * ( length + 1 )
			combo = 0
			misses += 1
			 
			GameHandeler.tallies["miss"] += 1
			GameHandeler.tallies["total_notes"] += 1
			entries += 1 + length
			accuracy = ( timings_sum / entries )
			
			show_combo( "miss", combo )
			emit_signal("combo_break")
			update_ui_stats()


func update_ui_stats():
	
	ui.accuracy = accuracy
	ui.misses = misses
	ui.target_health = health
	ui.score = score
	ui.rank = GameHandeler.get_rank()


# Visual Util


func show_combo( rating: String, combo: int ):
	
	var rating_instance = rating_node.instantiate()
	
	rating_instance.ui_skin = ui_skin
	rating_instance.rating = rating
	
	var combo_numbers_handeler_instance = combo_numbers_handeler_node.instantiate()
	
	combo_numbers_handeler_instance.ui_skin = ui_skin
	combo_numbers_handeler_instance.combo = combo
	if misses == 0: combo_numbers_handeler_instance.fc = true
	
	
	if SettingsHandeler.get_setting( "combo_ui" ):
		
		rating_instance.position = Vector2( -32, 88 )
		combo_numbers_handeler_instance.position = Vector2( 96, 152 )
		
		ui.add_child( rating_instance )
		ui.add_child( combo_numbers_handeler_instance )
	else:
		
		rating_instance.position = rating_position.global_position + ui.offset
		combo_numbers_handeler_instance.position = combo_position.global_position + ui.offset
		rating_instance.scale *= combo_scale_multiplier
		combo_numbers_handeler_instance.scale *= combo_scale_multiplier
		
		self.add_child( rating_instance )
		self.add_child( combo_numbers_handeler_instance )
