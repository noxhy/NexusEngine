extends Node2D


@export var load_path: String = "res://"
@export var save_path: String = "res://"

signal finished

var can_convert = true


# Called when the node enters the scene tree for the first time.
func _ready():
	
	set_process(false)
	$"UI/Input Panel/Load Path".text = load_path
	$"UI/Input Panel/Save Path".text = save_path


func _input(event):
	
	if event.is_action_pressed("ui_accept"):
		
		can_convert = false
		
		load_path = $"UI/Input Panel/Load Path".text
		save_path = $"UI/Input Panel/Save Path".text
		
		$"UI/Input Panel/Load Path".visible = false
		$"UI/Input Panel/Save Path".visible = false
		
		$"UI/Input Panel/Label2".text = "CONVERTING..."
		
		convert_dialogue()
		
		$"UI/Input Panel/Label2".text = "ENTER TO CONVERT"
		
		$"UI/Input Panel/Load Path".visible = true
		$"UI/Input Panel/Save Path".visible = true
		
		$"UI/Input Panel/Save Path".text = ""
		$"UI/Input Panel/Load Path".text = ""
		
		can_convert = true
		$"Success Sound".play()


func convert_dialogue():
	
	var json_file = FileAccess.open( load_path, FileAccess.READ )
	var json_data = json_file.get_as_text()
	
	var json = JSON.parse_string(json_data)
	var dialogue_resource = Dialogue.new()
	dialogue_resource.dialogue = ""
	
	var current_portait: String
	var current_box_state: String
	var current_speed: float
	
	for dialogue_data in json.dialogue:
		
		print( dialogue_data )
		
		if dialogue_data.portrait != current_portait:
			
			current_portait = dialogue_data.portrait
			dialogue_resource.dialogue += "func set_character " + dialogue_data.portrait + "\n"
		
		if dialogue_data.boxState != current_box_state:
			
			current_box_state = dialogue_data.boxState
			dialogue_resource.dialogue += "func set_box_state " + dialogue_data.boxState + "\n"
		
		if dialogue_data.speed != current_speed:
			
			current_speed = dialogue_data.speed
			dialogue_resource.dialogue += "func set_speed " + str( dialogue_data.speed ) + "\n"
		
		dialogue_resource.dialogue += "func set_expression " + dialogue_data.expression + "\n"
		dialogue_resource.dialogue += dialogue_data.portrait + ": " + dialogue_data.text
		
		if json.dialogue.rfind( dialogue_data ) != json.dialogue.size() - 1:
			dialogue_resource.dialogue += "\n"
	
	print( "done" )
	
	ResourceSaver.save( dialogue_resource, save_path + ".res" )
	emit_signal("finished")
