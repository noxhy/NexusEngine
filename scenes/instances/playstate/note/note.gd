@icon( "res://assets/sprites/nodes/note.png" )

extends Node2D
class_name Note

const font = preload("res://assets/fonts/Bold Normal Text.ttf")
const PIXELS_PER_SECOND = 450

@export_range(0, 16, 0.1) var length = 0.0
@export_range(0, 16, 0.1) var start_length = 0.0
@export var note_type = 0
@export var time = 0.0
@export var note_skin: NoteSkin
@export var chart_note: bool = false

@export_group("Length Modifiers")
@export_range(0.1, 5, 0.1) var scroll_speed = 1.0
@export var grid_size = Vector2(128, 128)

var scroll: float = 1.0
var can_press: bool = false
var pressed: bool = false
var last_length: float = 0.0

var direction: String = "left"
var animation: String = "left"
var lane: int = 0
var time_difference: float = INF

var on_screen = false

# Called when the node enters the scene tree for the first time.
func _ready(): 
	
	$Note.sprite_frames = note_skin.notes_texture
	$"Tail/Tail End".sprite_frames = note_skin.notes_texture
	
	if note_skin.animation_names != null: 
		
		if note_skin.animation_names.keys().size() > 0: 
			
			$Note.animation_names = note_skin.animation_names
			$"Tail/Tail End".animation_names = note_skin.animation_names
	
	$Note.play_animation( animation )
	$"Tail/Tail End".play_animation( animation + " end" )
	
	var tail_animation = $Note.get_real_animation( animation + " tail" )
	$Tail.texture = $Note.sprite_frames.get_frame_texture( tail_animation, 0 )
	
	$Note.offsets = note_skin.offsets
	
	if note_skin.pixel_texture: 
		
		$Note.texture_filter = TEXTURE_FILTER_NEAREST
		$Tail.texture_filter = TEXTURE_FILTER_NEAREST
		$"Tail/Tail End".texture_filter = TEXTURE_FILTER_NEAREST
	
	if !chart_note: 
		
		scale = Vector2(note_skin.notes_scale, note_skin.notes_scale)
		$Tail.width = note_skin.sustain_width
	else: 
		
		# scale = grid_size / Vector2(note_skin.notes_scale, note_skin.notes_scale)
		scale = Vector2(1, 1)
		$Note.scale = grid_size / ( Vector2( $Note.sprite_frames.get_frame_texture($Note.animation, 0).get_width(), $Note.sprite_frames.get_frame_texture($Note.animation, 0).get_height()) )
		$Tail.width = note_skin.sustain_width * $Note.scale.x
		$"Tail/Tail End".scale = $Note.scale


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	time_difference = (time - GameManager.offset) - GameManager.song_position
	
	if on_screen: 
		
		var tail_animation = $"Tail/Tail End".animation
		var texture = $"Tail/Tail End".sprite_frames.get_frame_texture(tail_animation, 0)
		
		var line_length = length
		line_length *= scroll_speed
		line_length *= grid_size.y
		line_length = abs(line_length)
		if !chart_note: line_length /= note_skin.notes_scale
		
		if length > 0:
			
			$Tail.visible = true
			
			$"Tail/Tail End".offset.x = texture.get_width() * 0.5
			if chart_note: 
				
				line_length -= $"Tail/Tail End".offset.x * $"Tail/Tail End".scale.x
				if line_length < $"Tail/Tail End".offset.x * $"Tail/Tail End".scale.x: 
					line_length = $"Tail/Tail End".offset.x * $"Tail/Tail End".scale.x
			$"Tail/Tail End".position.y = line_length
			
			$Tail.scale.y = scroll
			
			if last_length != length: $Tail.points = [Vector2(0, 0), Vector2(0, line_length)]
			
			var end_direction: Vector2 = Vector2.DOWN
			
			if $Tail.points.size() > 1: 
				end_direction = $Tail.points[$Tail.points.size() - 1] - $Tail.points[$Tail.points.size() - 2]
			
			$"Tail/Tail End".position = $Tail.get_point_position($Tail.points.size() - 1)
			$"Tail/Tail End".rotation = end_direction.angle()
			
			if scroll < 0:
				$VisibleOnScreenNotifier2D.rect = Rect2(-10, -10, grid_size.x, grid_size.y + (line_length * 1.1 * scroll)).abs()
			else:
				$VisibleOnScreenNotifier2D.rect = Rect2(-10, -10, grid_size.x, grid_size.y + (line_length * 1.1 * scroll))
		
		else: 
			
			$Tail.visible = false


func update_y():
	
	position.y = (PIXELS_PER_SECOND * time_difference * scroll_speed * scroll)
	
	var grid_scaler = PIXELS_PER_SECOND * GameManager.seconds_per_beat
	grid_size = Vector2(grid_scaler, grid_scaler)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void: 
	
	on_screen = true
	$Note.visible = on_screen
	$Tail.visible = on_screen

func _on_visible_on_screen_notifier_2d_screen_exited() -> void: 
	
	on_screen = false
	$Note.visible = on_screen
	$Tail.visible = on_screen
