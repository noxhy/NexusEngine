@icon("res://assets/sprites/nodes/strum arrows.png")

extends Node2D
class_name ArrowStrum

@onready var note_preload = preload("res://scenes/instances/playstate/note/note.tscn")
@onready var splash_preload = preload("res://scenes/instances/playstate/note/note_splash.tscn")

signal created_note(time: float, strum_name: StringName, length: float, note_type: int)
signal note_hit(time: float, strum_name: StringName, note_type: int, hit_time: float)
signal note_holding(time: float, strum_name: StringName, note_type: int)
signal note_miss(time: float, strum_name: StringName, length: float, note_type: int, hit_time: float)

@export var note_skin: NoteSkin
@export var input = ""
@export var strum_name = ""

@export var can_press = true
@export var auto_play = false
@export var can_splash = false
@export var enemy_slot = false

enum STATE {
	
	IDLE,
	PRESSED,
	GLOW,
	
}

var ignored_note_types: Array[int] = []
var note_types = [""]

var scroll_speed = 1.0
var scroll = 1.0
var song_position = 0.0
var song_speed = 1.0
var offset = 0.0
var note_list = []
var pressing = false
var previous_note = null
var state = 0

var tempo = 60.0
var seconds_per_beat = 60.0 / tempo

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$OffsetSprite.play_animation(strum_name)
	$"Hold Cover".visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	seconds_per_beat = 60.0 / tempo
	
	## Note movement
	for note in note_list:
		
		var time_difference = (note.time - offset) - (song_position) - delta
		var progress = time_difference / (note.seconds_per_beat * 4)
		
		note.scroll_speed = scroll_speed
		note.scroll = scroll
		note.position.y = (1000.0 * scroll_speed * scroll) * progress
		
		var grid_scaler = note.seconds_per_beat * note.scroll_speed * 0.25
		note.grid_size = Vector2(1000.0 * grid_scaler, 1000 * grid_scaler)
		
		if time_difference < 0.198:
			
			note.can_press = true
			
			if !enemy_slot:
				
				if note == note_list[0]:
					
					if SettingsHandeler.get_setting("glow_notes"):
						
						note.modulate = Color(1.5, 1.5, 1.5)
		
		if auto_play:
			
			if time_difference <= 0:
				
				if !ignored_note_types.has(note.note_type):
					
					if note != previous_note:
						
						emit_signal("note_hit", note.time, self.get_name(), note.note_type, 0)
						previous_note = note
					
					if note.length > 0:
						
						$"Hold Cover".play_animation("cover " + strum_name)
						note.position.y = 0
						note.length = ((note.time - offset) + (note.start_length * note.seconds_per_beat)) - song_position
						note.length /= note.seconds_per_beat
						
						if note.get_node("Note").visible:
							
							$"Hold Cover".play_animation("cover " + strum_name + " start")
							$"Hold Cover".visible = true
						
						note.get_node("Note").visible = false
						
						emit_signal("note_holding", note.time, self.get_name(), note.note_type)
						
						if !enemy_slot or SettingsHandeler.get_setting("enemy_strum_glow"):
							state = STATE.GLOW
					
					else:
						
						if !enemy_slot or SettingsHandeler.get_setting("enemy_strum_glow"):
							state = STATE.GLOW
						
						if can_splash:
								$"Hold Cover".play_animation("cover " + strum_name + " end")
						else:
								$"Hold Cover".visible = false
						
						note_list.erase(note)
						note.queue_free()
						
					
					continue
		
		if (time_difference + (note.start_length * note.seconds_per_beat - offset - delta)) <= -0.198:
				
				note_list.erase(note)
				note.queue_free()
				
				emit_signal("note_miss", note.time - time_difference, self.get_name(), note.length, note.note_type, time_difference + (note.length * note.seconds_per_beat))
	
	
	# Inputs
	
	
	if Input.is_action_just_pressed(input):
		
		if can_press:
			
			if note_list.size() > 0:
				
				var note = note_list[0]
				
				if note.can_press:
					
					if note.length <= 0:
						
						state = STATE.GLOW
						
						note_list.erase(note)
						note.queue_free()
						pressing = false
						
						var time_difference = (note.time - offset) - (song_position) - delta
						emit_signal("note_hit", note.time, self.get_name(), note.note_type, time_difference + (note.length * note.seconds_per_beat))
					
					else:
						
						$"Hold Cover".play_animation("cover " + strum_name)
						
						var time_difference = (note.time - offset) - (song_position) - delta
						emit_signal("note_hit", note.time, self.get_name(), note.note_type, time_difference)
						
						if !pressing:
							
							$"Hold Cover".play_animation("cover " + strum_name + " start")
							$"Hold Cover".visible = true
						
						pressing = true
				
				else:
					
					if !SettingsHandeler.get_setting("ghost_tapping"):
						emit_signal("note_miss", 0, self.get_name(), 0, -1, 0)
			else:
				
				if !SettingsHandeler.get_setting("ghost_tapping"):
					emit_signal("note_miss", 0, self.get_name(), 0, -1, 0)
	
	elif Input.is_action_pressed(input):
		
		
		if can_press:
			
			
			if pressing:
				
				
				if note_list.size() > 0:
					
					var note = note_list[0]
					
					if note.can_press:
						
						if note.length > 0:
							
							state = STATE.GLOW
							
							note.position.y = 0
							note.length = ((note.time - offset) + (note.start_length * note.seconds_per_beat)) - song_position
							note.length /= note.seconds_per_beat
							note.get_node("Note").visible = false
							
							emit_signal("note_holding", note.time, self.get_name(), note.note_type)
							
							if !pressing:
								
								$"Hold Cover".play_animation("cover " + strum_name + " start")
								$"Hold Cover".visible = true
							
							pressing = true
							
							if note.length <= 0:
								
								pressing = false
								emit_signal("note_holding", note.time, self.get_name(), note.note_type)
								
								if can_splash:
									$"Hold Cover".play_animation("cover " + strum_name + " end")
								else:
									$"Hold Cover".visible = false
								
								note_list.erase(note)
								note.queue_free()
			
			elif state != STATE.GLOW:
				
				state = STATE.PRESSED
	
	elif Input.is_action_just_released(input):
		
		if can_press:
			
			state = STATE.IDLE
			
			if $"Hold Cover".animation != "cover " + strum_name + " end":
				$"Hold Cover".visible = false
			
			if pressing:
				
				if note_list.size() > 0:
					
					var note = note_list[0]
					
					if note.can_press:
						
						if note.length > 0:
							
							note.time = song_position + note.length * note.seconds_per_beat
							note.start_length = note.length
	
	match state:
		
		STATE.IDLE:
			
			$OffsetSprite.play_animation(strum_name)
			
			var tween = create_tween()
			tween.tween_property($OffsetSprite, "scale", Vector2(note_skin.notes_scale, note_skin.notes_scale), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		STATE.PRESSED:
			press_strum()
		
		STATE.GLOW:
			glow_strum()


# Util


func set_skin(new_skin: NoteSkin):
	
	note_skin = new_skin
	
	$OffsetSprite.frames = note_skin.strums_texture
	$OffsetSprite.scale = Vector2(note_skin.notes_scale, note_skin.notes_scale)
	
	$"Hold Cover".frames = note_skin.hold_covers_texture
	$"Hold Cover".scale = Vector2(note_skin.hold_covers_scale, note_skin.hold_covers_scale)
	
	if note_skin.animation_names != null:
		
		$OffsetSprite.animation_names.merge(note_skin.animation_names, true)
		$"Hold Cover".animation_names.merge(note_skin.animation_names, true)
	
	$OffsetSprite.offsets.merge(note_skin.offsets, true)
	$"Hold Cover".offsets.merge(note_skin.offsets, true)
	
	if note_skin.pixel_texture:
		
		$OffsetSprite.texture_filter = TEXTURE_FILTER_NEAREST
		$"Hold Cover".texture_filter = TEXTURE_FILTER_NEAREST


func set_ignored_note_types(types: Array): ignored_note_types = types
func set_note_types(types: Array): note_types = types


func create_note(time: float, length: float, note_type: int, tempo: float):
	
	self.tempo = tempo
	
	var note_instance = note_preload.instantiate()
	
	note_instance.tempo = tempo
	note_instance.seconds_per_beat = 60.0 / tempo
	
	note_instance.time = time
	note_instance.length = length
	note_instance.start_length = length
	note_instance.note_type = note_type
	note_instance.grid_size = Vector2(1000 * seconds_per_beat, 1000 * seconds_per_beat)
	var scaler = seconds_per_beat * scroll_speed
	note_instance.position.y = 1000 * scaler * 4
	note_instance.scroll = scroll
	
	note_instance.direction = strum_name
	note_type = clamp(note_type, 0, note_types.size() - 1)
	note_instance.animation = note_types[ note_type ] + strum_name
	
	note_instance.note_skin = note_skin
	
	add_child(note_instance)
	note_list.append(note_instance)
	
	emit_signal("created_note", time, self.get_name(), length, note_type)


# Visuals



func glow_strum():
	
	# if $OffsetSprite.animation != $OffsetSprite.get_real_animation(strum_name + " glow"):
	$OffsetSprite.play_animation(strum_name + " glow")
	
	var note_scale = note_skin.notes_scale * 1.1
	
	if SettingsHandeler.get_setting("tween_strums"):
		
		var tween = create_tween()
		tween.tween_property($OffsetSprite, "scale", Vector2(note_scale, note_scale), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func press_strum():
	
	# if $OffsetSprite.animation != $OffsetSprite.get_real_animation(strum_name + " press"):
	$OffsetSprite.play_animation(strum_name + " press")
	
	var note_scale = note_skin.notes_scale * 0.9
	
	if SettingsHandeler.get_setting("tween_strums"):
		
		var tween = create_tween()
		tween.tween_property($OffsetSprite, "scale", Vector2(note_scale, note_scale), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_offset_sprite_animation_finished():
	
	if !can_press:
		
		state = STATE.IDLE


func _on_hold_cover_frame_changed():
	
	# Ugly fix for that rotates sprite bullshit
	if $"Hold Cover".animation.contains("idle"):
		
		if ($"Hold Cover".frame == 0) or ($"Hold Cover".frame == 3):
			$"Hold Cover".rotation_degrees = 90
		else:
			$"Hold Cover".rotation_degrees = 0
	else:
		$"Hold Cover".rotation_degrees = 0


func _on_hold_cover_animation_finished():
	
	if $"Hold Cover".animation == "cover " + strum_name + " start":
		$"Hold Cover".play_animation("cover " + strum_name)
	
	if $"Hold Cover".animation == "cover " + strum_name + " end": $"Hold Cover".visible = false


func create_splash(animation_name: String = strum_name + " splash"):
	
	if can_splash:
		
		if SettingsHandeler.get_setting("note_splashes"):
			
			var splash_instance = splash_preload.instantiate()
			
			splash_instance.note_skin = note_skin
			splash_instance.scale = Vector2.ONE * note_skin.splash_scale
			
			add_child(splash_instance)
			splash_instance.get_node("OffsetSprite").play_animation(animation_name)
