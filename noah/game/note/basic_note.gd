extends Note
## This note type is better for performance however the sustain isn't friendly
## for modcharts.
class_name BasicNote

const PIXELS_PER_SECOND = 450
const BACKUP_HOLD_TEXTURE = preload("uid://ds5jlynhtryxg")

@onready var note = $Note
@onready var tail = $Tail
@onready var end = null

## Callable for updating how the note handles its position and note length.
var update_callable: Callable = default_update
var start_length: float = 0.0
var time_difference: float = INF
var on_screen: bool = false
var holding: bool = false

var no_animation: bool = false
var damage_mult: float = 1.0
var health_mult: float = 1.0
var anim_prefix: String = ''
var splash_animation: StringName = &""
var scoreable: bool = true
var mine: bool = false
var hit: bool = false

# Applying Note Skin
func _ready() -> void: 
	end = $Tail/End
	note.sprite_frames = note_skin.notes_texture
	
	var tail_animation: StringName = animation + &"_tail"
	if tail:
		if tail_animation:
			tail.texture = note_skin.notes_texture.get_frame_texture(tail_animation, 0)
			if !tail.texture:
				tail.texture = BACKUP_HOLD_TEXTURE
	
	var end_animation: StringName = animation + &"_end"
	if end_animation and end:
		end.texture = note_skin.notes_texture.get_frame_texture(end_animation, 0)
		if end.texture:
			end.size = end.texture.get_size()
	
	note.offsets = note_skin.offsets
	note.play(animation)
	
	if note_skin.pixel_texture: 
		note.texture_filter = TEXTURE_FILTER_NEAREST
		tail.texture_filter = TEXTURE_FILTER_NEAREST
	
	note.scale = Vector2.ONE * note_skin.notes_scale
	
	if tail:
		tail.scale = Vector2.ONE * note_skin.notes_scale
		if tail.texture:
			tail.position.x = tail.texture.get_height() / 2.0 * tail.scale.x
		
		tail.modulate.a = note_skin.sustain_opacity
	
	if end:
		end.scale.x = note_skin.notes_scale
	
	load_basic_type()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	time_difference = time - GameManager.song_position


func update() -> void:
	update_callable.call()


func default_update() -> void:
	if !holding:
		position.y = PIXELS_PER_SECOND * time_difference * scroll_speed * scroll
		var grid_scaler: float = PIXELS_PER_SECOND * GameManager.conductor.seconds_per_beat
		grid_size.y = grid_scaler
	else:
		position.y = 0
	
	if length > 0:
		var line_length: float = length * scroll_speed * grid_size.y
		tail.visible = true
		tail.scale.x = scroll
		tail.size.x = line_length
		end.position.x = line_length
	else:
		tail.visible = false


func load_basic_type():
	match note_type:
		"no_animation":
			no_animation = true
		"alt_prefix":
			anim_prefix = 'alt_'


func apply_miss_effect():
	modulate *= 2
	modulate.a = min(modulate.a / 2, 0.5)
