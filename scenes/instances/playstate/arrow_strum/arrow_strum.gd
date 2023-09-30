@icon("res://assets/sprites/nodes/strum arrows.png")

extends Node2D
class_name ArrowStrum

@onready var note_preload = preload( "res://scenes/instances/playstate/note/note.tscn" )
@onready var splash_preload = preload( "res://scenes/instances/playstate/note/note_splash.tscn" )

signal created_note( time: float, strum_name: StringName, length: float, note_type: int )
signal note_hit( time: float, strum_name: StringName, note_type: int, hit_time: float )
signal note_holding( time: float, strum_name: StringName, note_type: int )
signal note_miss( time: float, strum_name: StringName, length: float, note_type: int, hit_time: float )

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
	
	$OffsetSprite.play_animation( strum_name )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	seconds_per_beat = 60.0 / tempo
	
	# Inputs
	
	if Input.is_action_just_pressed(input):
		
		if can_press:
			
			if note_list.size() > 0:
				
				var note = note_list[0]
				
				if note.can_press:
					
					if note.length == 0:
						
						state = STATE.GLOW
						
						note_list.erase( note )
						note.queue_free()
						pressing = false
						
						var time_difference = ( note.time ) - ( song_position ) - offset
						emit_signal( "note_hit", note.time, self.get_name(), note.note_type, time_difference )
					
					else:
						
						var time_difference = ( note.time ) - ( song_position ) - offset
						emit_signal( "note_hit", note.time, self.get_name(), note.note_type, time_difference )
						pressing = true
				
				else:
					
					if !SettingsHandeler.get_setting( "ghost_tapping" ):
						emit_signal( "note_miss", 0, self.get_name(), 0, 0, 0 )
			else:
				
				if !SettingsHandeler.get_setting( "ghost_tapping" ):
					emit_signal( "note_miss", 0, self.get_name(), 0, 0, 0 )
	
	
	elif Input.is_action_pressed(input):
		
		
		if can_press:
			
			
			if pressing:
				
				
				if note_list.size() > 0:
					
					var note = note_list[0]
					
					if note.can_press:
						
						if note.length > 0:
							
							state = STATE.GLOW
							
							note.position.y = 0
							var time_difference = ( note.time ) - ( song_position )
							note.length -= ( note.tempo / 60.0 ) * song_speed * delta
							note.time += note.seconds_per_beat * song_speed * delta
							note.time += delta
							note.get_node("Note").visible = false
							
							emit_signal( "note_holding", note.time, self.get_name(), note.note_type )
							pressing = true
							
							if note.length <= 0:
								
								pressing = false
								emit_signal( "note_holding", note.time, self.get_name(), note.note_type )
								
								note_list.erase( note )
								note.queue_free()
								
			
			elif state != STATE.GLOW:
				
				state = STATE.PRESSED
	
	elif Input.is_action_just_released(input):
		
		if can_press:
			
			state = STATE.IDLE
	
	match state:
		
		STATE.IDLE:
			
			$OffsetSprite.play_animation( strum_name )
			
			var tween = create_tween()
			tween.tween_property($OffsetSprite, "scale", Vector2( note_skin.notes_scale, note_skin.notes_scale ), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		STATE.PRESSED:
			press_strum()
		
		STATE.GLOW:
			glow_strum()


func _physics_process(delta):
	
	for note in note_list:
		
		var time_difference = ( note.time - offset ) - ( song_position )
		var progress = time_difference / ( note.seconds_per_beat * 4 )
		
		note.scroll_speed = scroll_speed
		note.scroll = scroll
		note.position.y = (1000 * scroll_speed * scroll) * progress
		
		var grid_scaler = note.seconds_per_beat * note.scroll_speed * 0.25
		note.grid_size = Vector2( 1000 * grid_scaler, 1000 * grid_scaler )
		
		if time_difference < 0.164:
			
			note.can_press = true
			
			if !enemy_slot:
				
				if note == note_list[0]:
					
					if SettingsHandeler.get_setting( "glow_notes" ):
						
						note.modulate = Color( 1.5, 1.5, 1.5 )
		
		if auto_play:
			
			if time_difference <= 0:
				
				if !ignored_note_types.has( note.note_type ):
					
					if note != previous_note:
						
						emit_signal( "note_hit", note.time, self.get_name(), note.note_type, 0 )
						previous_note = note
					
					if note.length > 0:
						
						note.position.y = 0
						note.length -= ( tempo / 60.0 ) * song_speed * delta
						note.get_node("Note").visible = false
						
						emit_signal( "note_holding", note.time, self.get_name(), note.note_type )
						
						if !enemy_slot || SettingsHandeler.get_setting( "enemy_strum_glow" ):
							state = STATE.GLOW
					else:
						
						if !enemy_slot || SettingsHandeler.get_setting( "enemy_strum_glow" ):
							state = STATE.GLOW
						
						note_list.erase( note )
						note.queue_free()
						
					
					continue
			
		
		if time_difference <= -0.164:
				
				note_list.erase( note )
				note.queue_free()
				
				emit_signal( "note_miss", note.time - time_difference, self.get_name(), note.length, note.note_type, time_difference )


# Util


func set_skin(new_skin: NoteSkin):
	
	note_skin = new_skin
	
	$OffsetSprite.frames = note_skin.strums_texture
	$OffsetSprite.scale = Vector2( note_skin.notes_scale, note_skin.notes_scale )
	
	if note_skin.animation_names != null:
		$OffsetSprite.animation_names.merge( note_skin.animation_names, true )
	
	$OffsetSprite.offsets = note_skin.offsets
	
	if note_skin.pixel_texture:
		$OffsetSprite.texture_filter = TEXTURE_FILTER_NEAREST


func set_ignored_note_types( types: Array ): ignored_note_types = types
func set_note_types( types: Array ): note_types = types


func create_note(time: float, length: float, note_type: int, tempo: float):
	
	self.tempo = tempo
	
	var note_instance = note_preload.instantiate()
	
	note_instance.tempo = tempo
	note_instance.seconds_per_beat = 60.0 / tempo
	
	note_instance.time = time
	note_instance.length = length
	note_instance.note_type = note_type
	note_instance.grid_size = Vector2( 1000 * seconds_per_beat, 1000 * seconds_per_beat )
	var scaler = seconds_per_beat * scroll_speed
	note_instance.position.y = 1000 * scaler * 4
	note_instance.scroll = scroll
	
	note_instance.direction = strum_name
	note_type = clamp( note_type, 0, note_types.size() - 1 )
	note_instance.animation = note_types[ note_type ] + strum_name
	
	note_instance.note_skin = note_skin
	
	add_child( note_instance )
	note_list.append( note_instance )
	
	emit_signal( "created_note", time, self.get_name(), length, note_type )


# Visuals



func glow_strum():
	
	# if $OffsetSprite.animation != $OffsetSprite.get_real_animation( strum_name + " glow" ):
	$OffsetSprite.play_animation( strum_name + " glow" )
	
	var note_scale = note_skin.notes_scale * 1.1
	
	var tween = create_tween()
	tween.tween_property($OffsetSprite, "scale", Vector2( note_scale, note_scale ), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func press_strum():
	
	# if $OffsetSprite.animation != $OffsetSprite.get_real_animation( strum_name + " press" ):
	$OffsetSprite.play_animation( strum_name + " press" )
	
	var note_scale = note_skin.notes_scale * 0.9
	
	var tween = create_tween()
	tween.tween_property($OffsetSprite, "scale", Vector2( note_scale, note_scale ), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_offset_sprite_animation_finished():
	
	if !can_press:
		
		state = STATE.IDLE


func create_splash( animation_name: String = strum_name + " splash" ):
	
	if can_splash:
		
		if SettingsHandeler.get_setting("note_splashes"):
			
			var splash_instance = splash_preload.instantiate()
			
			splash_instance.note_skin = note_skin
			
			add_child( splash_instance )
			splash_instance.get_node( "OffsetSprite" ).play_animation( animation_name )
