extends OptionNode

@export var min: float = 0.0
@export var max: float = 100.0
@export var step: float = 1.0
@export var value_name: String = ""
@export var value_scale = 1.0 # Multiplies this value (Used for shit like milliseconds)


# Called when the node enters the scene tree for the first time.
func _ready():
	
	$HSlider.min_value = min
	$HSlider.max_value = max
	$HSlider.step = step
	$HSlider.value = SettingsHandeler.get_setting( setting_name ) / value_scale


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	$HSlider.position.x = $Label.size.x + 20
	$Label.text = display_name + ": " + str( $HSlider.value ) + " " + value_name


func _on_h_slider_value_changed(value):
	
	if step == 1: value = int( value )
	SettingsHandeler.set_setting( setting_name, value * value_scale )
	SettingsHandeler.save_settings()
