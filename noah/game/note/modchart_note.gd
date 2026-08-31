extends BasicNote
## This note type is worse for performance
class_name ModChartNote

var last_length: float
var update_tail: Callable = func() -> void:
	var line_length: float = length * scroll_speed * grid_size.y
	tail.visible = true
	tail.points = [Vector2.ZERO, Vector2(0, line_length)]

# Applying Note Skin
func _ready() -> void: 
	note.sprite_frames = note_skin.notes_texture
	if note_skin.animation_names != null: 
		if note_skin.animation_names.keys().size() > 0: 
			note.animation_names.merge(note_skin.animation_names, true)
	
	var tail_animation: StringName = animation + &"_tail"
	if tail_animation and tail:
		tail.texture = note_skin.notes_texture.get_frame_texture(tail_animation, 0)
		if !tail.texture:
			tail.texture = BACKUP_HOLD_TEXTURE
	
	var end_animation: StringName = animation + &"_end"
	if end_animation and tail:
		tail.end_texture = note_skin.notes_texture.get_frame_texture(end_animation, 0)
	
	note.offsets = note_skin.offsets
	note.play_animation(animation)
	
	if note_skin.pixel_texture: 
		note.texture_filter = TEXTURE_FILTER_NEAREST
		tail.texture_filter = TEXTURE_FILTER_NEAREST
	
	note.scale = Vector2.ONE * note_skin.notes_scale
	
	if tail:
		tail.modulate.a = note_skin.sustain_opacity
		if tail.texture:
			tail.width = tail.texture.get_height()
		
		tail.scale.x = note_skin.notes_scale
	
	load_basic_type()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	time_difference = (time - GameManager.conductor.offset) - GameManager.song_position
	
	if length > 0:
		update_tail.call()
	else:
		tail.visible = false
