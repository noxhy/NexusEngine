extends Node2D

const LOCK_PRELOAD = preload("res://scenes/instances/character_select/lock.tscn")

var option_data: Dictionary = {
	0: {
		"character": "boyfriend",
		"icons": preload("res://assets/sprites/playstate/icons/boyfriend.tres"),
		"color": Color(0.175, 0.587, 0.859),
	},
	1: {
		"character": "pico",
		"icons": preload("res://assets/sprites/playstate/icons/pico.tres"),
		"color": Color(0.141, 0.851, 0.91),
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

func _ready() -> void:
	
	Global.set_window_title("Selecting a Character")
	$Camera2D.position.y = -150
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property($Camera2D, "position", Vector2(0, 0), 1.5)
	
	load_locks()

func load_locks():
	
	for i in range(9):
		
		var lock_instance = LOCK_PRELOAD.instantiate()
		
		lock_instance.position = get_node(str("%Lock ", i + 1)).position
		
		$UI.add_child(lock_instance)
		
		if option_data.has(i):
			
			lock_instance.color = option_data[i].get("color", Color(1, 1, 1))

func _on_conductor_new_beat(current_beat: int, measure_relative: int) -> void:
	
	if SettingsHandeler.get_setting("ui_bops"):
		Global.bop_tween($Camera2D, "zoom", Vector2(1, 1), Vector2(1.005, 1.005), 0.2, Tween.TRANS_CUBIC)
