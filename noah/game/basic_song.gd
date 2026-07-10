extends Node
class_name BasicSong

var camera_positions: Array = []

@onready var playstate_host: PlayState = $"PlayState"

@onready var stage: Node = %Stage
@onready var player: Node = %Player
@onready var enemy: Node = %Enemy

@onready var rating_marker = %"Rating Marker"
@onready var combo_marker = %"Combo Marker"

@onready var rating_node = load("uid://0l7bo1bqcbcj")
@onready var combo_numbers_manager_node = load("uid://bvreww5500i5g")

# How often the camera bops. Based off the step rate in the conductor.
var bop_rate: int = 16

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not playstate_host:
		playstate_host = $"PlayState Host"
	
	assert(playstate_host, "Playstate host not found")
	camera_positions = get_tree().get_nodes_in_group(&"camera_positions")
	
	if player:
		playstate_host.ui.update_player(player)
	
	if enemy:
		playstate_host.ui.update_enemy(enemy)
	
	await Signals.play_setup_finished
	
	Signals.play_conductor_step_hit.connect(_on_conductor_new_step)
	Signals.play_conductor_beat_hit.connect(_on_conductor_new_beat)
	
	Signals.play_combo_break.connect(_on_combo_break)
	Signals.play_create_note.connect(_on_create_note)
	Signals.play_new_event.connect(_on_new_event)
	Signals.play_note_hit.connect(self.note_hit)
	Signals.play_note_holding.connect(self.note_holding)
	Signals.play_note_miss.connect(self.note_miss)
	
	Signals.play_song_ready_to_start.emit()
	Signals.play_died.connect(self.died)

# Conductor Util
func _on_conductor_new_beat(current_beat: int, measure_relative: int):
	pass

func _on_conductor_new_step(current_step: int, measure_relative: int):
	if current_step % bop_rate == 0:
		if playstate_host.camera.parent_3d:
			var bump: float = playstate_host.camera_bop_strength.x * playstate_host.camera.zoom
			playstate_host.camera.bump(bump)
		else:
			var bump: Vector2 = playstate_host.camera_bop_strength * playstate_host.camera.zoom
			playstate_host.camera.bump(bump)
		
		if SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "ui_bops"):
			playstate_host.ui.bump(playstate_host.ui_bop_strength)


func _on_create_note(time: float, lane: int, note_length: float, note_type: String, tempo: float):
	if (lane > 3):
		playstate_host.strums[1].create_note(time, lane % 4, note_length, note_type, tempo)
	else:
		playstate_host.strums[0].create_note(time, lane % 4, note_length, note_type, tempo)


func note_hit(note: BasicNote, lane: int, hit_time: float, strum_manager: StrumManager):
	var group: StringName = get_group_from_manager(strum_manager)
	var anim_to_play: String = note.anim_prefix +  get_direction(lane % 4)
	
	if not note.no_animation:
		get_tree().call_group(group, &"play_animation", anim_to_play,
			Character.AnimContext.SING, true)
		
		get_tree().call_group(group, &"set_sing_timer")
	
	if group == &"player":
		show_combo(PlayState.get_rating(hit_time), playstate_host.combo)
		
		if playstate_host.combo > 0:
			if (playstate_host.combo % 200 == 0):
				get_tree().call_group(&"metronome", &"play_animation", &"cheer_200")
			elif (playstate_host.combo % 50 == 0):
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


func _on_combo_break():
	SoundManager.miss.play()
	show_combo("miss", 0)


func show_combo(rating: String, _combo: int):
	if rating != "miss":
		if GameManager.tallies.sick == GameManager.tallies.total_notes:
			rating = "fc_" + rating
	
	var rating_instance = rating_node.instantiate()
	
	rating_instance.ui_skin = playstate_host.ui_skin
	rating_instance.rating = rating
	
	var combo_numbers_manager_instance = combo_numbers_manager_node.instantiate()
	
	combo_numbers_manager_instance.ui_skin = playstate_host.ui_skin
	combo_numbers_manager_instance.combo = _combo
	if GameManager.tallies.max_combo == GameManager.tallies.total_notes:
		combo_numbers_manager_instance.fc = true
	
	if SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "combo_ui"):
		if playstate_host.ui.rating_marker:
			rating_instance.position = playstate_host.ui.rating_marker.position
		
		if playstate_host.ui.combo_marker:
			combo_numbers_manager_instance.position = playstate_host.ui.combo_marker.position
		
		playstate_host.ui.add_child(rating_instance)
		playstate_host.ui.add_child(combo_numbers_manager_instance)
	else:
		if rating_marker:
			rating_instance.position = rating_marker.global_position
			rating_instance.scale = rating_marker.scale
			rating_instance.z_index = 1000
		
		if combo_marker:
			combo_numbers_manager_instance.position = combo_marker.global_position
			combo_numbers_manager_instance.scale = combo_marker.scale
			combo_numbers_manager_instance.z_index = 1000
		
		self.add_child(rating_instance)
		self.add_child(combo_numbers_manager_instance)


func died():
	pass
