@icon("uid://kdr1a765du27")
extends Node
class_name CameraController


## A camera2D node that this will control.
@export var parent_2d: Camera2D

## A camera3D node that this will control.
@export var parent_3d: Camera3D

#can we change these var names some time
@export_category('Camera Config')
## The intended camera zoom. The camera will automatically attempt to lerp to this zoom.
var target_zoom: Vector2 = Vector2(1, 1)

@export_group("Zoom Smoothing")
## If [code]true[/code], the camera's zoom smoothly zoom towards its target position at [member zoom_smoothing_speed].
@export_custom(PROPERTY_HINT_GROUP_ENABLE, '') var zoom_smoothing: bool = true
## The asymptotic speed of the camera's zoom smoothing effect when [member zoom_smoothing] is true.
@export_custom(PROPERTY_HINT_RANGE, '1,64,suffix:weight') var zoom_smoothing_speed: float = 5


@export_group("Position Smoothing")
## If [code]true[/code], the camera's view smoothly moves towards its target position at [member position_smoothing_speed].
@export_custom(PROPERTY_HINT_GROUP_ENABLE, '') var position_smoothing: bool = true : 
	set(v):
		if parent_2d:
			parent_2d.position_smoothing_enabled = v
		position_smoothing = v
## Speed in pixels per second of the camera's smoothing effect when [member position_smoothing_enabled] is true.
@export_custom(PROPERTY_HINT_NONE, 'suffix:px/s') var position_smoothing_speed: float = 3.0 : 
	set(v):
		if parent_2d:
			parent_2d.position_smoothing_speed = v
		position_smoothing_speed = v


@export_group("Rotation Smoothing")
## If [code]true[/code], the camera's view smoothly rotates, via asymptotic smoothing, to align with its target rotation at [member rotation_smoothing_speed].
@export_custom(PROPERTY_HINT_GROUP_ENABLE, '') var rotation_smoothing: bool = true : 
	set(v):
		if parent_2d:
			parent_2d.rotation_smoothing_enabled = v
		rotation_smoothing = v
## The angular, asymptotic speed of the camera's rotation smoothing effect when [member rotation_smoothing_enabled] is true.
@export var rotation_smoothing_speed: float = 5.0 : 
	set(v):
		if parent_2d:
			parent_2d.rotation_smoothing_speed = v
		rotation_smoothing_speed = v

@export_group("Shake Settings")

## How quickly to move through the noise
@export var shake_speed: float = 30.0
## Noise returns values in the range (-1, 1)
## [br][br]So this is how much to multiply the returned value by
@export var shake_strength: float = 60.0
## The starting range of possible offsets using random values
@export var random_shake_strength: float = 30.0
## Multiplier for lerping the shake strength to zero
@export var shake_decay_rate: float = 3.0

var default_offset: Vector2
var shake_time: float = 0.0
var shaking: bool = false

var noise = FastNoiseLite.new()
var rand = RandomNumberGenerator.new()
var noise_i: float = 0.0

var _position_3d: Vector3 = Vector3.ZERO # needed for parity with camera 2d
var _rotation_3d: Vector3 = Vector3.ZERO # needed for parity with camera 2d

var rotation: Variant : set = set_rotation, get = get_rotation
var position: Variant : set = set_position, get = get_position
var zoom: Variant : set = set_zoom, get = get_zoom

func _ready() -> void:
	if not parent_2d and not parent_3d:
		printerr('(Camera Controller): No parent was assigned.')
	
	if parent_2d:
		default_offset = parent_2d.offset
		parent_2d.position_smoothing_enabled = position_smoothing
		parent_2d.position_smoothing_speed = position_smoothing_speed
		parent_2d.rotation_smoothing_enabled = rotation_smoothing
		parent_2d.rotation_smoothing_speed = rotation_smoothing_speed
		
		target_zoom = parent_2d.zoom
	elif parent_3d:
		default_offset = Vector2(parent_3d.h_offset, parent_3d.v_offset)
		_position_3d = parent_3d.position
		target_zoom = Vector2(parent_3d.fov, parent_3d.fov)

## returns the actual camera node ([code]Camera2D[/code], [code]Camera3D[/code]) used by [code]this[/code]
func get_direct() -> Variant:
	if parent_2d: 
		return parent_2d
	elif parent_3d:
		return parent_3d
	return null

#region setters/getters
func set_zoom(value: Variant) -> void:
	if value == null: return
	
	if parent_2d:
		if value is Vector2:
			parent_2d.zoom = value
		elif value is float:
			parent_2d.zoom = Vector2(value, value)
	elif parent_3d:
		if value is Vector2:
			parent_3d.fov = value.x
		if value is float:
			parent_3d.fov = value

func get_zoom() -> Variant:
	if parent_2d: return parent_2d.zoom
	elif parent_3d: return parent_3d.fov
	return Vector2.ZERO

func set_position(value: Variant) -> void:
	if value == null: return
	
	if parent_2d:
		if value is Vector3:
			value = Vector2(value.x, value.y)
		parent_2d.position = value
	
	elif parent_3d:
		if value is Vector2:
			if position_smoothing:
				_position_3d.x = value.x
				_position_3d.y = value.y
				return
			
			parent_3d.position.x = value.x
			parent_3d.position.y = value.y
		if value is Vector3:
			if position_smoothing:
				_position_3d = value
				return
			parent_3d.position = value

func get_position() -> Variant:
	if parent_2d: return parent_2d.position
	elif parent_3d: return parent_3d.position
	return Vector2.ZERO

func set_rotation(value: Variant) -> void:
	if value == null: return
	
	if parent_2d:
		if value is Vector3:
			value = Vector2(value.x, value.y)
		parent_2d.rotation = value
	
	elif parent_3d:
		if value is Vector2:
			if position_smoothing:
				_rotation_3d.x = value.x
				_rotation_3d.y = value.y
				return
			
			parent_3d.rotation.x = value.x
			parent_3d.rotation.y = value.y
		if value is Vector3:
			if rotation_smoothing:
				_rotation_3d = value
				return
			parent_3d.rotation = value

func get_rotation() -> Variant:
	if parent_2d: return parent_2d.rotation
	elif parent_3d: return parent_3d.rotation
	return Vector2.ZERO
#endregion

func _process(delta) -> void:
	if parent_2d: 
		update_2d(delta)
	if parent_3d: 
		update_3d(delta)
	if shaking:
		update_shake(delta)

func update_2d(delta: float) -> void:
	if zoom_smoothing:
		parent_2d.zoom = Global.frame_independent_lerp(parent_2d.zoom, target_zoom, zoom_smoothing_speed, delta)

func update_3d(delta: float) -> void:
	if zoom_smoothing:
		parent_3d.fov = Global.frame_independent_lerp(parent_3d.fov, target_zoom.x, zoom_smoothing_speed, delta)
	
	if position_smoothing:
		parent_3d.position = lerp_position(parent_3d.position, _position_3d, delta)
	
	if rotation_smoothing:
		var rot_rate: float = delta * rotation_smoothing_speed
		parent_3d.rotation.x = lerp_angle(parent_3d.rotation.x, _rotation_3d.x, rot_rate)
		parent_3d.rotation.y = lerp_angle(parent_3d.rotation.y, _rotation_3d.y, rot_rate)
		parent_3d.rotation.z = lerp_angle(parent_3d.rotation.z, _rotation_3d.z, rot_rate)

func update_shake(delta: float) -> void:
	shake_strength = move_toward(shake_strength, 0, shake_decay_rate * delta)
	
	var shake_offset: Vector2 = get_noise_offset(delta, shake_speed, shake_strength)
	if parent_2d:
		parent_2d.offset = shake_offset + default_offset
	elif parent_3d:
		parent_3d.h_offset = shake_offset.x + default_offset.x
		parent_3d.v_offset = shake_offset.y + default_offset.y
	
	shake_time -= delta
	if shake_time <= 0:
		end_shake()


func shake(amount: int, time: float) -> void:
	noise.seed = randi()
	noise.frequency = 2
	
	shake_time = time
	shake_decay_rate = 1 / amount
	shake_strength = amount
	shaking = true

func end_shake() -> void:
	shaking = false
	
	if not parent_2d and not parent_3d:
		return
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
	
	if parent_2d:
		tween.tween_property(parent_2d, "offset", default_offset, 0.1)
	elif parent_3d:
		tween.set_parallel()
		tween.tween_property(parent_3d, "h_offset", default_offset.x, 0.1)
		tween.tween_property(parent_3d, "v_offset", default_offset.y, 0.1)

func get_noise_offset(delta: float, speed: float, strength: float) -> Vector2:
	noise_i += delta * speed
	# Set the x values of each call to 'get_noise_2d' to a different value
	# so that our x and y vectors will be reading from unrelated areas of noise
	return Vector2(
		noise.get_noise_2d(1, noise_i),
		noise.get_noise_2d(100, noise_i)
	) * strength

func bump(strength: Variant) -> void:
	if parent_3d:
		strength *= -1
		zoom += strength
	if parent_2d:
		if strength is float:
			zoom += Vector2(strength, strength)
		else:
			zoom += strength

## Moves the camera's [member position] and [member rotation] to a [code]Marker2D[/code] or [code]Marker3D[/code]
## [br][br]This method abides by the [member position_smoothing] and [member rotation_smoothing] settings.
## [br][br]Check [method tween_to_marker] for eased movements
func go_to_marker(marker: Variant) -> void:
	if _marker_tween:
		_marker_tween.kill()
		_reapply_smoothing_settings()
	
	position = marker.global_position
	rotation = marker.global_rotation

var _last_position_smoothing: bool = true
var _last_rotation_smoothing: bool = true
var _marker_tween: Tween = null

func _reapply_smoothing_settings():
	position_smoothing = _last_position_smoothing
	rotation_smoothing = _last_rotation_smoothing
	
## Tweens the camera's [member position] and [member rotation] to a [code]Marker2D[/code] or [code]Marker3D[/code] in the span of the [code]duration[/code]
## [br][br]See [code]Global.string_to_ease[/code] for ease options
## [br][br]This method ignores [member position_smoothing] and [member rotation_smoothing] 
func tween_to_marker(marker: Variant, duration: float, ease_type: String = '') -> void:
	
	if _marker_tween:
		_marker_tween.kill()
		_reapply_smoothing_settings()
	
	_last_position_smoothing = position_smoothing
	_last_rotation_smoothing = rotation_smoothing
	
	position_smoothing = false
	rotation_smoothing = false
	
	var ease_info: Array = Global.string_to_ease(ease_type)
	
	_marker_tween = create_tween().set_trans(ease_info[0]).set_ease(ease_info[1])
	
	_marker_tween.tween_property(self, 'position', marker.global_position, duration)
	_marker_tween.tween_property(self, 'rotation', marker.global_rotation, duration)
	_marker_tween.finished.connect(_reapply_smoothing_settings)

var _zoom_tween: Tween = null
## Tweens the camera's [member zoom] to [code]new_zoom[/code] in the span of [code]duration[/code]
## [br][br]See [code]Global.string_to_ease[/code] for ease options
func tween_zoom(new_zoom: Vector2, duration: float, ease_type: String = ''):
	
	if _zoom_tween:
		_zoom_tween.kill()
		
	var ease_info: Array = Global.string_to_ease(ease_type)
	
	_zoom_tween = create_tween().set_parallel().set_trans(ease_info[0]).set_ease(ease_info[1])
	
	_zoom_tween.tween_property(self, 'target_zoom', new_zoom, duration)
	_zoom_tween.tween_property(self, 'zoom', new_zoom, duration)

## Recreation of godot's internal method for [code]position_smoothing[/code].
## [br][br]Used to give [code]Camera3D[/code] [member position_smoothing]
func lerp_position(cur: Variant, intended: Variant, delta: float) -> Variant:
	var c = position_smoothing_speed * delta
	return ((intended - cur) * c) + cur
