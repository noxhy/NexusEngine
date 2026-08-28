extends Node2D

var note_skin: NoteSkin
@onready var sprite = $OffsetSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.sprite_frames = note_skin.splashes_texture
	if note_skin.pixel_texture:
		sprite.texture_filter = TEXTURE_FILTER_NEAREST
	
	scale = Vector2.ONE * note_skin.splash_scale


func _on_offset_sprite_animation_finished():
	queue_free()
