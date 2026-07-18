extends Note
## This note type is better for performance however the sustain isn't friendly
## for modcharts.
class_name BasicNote

const PIXELS_PER_SECOND = 450

@onready var note = $Note
@onready var tail = $Tail
@onready var end = null

var start_length: float = 0.0
var can_press: bool = false
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
	if note_skin.animation_names != null: 
		if note_skin.animation_names.keys().size() > 0: 
			note.animation_names.merge(note_skin.animation_names, true)
	
	note.play_animation(animation)
	
	var tail_animation = note.get_real_animation(animation + " tail")
	if tail_animation and tail:
		tail.texture = note_skin.notes_texture.get_frame_texture(tail_animation, 0)
	
	var end_animation = note.get_real_animation(animation + " end")
	if end_animation and end:
		end.texture = note_skin.notes_texture.get_frame_texture(end_animation, 0)
		end.size = end.texture.get_size()
	
	note.offsets = note_skin.offsets
	
	if note_skin.pixel_texture: 
		note.texture_filter = TEXTURE_FILTER_NEAREST
		tail.texture_filter = TEXTURE_FILTER_NEAREST
	
	scale = Vector2(1, 1)
	note.scale = Vector2.ONE * note_skin.notes_scale
	
	if tail:
		tail.scale = Vector2.ONE * note_skin.notes_scale
		tail.position.x = tail.texture.get_height() / 2.0 * tail.scale.x
		tail.modulate.a = note_skin.sustain_opacity
	
	if end:
		end.scale.x = note_skin.notes_scale
	
	load_basic_type()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	time_difference = time - GameManager.song_position
	
	if length > 0:
		var line_length: float = length * scroll_speed * grid_size.y
		tail.visible = true
		tail.scale.x = scroll
		tail.size.x = line_length
		end.position.x = line_length
	else:
		tail.visible = false


func update():
	if !holding:
		position.y = PIXELS_PER_SECOND * time_difference * scroll_speed * scroll
		var grid_scaler = PIXELS_PER_SECOND * GameManager.seconds_per_beat
		grid_size.y = grid_scaler
	else:
		position.y = 0


func load_basic_type():
	match note_type:
		"no_animation":
			no_animation = true
		"alt_prefix":
			anim_prefix = 'alt_'
