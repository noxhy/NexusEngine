class_name TintTransform extends ColorTansform

@export_color_no_alpha var tint_color
@export var opacity: float
@export var shader: Shader = preload("res://assets/shaders/tint.gdshader")

func _init(t: Color, o: float) -> void:
	
	tint_color = t
	opacity = o
