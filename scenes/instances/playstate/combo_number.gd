extends Node2D


@export var ui_skin: UISkin
var digit: int
var motion: Vector2
var gravity = 0.0
var fc = false


# Called when the node enters the scene tree for the first time.
func _ready():
	
	$OffsetSprite.sprite_frames = ui_skin.numbers_texture
	
	if ui_skin.animation_names != null:
		$OffsetSprite.animation_names.merge( ui_skin.animation_names, true )
	
	$OffsetSprite.offsets = ui_skin.offsets
	$OffsetSprite.scale = Vector2( ui_skin.numbers_scale, ui_skin.numbers_scale ) 
	
	if ui_skin.pixel_texture: 
		$OffsetSprite.texture_filter = TEXTURE_FILTER_NEAREST
	
	$OffsetSprite.play()
	
	if fc: 
		$OffsetSprite.play_animation( "fc_" + str( digit ) )
	else:
		$OffsetSprite.play_animation( str( digit ) )
	
	motion = Vector2( randf_range( -0.25, 0.25 ), -2 )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	self.modulate.a -= delta * 1.8
	
	self.position += motion
	motion.y -= delta * gravity
	gravity += -50 * delta


func _on_timer_timeout():
	
	queue_free()
