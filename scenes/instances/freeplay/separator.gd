extends Node2D

@export_color_no_alpha var active_color = Color(1, 1, 1)
@export_color_no_alpha var inactive_color = Color(0.5, 0.5, 0.5)
@export var disabled_color: Color = Color(0.5, 0.5, 0.5, 0.5)
@export_enum("inactive", "active", "disabled") var state: int = 0:
	set(v): 
		
		state = v
		match v:
			
			1:
				modulate = active_color
			
			2:
				modulate = disabled_color
			
			_:
				modulate = inactive_color

var difficulty: String
