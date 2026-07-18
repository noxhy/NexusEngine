extends Control
class_name ModNode

enum ButtonStyle {
	IDLE,
	HOVER,
	ACTIVE,
	WRONG
}

@onready var icon = $HBoxContainer/Icon
@onready var name_label = $HBoxContainer/VBoxContainer/Name
@onready var description_label = $HBoxContainer/VBoxContainer/Credits

var dir: String
var errors: Array = []

var image: Texture:
	set(v):
		icon.texture = v
		image = v

var mod_name: String:
	set(v):
		name_label.text = v
		mod_name = v

var description: String:
	set(v):
		description_label.text = v
		description = v


func change_style(style: ButtonStyle):
	match style:
		ButtonStyle.HOVER:
			add_theme_stylebox_override("panel", load("uid://cqdejo2t6nvn2"))
		
		ButtonStyle.ACTIVE:
			add_theme_stylebox_override("panel", load("uid://ctkse30cncsl3"))
		
		ButtonStyle.WRONG:
			add_theme_stylebox_override("panel", load("uid://cicj0oltk4xrc"))
		
		_:
			add_theme_stylebox_override("panel", load("uid://d0f8qx5ndub6d"))
