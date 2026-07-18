extends OptionNode
class_name KeyBindOptionNode

var KEYBIND_BUTTON_PRELOAD = load("uid://darhx23v4e15y")

var selected: int = 0
var object_amount: int = 0
var buttons: Array[Button] = []

@export_enum("Key", "Controller") var type: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Label.text = display_name
	var bind_list: Array
	
	match type:
		0:
			bind_list = SettingsManager.get_keybind(setting_name)
		
		1:
			bind_list = SettingsManager.get_controller_bind(setting_name)
	
	for i in bind_list:
		var keybind_button_instance = KEYBIND_BUTTON_PRELOAD.instantiate()
		keybind_button_instance.setting_name = setting_name
		keybind_button_instance.index = object_amount
		keybind_button_instance.type = type
		
		object_amount += 1
		
		$HBoxContainer.add_child(keybind_button_instance)
		keybind_button_instance.connect("mouse_entered", self.select_button.bind(keybind_button_instance.index))
		#keybind_button_instance.connect("pressed")
		# keybind_button_instance.connect("mouse_exited", get_tree().call_group.bind("buttons", "normal"))
		buttons.append(keybind_button_instance)

func select_button(i: int):
	selected = wrapi(i, 0, buttons.size())
	get_tree().call_group("buttons", "normal")
	if i > -1:
		SoundManager.scroll.play()
		buttons[selected].select()

func normal():
	super()
	selected = -1
