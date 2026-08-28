extends Node2D


@export var ui_skin: UISkin
var rating: String = "sick"
var motion: Vector2
var gravity = 0.0

var elapsed: float = 0.0

@onready var sprite = $OffsetSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.sprite_frames = ui_skin.rating_texture
	
	sprite.offsets = ui_skin.offsets
	sprite.scale = Vector2(ui_skin.rating_scale, ui_skin.rating_scale) 
	
	if ui_skin.pixel_texture:
		sprite.texture_filter = TEXTURE_FILTER_NEAREST
	
	sprite.play()
	sprite.play(rating)
	
	motion = Vector2(randf_range(-0.1, 0.1), -2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if $Timer.time_left <= 0.7:
		self.modulate.a -= delta / 0.25
	
	self.position += motion * self.scale
	motion.y -= delta * gravity
	gravity += -40 * delta


func _on_timer_timeout():
	queue_free()
