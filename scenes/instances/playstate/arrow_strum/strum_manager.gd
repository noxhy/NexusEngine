@icon("res://assets/sprites/nodes/strum Manager.png")

extends Node2D

signal created_note(time: float, lane: int, length: float, note_type: int, manager: Node2D)
signal note_hit(time: float, lane: int, note_type: int, hit_time: float, manager: Node2D)
signal note_holding(time: float, lane: int, note_type: int, manager: Node2D)
signal note_miss(time: float, lane: int, length: float, note_type: int, hit_time: float, manager: Node2D)

@export var strum_count = 4
@export var note_skin = NoteSkin.new()
@export var strums = PackedStringArray()
@export var id: int = 0

@export var can_press = true
@export var auto_play = false
@export var can_splash = false
@export var enemy_slot = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	set_skin(note_skin)
	set_press(can_press)
	set_auto_play(auto_play)
	set_can_splash(can_splash)
	set_enemy_slot(enemy_slot)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_skin(new_skin: NoteSkin):
	
	for i in strums:
		get_node(i).set_skin(new_skin)


# PlayState Util


func set_scroll_speed(new_scroll_speed: float):
	
	for i in strums:
		get_node(i).scroll_speed = new_scroll_speed


func set_scroll(new_scroll: float):
	
	for i in strums:
		get_node(i).scroll = new_scroll


func set_press(toggle: bool):
	
	can_press = toggle
	
	for i in strums:
		get_node(i).can_press = can_press


func set_auto_play(toggle: bool):
	
	auto_play = toggle
	
	for i in strums:
		get_node(i).auto_play = auto_play


func set_can_splash(toggle: bool):
	
	can_splash = toggle
	
	for i in strums:
		get_node(i).can_splash = can_splash


func set_enemy_slot(toggle: bool):
	
	enemy_slot = toggle
	
	for i in strums:
		get_node(i).enemy_slot = enemy_slot


func set_ignored_note_types(note_types: Array):
	
	for i in strums:
		get_node(i).ignored_note_types = note_types


func get_strumline(lane: int) -> ArrowStrum: return get_node(strums[lane])
func get_scroll_speed(lane: int) -> float: return get_strumline(lane).scroll_speed


func note_types(note_types: Array):
	
	for i in strums:
		
		get_node(i).note_types = note_types


func create_note(time: float, lane: int, length: float, note_type: int, tempo: float):
	
	var strum = strums[ lane ]
	get_node(strum).create_note(time, length, note_type, tempo)


func create_splash(lane: int, animation_name: String):
	
	var strum = strums[ lane ]
	get_node(strum).create_splash(animation_name) 


# Visual Util


func glow_strum(lane: int):
	
	var node = get_node(strums[lane])
	node.glow_strum()


func press_strum(lane: int):
	
	var node = get_node(strums[lane])
	node.press_strum()


# Signals


func _on_note_hit(time, strum_name, note_type, hit_time):
	
	emit_signal("note_hit", time, strums.find(strum_name), note_type, hit_time, self)


func _on_note_holding(time, strum_name, note_type):
	
	emit_signal("note_holding", time, strums.find(strum_name), note_type, self)


func _on_note_miss(time, strum_name, length, note_type, hit_time):
	
	emit_signal("note_miss", time, strums.find(strum_name), length, note_type, hit_time, self)
