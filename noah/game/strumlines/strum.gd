@icon("uid://bl12tb0xiej71")

extends Node2D
class_name Strum

const PIXELS_PER_SECOND: float = 450

var NOTE_PRELOAD = preload("uid://krhxbwnjnr7r")
var SPLASH_PRELOAD = preload("uid://c23s1pbajtga2")

@export var note_skin: NoteSkin
## Name of the input in the [code]InputMap[/code]
@export var input: String = ""
## Strum direction name
@export var strum_name: String = ""

@export var can_press: bool  = true
@export var auto_play: bool  = false
@export var can_splash: bool  = false
@export var enemy_slot: bool = false
## Note types that autoplay wont press
@export var ignored_note_types: Array = []

enum STATE {
	IDLE,
	PRESSED,
	GLOW,
}

var scroll_speed: float = 1.0
var scroll: float = 1.0
var song_speed: float = 1.0
var offset: float = 0.0
var note_list: Array[BasicNote] = []
var pressing: bool = false
var previous_note = null
var state: STATE = STATE.IDLE
var lane: int = -1

var reset_timer: float = 0.0
var coyote_timer: float = 0.0

@onready var sprite: Node = $OffsetSprite
@onready var hold_cover_sprite: Node = $"Hold Cover"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.play_animation(strum_name)
	hold_cover_sprite.visible = false
	Signals.connect(&"play_unpaused", self.release_note)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	for note in note_list:
		var time_difference: float = note.time_difference
		
		note.scroll_speed = scroll_speed
		note.scroll = scroll
		
		if time_difference <= GameManager.SHIT_RATING_WINDOW:
			note.can_press = true
			
			if !enemy_slot:
				if note == note_list.front():
					if SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "glow_notes"):
						note.modulate = Color(1.5, 1.5, 1.5)
		
		if auto_play:
			if time_difference <= delta:
				if !ignored_note_types.has(note.note_type):
					if note != previous_note:
						note.hit = true
						Signals.play_note_hit.emit(note, lane, 0, get_parent())
						previous_note = note
					
					if note.length > 0:
						note.holding = true
						var temp = note.length
						var spb: float = get_relative_seconds_per_beat(note)
						note.length = time_difference + (note.start_length * spb)
						note.length /= spb
						
						if note.note.visible:
							hold_cover_sprite.play_animation("cover " + strum_name + " start")
							hold_cover_sprite.visible = true
						
						note.note.visible = false
						
						Signals.play_note_holding.emit(note, lane, temp - max(0, note.length), get_parent())
						state = STATE.GLOW
					else:
						reset_timer = GameManager.seconds_per_step
						state = STATE.GLOW
						
						if can_splash:
								hold_cover_sprite.play_animation("cover " + strum_name + " end")
						else:
								hold_cover_sprite.visible = false
						
						note_list.erase(note)
						note.queue_free()
					continue
		
		var relative_time: float = time_difference + (note.start_length * GameManager.seconds_per_beat - offset)
		var hit_window: float = GameManager.SHIT_RATING_WINDOW
		if ignored_note_types.has(note.note_type):
			# This is for stuff like mine's so they have a smaller hit qindow
			hit_window = GameManager.GOOD_RATING_WINDOW
		
		if relative_time <= -hit_window and coyote_timer <= 0:
			note_list.erase(note)
			Signals.play_note_miss.emit(note, lane, get_parent())
			note.queue_free()
	# Inputs
	if Input.is_action_just_pressed(input):
		if can_press and !note_list.is_empty():
			var note = note_list.front()
			if note:
				if note.can_press:
					if note.length <= 0:
						state = STATE.GLOW
						coyote_timer = 0
						
						note.hit = true
						note_list.erase(note)
						note.queue_free()
						pressing = false
						var time_difference: float = (note.time - offset) - (GameManager.song_position)
						Signals.play_note_hit.emit(note, lane, time_difference, get_parent())
					else:
						var time_difference = (note.time - offset) - (GameManager.song_position)
						if note != previous_note:
							note.hit = true
							Signals.play_note_hit.emit(note, lane, time_difference, get_parent())
						
						coyote_timer = 0
						
						if !pressing:
							hold_cover_sprite.play_animation("cover " + strum_name + " start")
							hold_cover_sprite.visible = true
						
						pressing = true
						note.holding = true
						previous_note = note
				else:
					if !SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "ghost_tapping"):
						Signals.play_note_miss.emit(null, lane, get_parent())
			else:
				if !SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "ghost_tapping"):
					Signals.play_note_miss.emit(null, lane, get_parent())
		
	if Input.is_action_pressed(input):
		if can_press:
			if pressing:
				var note = note_list.front()
				if note:
					if note.can_press:
						if note.length > 0:
							state = STATE.GLOW
							note.position.y = 0
							var temp = note.length
							var spb: float = get_relative_seconds_per_beat(note)
							note.length = ((note.time - offset) + (note.start_length * spb)) - GameManager.song_position
							note.length /= spb
							note.note.visible = false
							Signals.play_note_holding.emit(note, lane, temp - max(0, note.length), get_parent())
							
							if !pressing:
								hold_cover_sprite.play_animation("cover " + strum_name + " start")
								hold_cover_sprite.visible = true
							
							pressing = true
							
							if note.length <= 0:
								pressing = false
								if can_splash:
									hold_cover_sprite.play_animation("cover " + strum_name + " end")
								else:
									hold_cover_sprite.visible = false
								
								note_list.remove_at(0)
								note.queue_free()
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
			var note = note_list.front()
			if note:
				note.time -= note.length * GameManager.seconds_per_beat
				note.time -= GameManager.BAD_RATING_WINDOW
	
	if state == STATE.IDLE:
		sprite.play_animation(strum_name)
	elif state == STATE.PRESSED:
		sprite.play_animation(strum_name + " press", false)
	elif state == STATE.GLOW:
		sprite.play_animation(strum_name + " glow", false)

# Util
func set_skin(new_skin: NoteSkin):
	note_skin = new_skin
	
	sprite.frames = note_skin.strums_texture
	sprite.scale = Vector2(note_skin.notes_scale, note_skin.notes_scale)
	
	hold_cover_sprite.frames = note_skin.hold_covers_texture
	hold_cover_sprite.scale = Vector2(note_skin.hold_covers_scale, note_skin.hold_covers_scale)
	
	if note_skin.animation_names != null:
		sprite.animation_names.merge(note_skin.animation_names, true)
		hold_cover_sprite.animation_names.merge(note_skin.animation_names, true)
	
	sprite.offsets.merge(note_skin.offsets, true)
	hold_cover_sprite.offsets.merge(note_skin.offsets, true)
	
	if note_skin.pixel_texture:
		sprite.texture_filter = TEXTURE_FILTER_NEAREST
		hold_cover_sprite.texture_filter = TEXTURE_FILTER_NEAREST


func create_note(time: float, length: float, note_type: String, _tempo: float):
	var note_instance = NOTE_PRELOAD.instantiate()
	
	note_instance.time = time - offset
	note_instance.length = length
	note_instance.start_length = length
	note_instance.note_type = note_type
	note_instance.position.y = 1000
	note_instance.scroll = scroll
	note_instance.tempo = _tempo
	
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
	if hold_cover_sprite.animation == hold_cover_sprite.animation_names.get("cover " + strum_name + " start"):
		hold_cover_sprite.play_animation("cover " + strum_name)
	
	if hold_cover_sprite.animation == hold_cover_sprite.animation_names.get("cover " + strum_name + " end"):
		hold_cover_sprite.visible = false


func create_splash(animation_name: String = strum_name + " splash"):
	if can_splash:
		if SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "note_splashes"):
			var splash_instance = SPLASH_PRELOAD.instantiate()
			
			splash_instance.note_skin = note_skin
			splash_instance.scale = Vector2.ONE * note_skin.splash_scale
			
			add_child(splash_instance)
			splash_instance.get_node("OffsetSprite").play_animation(animation_name)


func release_note():
	if can_press:
		if pressing:
			pressing = false
			reset_timer = GameManager.seconds_per_step
			if hold_cover_sprite.animation != "cover " + strum_name + " end":
				hold_cover_sprite.visible = false
			
			var note = note_list.front()
			if note:
				# Checks if you were holding a note before releasing
				if note.can_press and note.length > 0:
					note.holding = false
					coyote_timer = GameManager.HOLD_NOTE_LENIENCY
					note.time = GameManager.song_position
					note.start_length = note.length
		else:
			state = STATE.IDLE

## Returns the seconds per beat relative to the given note.
func get_relative_seconds_per_beat(note: Note) -> float:
	return (GameManager.conductor.tempo / note.tempo) * GameManager.seconds_per_beat
