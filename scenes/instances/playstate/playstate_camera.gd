extends Camera2D
class_name PlayStateCamera


@export_subgroup("Essentials")

@export var target_zoom: Vector2 = Vector2(1, 1)
@export var lerp_weight: float = 0.1

@export var lerping = true

@export_subgroup("Shaking")

@export var shake_time: float = 0.0
@export var shaking: bool = false
@export var shake_amount: int = 0
var default_offset = offset


func _ready():
	
	randomize()


func _physics_process(delta):
	
	if lerping:
		
		zoom = lerp( zoom, target_zoom, lerp_weight )
	
	
	# Camera Shaking
	
	if shaking:
		
		offset = Vector2( randi_range(-1, 1) * shake_amount, randi_range(-1, 1) * shake_amount )
		
		shake_time -= delta
		if shake_time <= 0: end_shake()


func shake( amount: int, time: float ):
	
	shake_time = time
	shake_amount = amount
	shaking = true


func end_shake():
	
	shaking = false
	
	var tween = create_tween()
	tween.set_trans( Tween.TRANS_ELASTIC ).set_ease( Tween.EASE_IN_OUT )
	tween.tween_property( self, "offset", default_offset, 0.1 )
