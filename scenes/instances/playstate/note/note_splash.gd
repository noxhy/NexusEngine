extends Node2D

@export var note_skin = NoteSkin.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$OffsetSprite.sprite_frames = note_skin.splashes_texture
	
	if note_skin.animation_names != null:
		$OffsetSprite.animation_names.merge( note_skin.animation_names, true )
	
	$OffsetSprite.offsets = note_skin.offsets
	
	if note_skin.pixel_texture:
		$OffsetSprite.texture_filter = TEXTURE_FILTER_NEAREST
	
	$OffsetSprite.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_offset_sprite_animation_finished():
	queue_free()
