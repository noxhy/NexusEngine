extends Node2D


@export var ui_skin: UISkin
var rating: String = "sick"
var motion: Vector2
var gravity = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	
	$OffsetSprite.sprite_frames = ui_skin.rating_texture
	
	if ui_skin.animation_names != null:
		
		$OffsetSprite.animation_names.merge( ui_skin.animation_names, true )
	
	$OffsetSprite.offsets = ui_skin.offsets
	$OffsetSprite.scale = Vector2( ui_skin.rating_scale, ui_skin.rating_scale ) 
	
	if ui_skin.pixel_texture:
		$OffsetSprite.texture_filter = TEXTURE_FILTER_NEAREST
	
	$OffsetSprite.play()
	
	$OffsetSprite.play_animation( rating )
	
	motion = Vector2( randf_range( -1, 1 ), -2 )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	self.modulate.a -= delta * 1.8
	
	self.position += motion
	motion.y -= delta * gravity
	gravity += -50 * delta


func _on_timer_timeout():
	
	queue_free()
