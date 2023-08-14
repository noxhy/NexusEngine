extends Node2D


@onready var dialogue_line_preload = preload( "res://scenes/instances/dialgoue editor/dialogue_line.tscn" )


@export var dialogue: Dialogue = Dialogue.new()


var dialogue_naviagtor_nodes = []

var current_line: String
var current_index: int
var speed: float = 0.05


# Called when the node enters the scene tree for the first time.
func _ready():
	
	load_dialogue_nagivator()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	$UI/RichTextLabel.text = dialogue.dialogue
	
	$UI/ColorRect/Label.text = "Current Line: " + current_line
	$UI/ColorRect/Label.text += "\n" + "Current Index: " + str( current_index )


func dialogue_line_pressed( node: Button ):
	
	current_line = node.line
	current_index = node.index
	
	$"UI/Dialogue Reader/Speed Slider".visible = true
	
	
	if node.line_type == 0:
		
		%Dialogue.text = node.line
		read_dialogue_line( node.index )
		$"UI/Dialogue Reader/Reader Label".text = "Dialogue Reader"
	else:
		
		%Dialogue.text = node.line.split(" ")[2]
		%Character.text = node.line.split(" ")[1]
		$"UI/Dialogue Reader/Reader Label".text = "Function Editor"
		$"UI/Dialogue Reader/Speed Slider".visible = false


func _on_speed_slider_value_changed(value):
	
	speed = value
	$"UI/Dialogue Reader/Speed Slider/Label".text = "Speed: " + str( value ) + "ms"


func _on_paste_display_pressed(): %Input.text = current_line


func _on_input_text_submitted( new_text ):
	
	var dialogue_array = dialogue.dialogue.split("\n")
	dialogue_array[ current_index ] = new_text
	dialogue.dialogue = convert_array_to_string( dialogue_array )
	
	load_dialogue_nagivator()
	dialogue_line_pressed( dialogue_naviagtor_nodes[ current_index ] )


func _on_add_line_pressed():
	
	var dialogue_array = dialogue.dialogue.split("\n")
	dialogue_array.insert( current_index + 1, ":" )
	dialogue.dialogue = convert_array_to_string( dialogue_array )
	
	load_dialogue_nagivator()
	dialogue_line_pressed( dialogue_naviagtor_nodes[ current_index ] )


func _on_remove_line_pressed():
	
	var dialogue_array = dialogue.dialogue.split("\n")
	dialogue_array.remove_at( current_index )
	dialogue.dialogue = convert_array_to_string( dialogue_array )
	
	load_dialogue_nagivator()
	dialogue_line_pressed( dialogue_naviagtor_nodes[ current_index ] )


# Util


func load_dialogue_nagivator():
	
	for i in dialogue_naviagtor_nodes.size():
		
		dialogue_naviagtor_nodes[0].queue_free()
		dialogue_naviagtor_nodes.remove_at( 0 )
	
	var i: int = 0
	
	for line in dialogue.dialogue.split("\n"):
		
		
		var dialogue_line_instance = dialogue_line_preload.instantiate()
		
		dialogue_line_instance.line = line
		dialogue_line_instance.index = i
		
		
		$"UI/Dialogue Navigator/ScrollContainer/VBoxContainer".add_child( dialogue_line_instance )
		
		dialogue_line_instance.connect( "button", dialogue_line_pressed )
		
		dialogue_naviagtor_nodes.append( dialogue_line_instance )
		
		i += 1


func _on_save_button_pressed():
	
	ResourceSaver.save( dialogue, dialogue.resource_path )


func read_dialogue_line( index: int ):
	
	var line = dialogue.dialogue.split( "\n" )[ index ]
	
	var character = line.split(":")[0]
	var line_said = line.split(":")[1].trim_prefix(" ")
	
	%Character.text = character
	%Dialogue.text = line_said
	%Dialogue.visible_characters = 0
	
	for i in line_said:
		
		if current_line != line:
			
			%Dialogue.visible_characters = -1
			break
		
		var delay: float = speed
		var slow_characters = ".?!,"
		
		%Dialogue.visible_characters += 1
		
		if i == " ": continue
		
		if slow_characters.find(i) != -1: delay = 0.25
		
		await get_tree().create_timer( delay ).timeout


func convert_array_to_string( array: Array ) -> String:
	
	var string: String
	
	for i in array:
		
		string += i
		if array.rfind(i) != array.size() - 1: string += "\n"
	
	return string

