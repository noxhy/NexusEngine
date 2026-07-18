extends Node2D
class_name MenuOption

@export var text: String = "Menu Option"
@export var icon: Texture

@onready var label: Variant
@onready var sprite = $Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label = $Label
	label.text = text
	if icon:
		sprite.texture = icon
		await Engine.get_main_loop().process_frame
		sprite.position.x = label.size.x + sprite.texture.get_width() * 0.5 + 15
