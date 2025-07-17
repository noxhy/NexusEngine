class_name AdvancedTransform extends ColorTansform

@export var multiplier: Color
@export var offset: Color
@export var shader: Shader = preload("res://assets/shaders/advanced_transform.gdshader")

func _init(m: Color, o: Color) -> void:
	
	multiplier = m
	offset = o
