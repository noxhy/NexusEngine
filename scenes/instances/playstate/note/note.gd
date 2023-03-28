@icon( "res://assets/sprites/nodes/note.png" )

extends Node2D
class_name Note

@export_range(0, 16, 0.1) var length = 0.0
@export var note_type = 0
@export var time = 0.0
@export var note_skin: NoteSkin

@export_group("Length Modifiers")
@export_range(0.1, 5, 0.1) var scroll_speed = 1.0
@export var grid_size = Vector2(64, 64)

var tempo = 60.0
var seconds_per_beat = 0.0
var scroll = 1.0
var can_press = false

var direction = "left"
var animation = "left"


# Called when the node enters the scene tree for the first time.
func _ready():
	
	$Note.sprite_frames = note_skin.notes_texture
	$"Tail/Tail End".sprite_frames = note_skin.notes_texture
	scale = Vector2( note_skin.notes_scale, note_skin.notes_scale )
	
	if note_skin.animation_names != null:
		
		if note_skin.animation_names.keys().size() > 0:
			
			$Note.animation_names = note_skin.animation_names
			$"Tail/Tail End".animation_names = note_skin.animation_names
	
	$Note.play_animation( animation )
	$"Tail/Tail End".play_animation( animation + " end" )
	
	var tail_animation = $Note.get_real_animation( animation + " tail" )
	$Tail.texture = $Note.sprite_frames.get_frame_texture( tail_animation, 0 )
	
	$Tail.width = note_skin.sustain_width
	$Note.offsets = note_skin.offsets
	
	if note_skin.pixel_texture:
		
		$Note.texture_filter = TEXTURE_FILTER_NEAREST
		$Tail.texture_filter = TEXTURE_FILTER_NEAREST
		$"Tail/Tail End".texture_filter = TEXTURE_FILTER_NEAREST


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	seconds_per_beat = 60.0 / tempo
	
	var line_length = length
	line_length *= scroll_speed
	line_length *= grid_size.y
	line_length = abs(line_length)
	
	line_length *= 0.75
	line_length /= note_skin.notes_scale
	
	if length != 0:
		
		$Tail.visible = true
		
		var tail_animation = $"Tail/Tail End".animation
		var texture = $"Tail/Tail End".sprite_frames.get_frame_texture( tail_animation, 0 )
		
		$"Tail/Tail End".offset.x = texture.get_width() * 0.5
		line_length -= $"Tail/Tail End".offset.x
		$"Tail/Tail End".position.y = line_length
		$Tail.scale.y = scroll
		
		if $Tail.points.size() == 0:
				$Tail.add_point(Vector2(0, 0))
				$Tail.add_point(Vector2(0, line_length))
		else:
				$Tail.set_point_position(1, Vector2(0, line_length))
	else:
		
		$Tail.visible = false
