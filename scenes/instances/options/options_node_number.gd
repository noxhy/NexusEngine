extends OptionNode

@export var min: float = 0.0
@export var max: float = 100.0
@export var step: float = 1.0
@export var value_name: String = ""
@export var value_scale = 1.0 # Multiplies this value (Used for shit like milliseconds)


# Called when the node enters the scene tree for the first time.
func _ready():
	
	$SpinBox.min_value = min
	$SpinBox.max_value = max
	$SpinBox.step = step
	$SpinBox.value = SettingsManager.get_setting( setting_name ) / value_scale


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	$SpinBox.position.x = $Label.size.x + 5
	$Label.text = display_name
	
	$SpinBox/Label2.position.x = $SpinBox.size.x
	$SpinBox/Label2.text = value_name


func _on_spin_box_value_changed(value):
	
	if step == 1: value = int( value )
	SettingsManager.set_setting( setting_name, value * value_scale )
	SettingsManager.save_settings()
