@icon("uid://bl12tb0xiej71")

extends Node2D
class_name Strum

const PIXELS_PER_SECOND: float = 450

var NOTE_PRELOAD = preload("uid://krhxbwnjnr7r")
var MODCHART_NOTE_PRELOAD = preload("uid://bfovtttcq6f32")
var SPLASH_PRELOAD = preload("uid://c23s1pbajtga2")

## Name of the input in the [code]InputMap[/code]
@export var input: String = ""
## Strum direction name
@export var strum_name: StringName = ""

@export var can_press: bool  = true
@export var auto_play: bool  = false
@export var can_splash: bool  = false
@export var enemy_slot: bool = false
## Note types that will be skipped over in note prioritization.
@export var ignored_note_types: Array = []
@export_enum("NORMAL", "MODCHART") var node_type: int

enum STATE {
	IDLE,
	PRESSED,
	GLOW,
}

var note_skin: NoteSkin
var scroll_speed: float = 1.0: set = set_scroll_speed
var scroll: float = 1.0: set = set_scroll
var song_speed: float = 1.0
var offset: float = 0.0
var note_list: Array[BasicNote] = []
var pressing: bool = false
var target_note: BasicNote = null
var state: STATE = STATE.IDLE
var lane: int = -1

var reset_timer: float = 0.0
var coyote_timer: float = 0.0

@onready var sprite: Node = $OffsetSprite
@onready var hold_cover_sprite: Node = $"Hold Cover"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hold_cover_sprite.visible = false
	Signals.connect(&"play_unpaused", self.release_note)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	target_note = get_prioritized_note(NoahStats.SHIT_RATING_WINDOW)
	
	if target_note:
		if !enemy_slot:
			if SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "glow_notes") and !ignored_note_types.has(target_note.note_type):
				target_note.modulate = Color(1.5, 1.5, 1.5)
		
		var relative_time: float = target_note.time_difference - offset + (target_note.start_length * GameManager.conductor.seconds_per_beat)
		var hit_window: float = NoahStats.SHIT_RATING_WINDOW
		if relative_time <= -hit_window and coyote_timer <= 0:
			note_list.erase(target_note)
			Signals.play_note_miss.emit(target_note, lane, get_parent())
			target_note.queue_free()
	
	if auto_play:
		if target_note and !ignored_note_types.has(target_note.note_type):
			if target_note.time_difference <= delta:
				reset_timer = GameManager.conductor.seconds_per_step
				
				if !pressing:
					press_note()
				else:
					hold_note()
	
	# Inputs
	if can_press:
		if Input.is_action_just_pressed(input):
			if target_note:
				press_note()
			else:
				if !SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "ghost_tapping"):
					Signals.play_note_miss.emit(null, lane, get_parent())
		
		if Input.is_action_pressed(input):
			if target_note:
				if pressing and target_note.length > 0:
					hold_note()
			elif state != STATE.GLOW:
				state = STATE.PRESSED
		
		if Input.is_action_just_released(input):
			release_note()
	
	if reset_timer > 0:
		reset_timer -= delta
		if reset_timer <= 0:
			reset_timer = 0
			state = STATE.IDLE
	
	if coyote_timer > 0:
		coyote_timer -= delta
		if coyote_timer <= 0:
			Signals.play_note_miss.emit(target_note, lane, get_parent())
			target_note.hit = true
			target_note.apply_miss_effect()
	
	if state == STATE.IDLE:
		sprite.play(strum_name + &"_strum")
	elif state == STATE.PRESSED:
		var animation_name: StringName = &"press_" + strum_name + &"_strum"
		if sprite.animation != animation_name:
			sprite.play(animation_name)
	elif state == STATE.GLOW:
		var animation_name: StringName = &"glow_" + strum_name + &"_strum"
		if sprite.animation != animation_name:
			sprite.play(animation_name)

# Util
func set_skin(new_skin: NoteSkin):
	note_skin = new_skin
	
	sprite.sprite_frames = note_skin.strums_texture
	sprite.scale = Vector2.ONE * note_skin.notes_scale
	sprite.offsets = note_skin.offsets
	hold_cover_sprite.offsets = note_skin.offsets
	
	hold_cover_sprite.sprite_frames = note_skin.hold_covers_texture
	hold_cover_sprite.scale = Vector2.ONE * note_skin.hold_covers_scale
	
	if note_skin.pixel_texture:
		sprite.texture_filter = TEXTURE_FILTER_NEAREST
		hold_cover_sprite.texture_filter = TEXTURE_FILTER_NEAREST


func create_note(time: float, length: float, note_type: String, _tempo: float):
	var note_instance: BasicNote
	if node_type == 0:
		note_instance = NOTE_PRELOAD.instantiate()
	else:
		note_instance = MODCHART_NOTE_PRELOAD.instantiate()
	
	note_instance.time = time - offset
	note_instance.length = length
	note_instance.start_length = length
	note_instance.note_type = note_type
	note_instance.position.y = PIXELS_PER_SECOND * 10
	note_instance.scroll_speed = scroll_speed
	note_instance.scroll = scroll
	note_instance.tempo = _tempo
	note_instance.lane = lane
	
	note_instance.direction = strum_name
	note_type = Constants.NOTE_TYPES.get(note_type, "")
	note_instance.animation = note_type + strum_name
	
	note_instance.note_skin = note_skin
	
	add_child(note_instance)
	note_list.append(note_instance)
	
	Signals.play_note_created.emit(note_instance, self)

# Visuals
func _on_offset_sprite_animation_finished():
	if state == STATE.GLOW:
		if !auto_play:
			if pressing:
				sprite.set_frame_and_progress(0, 0)
				sprite.play()
		else:
			sprite.set_frame_and_progress(0, 0)
			sprite.play()


func _on_hold_cover_animation_finished():
	if hold_cover_sprite.animation == &"start_" + strum_name + &"_cover":
		hold_cover_sprite.play(strum_name + &"_cover")
	
	if hold_cover_sprite.animation == &"end_" + strum_name + &"_cover":
		hold_cover_sprite.visible = false


func create_splash(animation_name: StringName = strum_name + &"_splash"):
	if can_splash:
		if SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "note_splashes"):
			var splash_instance = SPLASH_PRELOAD.instantiate()
			
			splash_instance.note_skin = note_skin
			
			add_child(splash_instance)
			splash_instance.sprite.play(animation_name)

## Calls when first pressing the input
func press_note():
	state = STATE.GLOW
	coyote_timer = 0
	var hit_time: float = (target_note.time - offset) - (GameManager.song_position) if !auto_play else 0.0
	
	if target_note.length <= 0:
		target_note.hit = true
		pressing = false
		var hit_rating: NoahStats.HIT_RATING = NoahStats.get_hit_rating(hit_time)
		if hit_rating == NoahStats.HIT_RATING.BAD or hit_rating == NoahStats.HIT_RATING.SHIT:
			target_note.apply_miss_effect()
		else:
			note_list.erase(target_note)
			target_note.queue_free()
	else:
		hold_cover_sprite.play(&"start_" + strum_name + &"_cover")
		hold_cover_sprite.visible = true
		
		pressing = true
		target_note.holding = true
	
	Signals.play_note_hit.emit(target_note, lane, hit_time, get_parent())

## Calls when holding the input
func hold_note():
	state = STATE.GLOW
	target_note.position.y = 0
	var temp = target_note.length
	var spb: float = get_relative_seconds_per_beat(target_note)
	target_note.length = ((target_note.time - offset) + (target_note.start_length * spb)) - GameManager.song_position
	target_note.length /= spb
	target_note.note.visible = false
	Signals.play_note_holding.emit(target_note, lane, temp - max(0, target_note.length), get_parent())

	if target_note.length <= 0:
		pressing = false
		if can_splash:
			hold_cover_sprite.play(&"end_" + strum_name + &"_cover")
		else:
			hold_cover_sprite.visible = false
		
		note_list.erase(target_note)
		target_note.queue_free()

## Calls when releasing the input
func release_note():
	if can_press:
		if pressing:
			pressing = false
			reset_timer = GameManager.conductor.seconds_per_step
			if hold_cover_sprite.animation != &"cover " + strum_name + &" end":
				hold_cover_sprite.visible = false
			
			var note = get_prioritized_note(NoahStats.SHIT_RATING_WINDOW)
			if note:
				# Checks if you were holding a note before releasing
				if target_note and note.length > 0:
					note.holding = false
					coyote_timer = GameManager.HOLD_NOTE_LENIENCY
					note.time = GameManager.song_position
					note.start_length = note.length
		else:
			state = STATE.IDLE

## Returns the seconds per beat relative to the given note.
func get_relative_seconds_per_beat(note: Note) -> float:
	return (GameManager.conductor.tempo / note.tempo) * GameManager.conductor.seconds_per_beat

## Returns the highest prioritized note within the hit window.
func get_prioritized_note(hit_window: float) -> BasicNote:
	if note_list.is_empty():
		return null
	
	var target = null
	for note in note_list: 
		if !note:
			continue
		
		if note.hit:
			continue
		
		if note.time_difference > hit_window:
			break
		
		if !ignored_note_types.has(note.note_type):
			return note
		else:
			if !target:
				target = note
	
	return target


func set_scroll_speed(s: float):
	scroll_speed = s
	
	for note in note_list:
		note.scroll_speed = s


func set_scroll(s: float):
	scroll = s
	
	for note in note_list:
		note.scroll = s
