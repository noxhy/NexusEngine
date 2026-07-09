@icon("uid://yl4giaklgpx0")
extends Node2D
class_name StrumManager


@export var note_skin: NoteSkin = NoteSkin.new()
## List of Nodes of the strumlines.
@export var strums: Array[Strum] = []
## Vocal track ID.
@export var id: int = 0

## If [code]true[/code], the strumlines will read the player's input.
@export var can_press: bool = true
## If [code]true[/code], the strumlines will hit notes automatically. Typically used for botplay
## or the enemy strumlines.
@export var auto_play: bool = false
## If [code]true[/code], the strumlines will create a note splash effect when hitting or holding a
## note. Typically used for the player strumlines.
@export var can_splash: bool = false
## If [code]true[/code], the strumlines will count as a enemy strumline. Enemy strumlines do not
## affect player stats.
@export var enemy_slot: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_skin(note_skin)
	set_press(can_press)
	set_auto_play(auto_play)
	set_can_splash(can_splash)
	set_enemy_slot(enemy_slot)
	
	var i: int = 0
	for strum in strums:
		strum.lane = i
		i += 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass


func set_skin(new_skin: NoteSkin):
	for strum in strums:
		strum.set_skin(new_skin)


# PlayState Util


func set_scroll_speed(new_scroll_speed: float):
	for strum in strums:
		strum.scroll_speed = new_scroll_speed


func set_scroll(new_scroll: float):
	for strum in strums:
		strum.scroll = new_scroll


func set_press(toggle: bool):
	for strum in strums:
		strum.can_press = toggle


func set_auto_play(toggle: bool):
	for strum in strums:
		strum.auto_play = toggle


func set_offset(offset: float):
	for strum in strums:
		strum.offset = offset


func set_can_splash(toggle: bool):
	for strum in strums:
		strum.can_splash = toggle


func set_enemy_slot(toggle: bool):
	for strum in strums:
		strum.enemy_slot = toggle


func set_ignored_note_types(_note_types: Array):
	for strum in strums:
		strum.ignored_note_types = _note_types


func get_strumline(lane: int) -> Strum:
	return strums[lane]

func get_scroll_speed(lane: int) -> float:
	return get_strumline(lane).scroll_speed


func create_note(time: float, lane: int, length: float, note_type: String, tempo: float):
	strums[lane].create_note(time, length, note_type, tempo)

func create_splash(lane: int, animation_name: StringName):
	var anim_to_play: StringName = animation_name + &"_splash"
	if animation_name.is_empty():
		anim_to_play = strums[lane].strum_name + &"_splash"
	
	strums[lane].create_splash(anim_to_play)

# Visual Util
func glow_strum(lane: int):
	strums[lane].glow_strum()


func press_strum(lane: int):
	strums[lane].press_strum()
