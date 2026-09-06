@icon("uid://yl4giaklgpx0")
extends Node2D
class_name StrumManager

@export var note_skin: NoteSkin: set = set_skin
## List of Nodes of the strumlines.
@export var strums: Array[Strum]
## Vocal track ID.
@export var id: int = 0

## If [code]true[/code], the strumlines will read the player's input.
@export var can_press: bool: set = set_press
## If [code]true[/code], the strumlines will hit notes automatically. Typically used for botplay
## or the enemy strumlines.
@export var auto_play: bool: set = set_auto_play
## If [code]true[/code], the strumlines will create a note splash effect when hitting or holding a
## note. Typically used for the player strumlines.
@export var can_splash: bool: set = set_can_splash
## If [code]true[/code], the strumlines will count as a enemy strumline. Enemy strumlines do not
## affect player stats.
@export var enemy_slot: bool: set = set_enemy_slot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var i: int = 0
	for strum in strums:
		strum.lane = i
		i += 1


func set_skin(new_skin: NoteSkin) -> void:
	note_skin = new_skin
	for strum in strums:
		strum.set_skin(new_skin)


func set_scroll_speed(new_scroll_speed: float) -> void:
	for strum in strums:
		strum.scroll_speed = new_scroll_speed


func set_scroll(new_scroll: float) -> void:
	for strum in strums:
		strum.scroll = new_scroll


func set_press(toggle: bool) -> void:
	can_press = toggle
	for strum in strums:
		strum.can_press = toggle


func set_auto_play(toggle: bool) -> void:
	auto_play = toggle
	for strum in strums:
		strum.auto_play = toggle


func set_offset(offset: float) -> void:
	for strum in strums:
		strum.offset = offset


func set_can_splash(toggle: bool) -> void:
	can_splash = toggle
	for strum in strums:
		strum.can_splash = toggle


func set_enemy_slot(toggle: bool) -> void:
	enemy_slot = toggle
	for strum in strums:
		strum.enemy_slot = toggle


func set_ignored_note_types(_note_types: Array) -> void:
	for strum in strums:
		strum.ignored_note_types = _note_types


func get_strumline(lane: int) -> Strum:
	return strums[lane]


func get_scroll_speed(lane: int) -> float:
	return get_strumline(lane).scroll_speed


func create_note(time: float, lane: int, length: float, note_type: String, tempo: float) -> void:
	get_strumline(lane).create_note(time, length, note_type, tempo)


func create_splash(lane: int, animation_name: StringName) -> void:
	var anim_to_play: StringName = animation_name + &"_splash"
	if animation_name.is_empty():
		anim_to_play = get_strumline(lane).strum_name + &"_splash"
	
	get_strumline(lane).create_splash(anim_to_play)
