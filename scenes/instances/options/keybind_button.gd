extends OptionNode

@export var checking = false
@export var index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	self.text = OS.get_keycode_string( SettingsHandeler.get_keybind( setting_name )[index] )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _input(event):
	
	if checking:
		
		if event is InputEventKey:
			
			checking = false
			SettingsHandeler.set_keybind( setting_name, event.keycode, index )
			SettingsHandeler.save_settings()
			SettingsHandeler.load_settings()
			self.text = OS.get_keycode_string( SettingsHandeler.get_keybind( setting_name )[index] )
			self.button_pressed = false


func _on_toggled(button_pressed):
	
	if button_pressed:
		
		self.text = "..."
		checking = true
