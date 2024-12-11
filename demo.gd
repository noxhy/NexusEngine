extends Node2D

@onready var swf:SwfAnimation = $SwfAnimation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#swf.set_animation("WAI")
	swf.set_animation("default")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
