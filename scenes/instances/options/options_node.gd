extends Control
class_name OptionNode

@export var setting_name: String = ""
@export_multiline var display_name = ""


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	$Label.text = display_name
