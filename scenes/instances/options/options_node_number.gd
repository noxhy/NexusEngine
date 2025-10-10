extends OptionNode

@export var min: float = 0.0
@export var max: float = 100.0
@export var step: float = 1.0
@export var value_name: String = ""
@export var value_scale = 1.0 # Multiplies this value (Used for shit like milliseconds)

@onready var spin_box := $SpinBox

# Called when the node enters the scene tree for the first time.
func _ready(): 
	var savedValue = clampf(SettingsManager.get_setting(setting_name) / value_scale, min, max);
	
	spin_box.min_value = min
	spin_box.max_value = max
	spin_box.step = step
	spin_box.value = savedValue

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta): 
	
	$SpinBox.position.x = $Label.size.x + 5
	$Label.text = display_name
	
	$SpinBox/Label2.position.x = $SpinBox.size.x
	$SpinBox/Label2.text = value_name


func _on_spin_box_value_changed(value): 
	
	var newValue = clampf(value, min, max); # the spin box idfk is stupid dude so no
	
	spin_box.set_value_no_signal(newValue)
	
	if step == 1: 
		newValue = int(newValue)
	if value_scale == 1: 
		int(value_scale)
		
	SettingsManager.set_setting(setting_name, newValue * value_scale)
	
