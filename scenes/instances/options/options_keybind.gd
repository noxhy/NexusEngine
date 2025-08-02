extends OptionNode

@onready var keybind_button_node = preload( "res://scenes/instances/options/keybind_button.tscn" )

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var object_amount: int = 0
	
	for i in SettingsHandeler.get_keybind(setting_name):
		
		var keybind_button_instance = keybind_button_node.instantiate()
		
		keybind_button_instance.setting_name = setting_name
		keybind_button_instance.index = object_amount
		keybind_button_instance.position.x = $Label.size.x + ( keybind_button_instance.size.x + 50 ) * object_amount
		
		object_amount += 1
		
		add_child( keybind_button_instance )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	$Label.text = display_name
