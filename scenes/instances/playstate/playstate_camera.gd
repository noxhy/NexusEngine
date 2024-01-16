extends Camera2D
class_name PlayStateCamera

@onready var noise = FastNoiseLite.new()
@onready var rand = RandomNumberGenerator.new()

@export_subgroup("Essentials")

@export var target_zoom: Vector2 = Vector2(1, 1)
@export var lerp_weight: float = 0.1

@export var lerping = true

@export_subgroup("Shaking")

@export var shake_time: float = 0.0
@export var shaking: bool = false
var default_offset = offset

# How quickly to move through the noise
@export var shake_speed: float = 30.0
# Noise returns values in the range (-1, 1)
# So this is how much to multiply the returned value by
@export var shake_strength: float = 60.0
# The starting range of possible offsets using random values
@export var random_shake_strength: float = 30.0
# Multiplier for lerping the shake strength to zero
@export var shake_decay_rate: float = 3.0

var noise_i: float = 0.0



func _ready():
	
	# noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.163


func _physics_process(delta):
	
	if lerping:
		
		zoom = lerp( zoom, target_zoom, lerp_weight )
	
	
	# Camera Shaking0
	
	if shaking:
		
		shake_strength = lerp(shake_strength, 0.0, shake_decay_rate * delta)
		
		var shake_offset: Vector2 = get_noise_offset(delta, shake_speed, shake_strength)
		offset = shake_offset
		
		shake_time -= delta
		if shake_time <= 0: end_shake()


func shake( amount: int, time: float ):
	
	shake_time = time
	shake_decay_rate = time
	shake_strength = amount
	shaking = true


func end_shake():
	
	shaking = false
	
	var tween = create_tween()
	tween.set_trans( Tween.TRANS_ELASTIC ).set_ease( Tween.EASE_IN_OUT )
	tween.tween_property( self, "offset", default_offset, 0.1 )


func get_noise_offset(delta: float, speed: float, strength: float) -> Vector2:
	
	noise_i += delta * speed
	# Set the x values of each call to 'get_noise_2d' to a different value
	# so that our x and y vectors will be reading from unrelated areas of noise
	return Vector2(
		noise.get_noise_2d(1, noise_i) * strength,
		noise.get_noise_2d(100, noise_i) * strength
	)
