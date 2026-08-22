extends BasicNote
class_name ChartNote

@onready var area = $Area2D
@onready var collision_shape = $Area2D/CollisionShape2D
@onready var label = %"Special Note Label"
@onready var screen_enabler = $VisibleOnScreenEnabler2D

# Applying Note Skin
func _ready() -> void:
	note.texture = note_skin.notes_texture.get_frame_texture(get_animation_name(animation), 0)
	
	var tail_animation = get_animation_name(animation + &"_tail")
	if tail_animation:
		tail.texture = note_skin.notes_texture.get_frame_texture(tail_animation, 0)
	
	if note_skin.pixel_texture: 
		note.texture_filter = TEXTURE_FILTER_NEAREST
		tail.texture_filter = TEXTURE_FILTER_NEAREST
	
	update()

func update():
	if note:
		note.size = grid_size
		note.position = -note.size / 2
		
		if tail:
			tail.scale = grid_size / note.texture.get_size()
			if tail.texture:
				tail.position.x = tail.texture.get_height() / 2.0 * tail.scale.x
		
		screen_enabler.scale = grid_size / Vector2(640, 640)
		
		if collision_shape:
			collision_shape.shape = RectangleShape2D.new()
			collision_shape.scale = screen_enabler.scale * 0.9
			collision_shape.shape.set_size(Vector2(screen_enabler.rect.size.x, screen_enabler.rect.size.x))
			
			label.size = grid_size
			label.position = -grid_size / 2
			label.label_settings.font_size = grid_size.y / 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	time_difference = (time - GameManager.conductor.offset) - GameManager.song_position
	
	if length > 0:
		var line_length = length * scroll_speed * grid_size.y
		tail.visible = true
		tail.scale.x = scroll
		tail.size.x = line_length
		screen_enabler.rect.size.y = (length + 1) * scroll_speed * 640
	else:
		tail.visible = false


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	on_screen = true
	note.visible = on_screen
	tail.visible = on_screen
	label.visible = (note_type != "")


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	on_screen = false
	note.visible = on_screen
	tail.visible = on_screen
	label.visible = on_screen
