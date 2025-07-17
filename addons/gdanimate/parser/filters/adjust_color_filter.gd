class_name AdjustColorFilter extends Filter


@export var hue: float
@export var brightness: float
@export var contrast: float
@export var saturation: float
@export var shader: Shader = load("res://assets/shaders/adjust_hsv.gdshader")
