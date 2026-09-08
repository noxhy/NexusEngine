extends Node
class_name BasicSong

var camera_positions: Array = []

@onready var playstate: PlayState = $"PlayState"

@onready var stage: Node = %Stage
@onready var player: Node = %Player
@onready var enemy: Node = %Enemy

@onready var rating_marker = %"Rating Marker"
@onready var combo_marker = %"Combo Marker"

@onready var rating_node = load("uid://0l7bo1bqcbcj")
@onready var combo_numbers_node = load("uid://b28wu6vajuag3")

# How often the camera bops. Based off the step rate in the conductor.
var bop_rate: int = 16
var bop_rate_offset: int = 0
var pause_preload: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not playstate:
		playstate = $"PlayState Host"
	
	if not playstate:
		printerr("Playstate host not found")
	
	camera_positions = get_tree().get_nodes_in_group(&"camera_positions")
	
	if playstate and playstate.ui:
		if player:
			playstate.ui.update_player(player)
		
		if enemy:
			playstate.ui.update_enemy(enemy)
	
	pause_preload = load(playstate.ui_skin.pause_scene)
	
	await Signals.play_setup_finished
	
	Signals.play_conductor_step_hit.connect(_on_conductor_new_step)
	Signals.play_conductor_beat_hit.connect(_on_conductor_new_beat)
	GameManager.conductor.new_numerator.connect(update_bop_rate)
	GameManager.conductor.new_denominator.connect(update_bop_rate)
	
	Signals.play_combo_break.connect(_on_combo_break)
	Signals.play_create_note.connect(_on_create_note)
	Signals.play_new_event.connect(_on_new_event)
	Signals.play_note_hit.connect(self.note_hit)
	Signals.play_note_holding.connect(self.note_holding)
	Signals.play_note_miss.connect(self.note_miss)
	
	Signals.play_song_ready_to_start.emit()
	Signals.play_died.connect(self.died)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"pause"):
		Global.manual_pause = true
		pause()
	
	if Input.is_action_just_pressed(&"kill"):
		playstate.health = 0
	
	if Input.is_action_just_pressed(&"chart_editor") and OS.is_debug_build():
		ChartManager.event_editor = false
		ChartManager.song = playstate.song_data
		ChartManager.difficulty = GameManager.difficulty
		Global.change_scene_to(Constants.CHART_EDITOR_SCENE)

# Conductor Util
func _on_conductor_new_beat(current_beat: int, measure_relative: int):
	pass


func _on_conductor_new_step(current_step: int, measure_relative: int):
	if playstate:
		if current_step % (bop_rate - bop_rate_offset) == 0:
			if playstate.camera.parent_3d:
				var bump: float = playstate.camera_bop_strength.x * playstate.camera.zoom
				playstate.camera.bump(bump)
			else:
				playstate.camera.bump(playstate.camera_bop_strength)
			
			if SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "ui_bops") and playstate.ui:
				playstate.ui.bump(playstate.ui_bop_strength)


func update_bop_rate(_i: int) -> void:
	bop_rate = GameManager.conductor.numerator * GameManager.conductor.denominator


func _on_create_note(time: float, lane: int, note_length: float, note_type: String, tempo: float):
	if playstate:
		if not playstate.strums.is_empty():
			if (lane > 3):
				playstate.strums[1].create_note(time, lane % 4, note_length, note_type, tempo)
			else:
				playstate.strums[0].create_note(time, lane % 4, note_length, note_type, tempo)


func note_hit(note: BasicNote, lane: int, hit_time: float, strum_manager: StrumManager):
	var group: StringName = get_group_from_manager(strum_manager)
	var anim_to_play: String = note.anim_prefix + get_direction(lane % 4)
	
	if not note.no_animation:
		get_tree().call_group(group, &"play_animation", anim_to_play,
			Character.AnimContext.SING, true)
		
		get_tree().call_group(group, &"set_sing_timer")
	
	if group == &"player":
		show_combo(NoahStats.get_hit_rating(hit_time), playstate.song_stats.combo)
		
		if playstate:
			if playstate.song_stats.combo > 0:
				if (playstate.song_stats.combo % 200 == 0):
					get_tree().call_group(&"metronome", &"play_animation", &"cheer_200")
				elif (playstate.song_stats.combo % 50 == 0):
					get_tree().call_group(&"metronome", &"play_animation", &"cheer")


func note_holding(note: Note, lane: int, hold_difference: float, strum_manager: StrumManager):
	var group: StringName = get_group_from_manager(strum_manager)
	get_tree().call_group(group, &"set_sing_timer")


func note_miss(note: Note, lane: int, strum_manager: StrumManager):
	if !strum_manager.enemy_slot:
		if not note:
			SoundManager.anti_spam.play()
		else:
			get_tree().call_group(&"metronome", &"play_animation", &"cry",
			Character.AnimContext.SPECIAL, true)
	
	get_tree().call_group(
		&"enemy" if strum_manager.enemy_slot else &"player", &"play_animation",
		&"miss_" + get_direction(lane % 4), Character.AnimContext.SING, true)


func get_group_from_manager(strum_manager: StrumManager) -> StringName:
	return &"enemy" if strum_manager.enemy_slot else &"player"


func get_direction(direction: int) -> StringName:
	return [&"left", &"down", &"up", &"right"][direction]


func _on_new_event(time: float, event_name: String, event_parameters: Array):
	match event_name:
		&"play_animation":
			var duration: float = -1
			if event_parameters.get(2) and !event_parameters[2].is_empty():
				duration = Global.string_to_time(event_parameters[2])
			
			get_tree().call_group(event_parameters[0], &"play_animation",
			event_parameters[1], Character.AnimContext.SPECIAL, true, duration)
		&"set_prefix":
			get_tree().set_group(event_parameters[0], &"animation_prefix",
			event_parameters[1])
		&"set_bop_offset":
			bop_rate_offset = int(event_parameters[0])


func _on_combo_break():
	SoundManager.miss.play()
	show_combo(NoahStats.HIT_RATING.MISS, 0)


func show_combo(rating: NoahStats.HIT_RATING, _combo: int):
	if playstate:
		var hit_rating: String
		
		match rating:
			NoahStats.HIT_RATING.SICK:
				hit_rating = "sick"
			
			NoahStats.HIT_RATING.GOOD:
				hit_rating = "good"
			
			NoahStats.HIT_RATING.BAD:
				hit_rating = "bad"
			
			NoahStats.HIT_RATING.SHIT:
				hit_rating = "shit"
			
			_:
				hit_rating = "miss"
		
		if rating != NoahStats.HIT_RATING.MISS:
			if playstate.song_stats.sicks == playstate.song_stats.total_notes:
				hit_rating = str("fc_", hit_rating)
		
		var rating_instance = rating_node.instantiate()
		
		rating_instance.ui_skin = playstate.ui_skin
		rating_instance.animation = hit_rating
		rating_instance.z_index = 1000
		
		var add_numbers: Callable = func(parent: Node) -> void:
			if _combo >= 10:
				var combo_string: String = str(_combo)
				var digits: int = combo_string.length()
				for digit in digits:
					var combo_number_instance = combo_numbers_node.instantiate()
					
					combo_number_instance.position.x = playstate.ui_skin.numbers_spacing * (
						(digits - 1) / -2.0 + digit) * playstate.ui_skin.numbers_scale
					
					combo_number_instance.ui_skin = playstate.ui_skin
					if playstate.song_stats.max_combo == playstate.song_stats.total_notes:
						combo_number_instance.animation = str("fc_", combo_string[digit])
					else:
						combo_number_instance.animation = combo_string[digit]
					
					combo_number_instance.z_index = 1000
					
					parent.add_child(combo_number_instance)
		
		if SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "combo_ui") and playstate.ui:
			if playstate.ui.rating_marker:
				playstate.ui.rating_marker.add_child(rating_instance)
			
			if playstate.ui.combo_marker:
				add_numbers.call(playstate.ui.combo_marker)
		else:
			if rating_marker:
				rating_marker.add_child(rating_instance)
			
			if combo_marker:
				add_numbers.call(combo_marker)


func pause():
	var pause_scene_instance = pause_preload.instantiate()
	
	Signals.play_paused.emit()
	add_child(pause_scene_instance)
	
	get_tree().paused = true


func died():
	pass
