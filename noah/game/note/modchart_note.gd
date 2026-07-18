extends BasicNote
## This note type is worse for performance
class_name ModChartNote

var last_length: float

# Applying Note Skin
func _ready() -> void: 
	$Note.sprite_frames = note_skin.notes_texture
	if note_skin.animation_names != null: 
		if note_skin.animation_names.keys().size() > 0: 
			$Note.animation_names.merge(note_skin.animation_names, true)
	
	$Note.play_animation(animation)
	
	var tail_animation = $Note.get_real_animation(StringName(animation + " tail"))
	if tail_animation:
		tail.texture = note_skin.notes_texture.get_frame_texture(tail_animation, 0)
	
	var end_animation = $Note.get_real_animation(StringName(animation + " end"))
	if end_animation:
		tail.end_texture = note_skin.notes_texture.get_frame_texture(end_animation, 0)
	
	$Note.offsets = note_skin.offsets
	
	if note_skin.pixel_texture: 
		$Note.texture_filter = TEXTURE_FILTER_NEAREST
		tail.texture_filter = TEXTURE_FILTER_NEAREST
	
	scale = Vector2(1, 1)
	$Note.scale = grid_size / $Note.sprite_frames.get_frame_texture($Note.animation, 0).get_size()
	tail.width = note_skin.sustain_width * $Note.scale.x


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	time_difference = (time - GameManager.offset) - GameManager.song_position
	
	if length > 0:
		var line_length = length * scroll_speed  * grid_size.y
		line_length /= note_skin.notes_scale
		
		tail.visible = true
		tail.scale.y = scroll
		
		if last_length != length:
			tail.points = [Vector2.ZERO, Vector2(0, line_length)]
	else: 
		tail.visible = false
