extends OptionNode
class_name BoolOptionNode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Button.button_pressed = SettingsManager.get_value(setting_category, setting_name)
	%Label.text = display_name
	update()

func _on_check_button_toggled(button_pressed):
	SettingsManager.set_value(setting_category, setting_name, button_pressed)
	SoundManager.accept.play()
	update()

func update():
	%Button.text = str(%Button.button_pressed).capitalize()
