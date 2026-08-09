extends Resource
class_name CameraValue

#while yeah i could use smth like a vec2 this is more readable to me

var current: Vector2
## The intended value. The camera will lerp current to this value.
var target: Vector2

func snap() -> void:
	current = target
