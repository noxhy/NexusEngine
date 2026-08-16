extends BasicNote
class_name ChartNote

@onready var area = $Area2D
@onready var collision_shape = $Area2D/CollisionShape2D

# Applying Note Skin
func _ready() -> void:
	note.sprite_frames = note_skin.notes_texture
	if !note_skin.animation_names.is_empty(): 
		note.animation_names.merge(note_skin.animation_names, true)
	
	note.play_animation(animation)
	
	var tail_animation = note.get_animation_name(animation + &"_tail")
	if tail_animation:
		tail.texture = note_skin.notes_texture.get_frame_texture(tail_animation, 0)
	
	note.offsets = note_skin.offsets
	
	if note_skin.pixel_texture: 
		note.texture_filter = TEXTURE_FILTER_NEAREST
		tail.texture_filter = TEXTURE_FILTER_NEAREST
	
	update()

func update():
	if note:
		scale = Vector2(1, 1)
		note.scale = grid_size / note.sprite_frames.get_frame_texture(note.animation, 0).get_size()
		
		#note.scale *= 0.9
		%"Special Note Label".scale = grid_size / %"Special Note Label".size
		if tail:
			tail.scale = note.scale
			if tail.texture:
				tail.position.x = tail.texture.get_height() / 2.0 * tail.scale.x
		
		$VisibleOnScreenEnabler2D.scale = grid_size / Vector2(640, 640)
		
		if collision_shape:
			collision_shape.shape = RectangleShape2D.new()
			collision_shape.scale = $VisibleOnScreenEnabler2D.scale * 0.9
			collision_shape.shape.set_size(Vector2($VisibleOnScreenEnabler2D.rect.size.x, $VisibleOnScreenEnabler2D.rect.size.x))
			%"Special Note Label".visible = note_type != ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	time_difference = (time - GameManager.offset) - GameManager.song_position
	
	if length > 0:
		var line_length = length * scroll_speed * grid_size.y
		tail.visible = true
		tail.scale.x = scroll
		tail.size.x = line_length
		$VisibleOnScreenEnabler2D.rect.size.y = (length + 1) * scroll_speed * 640
	else:
		tail.visible = false


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	on_screen = true
	note.visible = on_screen
	tail.visible = on_screen


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	on_screen = false
	note.visible = on_screen
	tail.visible = on_screen
