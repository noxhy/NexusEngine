extends OptionNode


# Called when the node enters the scene tree for the first time.
func _ready():
	
	$CheckButton.button_pressed = SettingsManager.get_setting( setting_name )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	$CheckButton.position.x = $Label.size.x + 20
	$Label.text = display_name


func _on_check_button_toggled(button_pressed):
	
	SettingsManager.set_setting( setting_name, button_pressed )
	SettingsManager.save_settings()
