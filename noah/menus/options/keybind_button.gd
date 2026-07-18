extends OptionNode

@export var checking = false
@export var index = 0
@export_enum("Key", "Controller") var type: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_text()
	Input.joy_connection_changed.connect(self.update_text)

func _input(event):
	if checking:
		match type:
			0:
				if event is InputEventKey:
					if event.is_pressed():
						if event.keycode == KEY_DELETE:
							event.keycode = KEY_NONE
						
						checking = false
						SettingsManager.set_keybind(setting_name, event.keycode, index)
						SettingsManager.flush()
						self.text = OS.get_keycode_string(event.keycode)
						self.button_pressed = false
						SoundManager.accept.play()
			
			1:
				if event is InputEventJoypadButton:
					if event.is_pressed():
						if event.button_index == JOY_BUTTON_GUIDE:
							event.button_index = JOY_BUTTON_INVALID
						
						checking = false
						SettingsManager.set_controller_bind(setting_name, event.button_index, index)
						SettingsManager.flush()
						update_text()
						self.button_pressed = false
						SoundManager.accept.play()
				elif event is InputEventJoypadMotion:
					checking = false
					if event.axis == JoyAxis.JOY_AXIS_TRIGGER_LEFT or event.axis == JoyAxis.JOY_AXIS_TRIGGER_RIGHT:
						SettingsManager.set_controller_bind(setting_name, event.axis + 100, index)
						SettingsManager.flush()
						update_text()
						self.button_pressed = false
						SoundManager.accept.play()


func _on_toggled(button_pressed):
	if button_pressed:
		self.text = "..."
		checking = true


func select():
	var hover_style = get_theme_stylebox("hover", "Button")
	add_theme_stylebox_override("normal", hover_style)

func normal():
	remove_theme_stylebox_override("normal")
	checking = false
	update_text()
	self.button_pressed = false
	_on_toggled(false)


func update_text(device: int = -1, connected: bool = false):
	match type:
		0:
			self.text = OS.get_keycode_string(SettingsManager.get_keybind(setting_name)[index])
		
		1: 
			if device == -1:
				self.text = SettingsManager.translate_joy_bind(Global.current_controller, SettingsManager.get_controller_bind(setting_name)[index])
			else:
				self.text = SettingsManager.translate_joy_bind(device, SettingsManager.get_controller_bind(setting_name)[index])
