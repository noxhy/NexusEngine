extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

var timer: float = 0
func _physics_process(delta: float) -> void:
	timer += delta * 2
	modulate.a = 1 - sin(timer)
