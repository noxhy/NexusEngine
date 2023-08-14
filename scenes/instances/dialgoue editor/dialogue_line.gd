extends Button

@export_enum( "DIALOGUE", "FUNCTION" ) var line_type

@export var line: String
@export var index: int

signal button( node: Button )

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$Label.text = line
	
	if line.split(" ")[0] == "func": line_type = 1
	else: line_type = 0
	
	if line_type == 0:
		
		$Label.label_settings.font_color = Color( 1, 1, 1 ) 
	else:
		
		$Label.text = line.substr( 5 )
		$Label.label_settings.font_color = Color(0.553, 0.573, 1)


func _on_pressed(): emit_signal( "button", self )
