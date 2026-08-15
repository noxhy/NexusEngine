extends Node2D

@export var note_skin = NoteSkin.new()

@onready var sprite = $OffsetSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.sprite_frames = note_skin.splashes_texture
	
	if note_skin.animation_names:
		sprite.animation_names.merge(note_skin.animation_names, true)
	
	sprite.offsets = note_skin.offsets
	
	if note_skin.pixel_texture:
		sprite.texture_filter = TEXTURE_FILTER_NEAREST
	
	sprite.play()


func _on_offset_sprite_animation_finished():
	queue_free()
