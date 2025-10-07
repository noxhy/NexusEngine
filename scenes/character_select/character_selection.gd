extends Node2D

const LOCK_PRELOAD = preload("res://scenes/instances/character_select/lock.tscn")

var option_data: Dictionary = {
	0: {
		"character": "boyfriend",
		"icons": preload("res://assets/sprites/playstate/icons/boyfriend.tres"),
		"color": Color(0.192, 0.69, 0.82),
		"player": preload("res://scenes/instances/character_select/characters/boyfriend/boyfriend.tscn"),
		"partner": preload("res://scenes/instances/character_select/characters/boyfriend/girlfriend.tscn")
	},
	1: {
		"character": "pico",
		"icons": preload("res://assets/sprites/playstate/icons/pico.tres"),
		"color": Color(0.141, 0.851, 0.91),
		"player": preload("res://scenes/instances/character_select/characters/pico/pico.tscn"),
		"partner": preload("res://scenes/instances/character_select/characters/pico/nene.tscn")
	},
	2: {
		"color": Color(0.125, 0.608, 0.867),
	},
	3: {
		"color": Color(0.125, 0.925, 0.804),
	},
	4: {
		"color": Color(0.192, 0.949, 0.647),
	},
	5: {
		"color": Color(0.141, 0.851, 0.91),
	},
	6: {
		"color": Color(0.137, 0.384, 0.788),
	},
	7: {
		"color": Color(0.125, 0.608, 0.867),
	},
	8: {
		"color": Color(0.141, 0.247, 0.725),
	},
}

var map: Array[Array] = [
	[4, 3, 5],
	[1, 0, 2],
	[7, 6, 8]
]

var selected: Vector2i = Vector2i(1, 1)
var input_time: float
var input_delay: float
var time_of_next_step: float
var total: float = 0.0
var can_press: bool = true

func _ready() -> void:
	
	Global.set_window_title("Selecting a Character")
	$Camera2D.offset.y = -150
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property($Camera2D, "offset", Vector2(640, 360), 1.5)
	
	load_locks()
	select(selected)


func _process(delta: float) -> void:
	
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var time = $Audio/Music.get_playback_position()
	time -= AudioServer.get_time_since_last_mix()
	time -= AudioServer.get_output_latency()
	
	if input_vector != Vector2.ZERO:
		
		if input_time == 0 || input_time >= $Conductor.seconds_per_beat / 4:
			
			select(Vector2i(input_vector.sign()) + selected)
			if input_time >= (time_of_next_step - time):
				input_time = 0
		
		input_time += delta
	
	if (multi_input_xor(
		[Input.is_action_just_released("ui_left"), Input.is_action_just_released("ui_right"),
		Input.is_action_just_released("ui_down"), Input.is_action_just_released("ui_up")
		]
	)):
		input_time = 0
	
	if Input.is_action_just_pressed("ui_accept"):
		confirm(selected)
	
	%"Character Name".position.y = -616.2 + (sin(total) * 10)
	total += delta * $Conductor.seconds_per_beat * 4


func load_locks():
	
	for i in range(9):
		
		var pos = get_node(str("%Lock ", i + 1)).position
		var lock_instance = LOCK_PRELOAD.instantiate()
		
		lock_instance.position = pos
		
		$UI.add_child(lock_instance)
		
		lock_instance.color = option_data[i].get("color", Color(1, 1, 1))
		option_data[i]["position"] = pos
		
		if option_data[i].has("icons"):
			lock_instance.icon = option_data[i]["icons"].get_frame_texture("default", 0)
			lock_instance.state = 2
		
		if option_data[i].has("player"):
			
			var instance = option_data[i]["player"].instantiate()
			
			instance.position = Vector2(944, 600)
			instance.visible = false
			
			$Background/Characters.add_child(instance)
			instance.add_to_group(option_data[i]["character"])
			instance.add_to_group("player")
		
		if option_data[i].has("partner"):
			
			var instance = option_data[i]["partner"].instantiate()
			
			instance.position = Vector2(344, 592)
			instance.animation = "idle"
			instance.visible = false
			
			$Background/Characters.add_child(instance)
			instance.add_to_group(option_data[i]["character"])
			instance.add_to_group("partner")


func _on_conductor_new_beat(current_beat: int, _measure_relative: int) -> void:
	
	if SettingsManager.get_setting("ui_bops"):
		Global.bop_tween($Camera2D, "zoom", Vector2(1, 1), Vector2(1.005, 1.005), 0.2, Tween.TRANS_CUBIC)
	
	$Background/Parallax2D3/Speakers.playing = true
	$Background/Parallax2D3/Speakers.frame = 0
	
	get_tree().call_group("player", "play", "idle")
	if current_beat % 2 == 0:
		get_tree().call_group("partner", "play", "idle")


func _on_conductor_new_step(_current_step: int, _measure_relative: int) -> void:
	
	time_of_next_step = $Audio/Music.get_playback_position()
	time_of_next_step -= AudioServer.get_time_since_last_mix()
	time_of_next_step -= AudioServer.get_output_latency()
	time_of_next_step += $Conductor.seconds_per_beat / 4


func select(pos: Vector2i = selected):
	
	if !can_press: return
	
	pos.x = wrapi(pos.x, 0, 3)
	pos.y = wrapi(pos.y, 0, 3)
	selected = pos
	
	$Camera2D.drag_horizontal_offset = pos.x - 1
	$Camera2D.drag_vertical_offset = pos.y - 1
	
	var index: int = map[pos.y][pos.x]
	
	%"Character Name".play(option_data[index].get("character", "default"))
	
	$Audio/Select.play()
	
	for node in get_tree().get_nodes_in_group("current"):
		
		node.visible = false
		node.remove_from_group("current")
	
	if option_data[index].has("character"):
		
		for node in get_tree().get_nodes_in_group(option_data[index]["character"]):
			
			node.visible = true
			node.add_to_group("current")
	
	get_tree().call_group("current", "play", "in")
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(%Selector, "position", option_data[index]["position"], 0.2)
	tween.tween_method(self.mozaic, 40, 0, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)


func confirm(pos: Vector2i = selected):
	
	if !can_press: return
	
	pos.x = wrapi(pos.x, 0, 3)
	pos.y = wrapi(pos.y, 0, 3)
	selected = pos
	
	var index: int = map[pos.y][pos.x]
	var character = option_data[index].get("character")
	
	if character != null:
		
		can_press = false
		GameManager.current_character = character
		$Audio/Confirm.play()
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property($Audio/Music, "pitch_scale", 0.0, 0.5)
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property($Camera2D, "offset", $Camera2D.offset - Vector2(0, 150), 0.5).set_delay(0.5)
		
		get_tree().call_group("current", "play", "confirm")
		Global.change_scene_to("res://scenes/freeplay/freeplay.tscn")
	else:
		
		$Audio/Locked.play()


func mozaic(amount: float):
	%"Character Name".material.set_shader_parameter("amount", amount)

func multi_input_xor(inputs: Array) -> bool:
	
	var result = false
	for input_val in inputs:
		result = result != input_val
	
	return result
