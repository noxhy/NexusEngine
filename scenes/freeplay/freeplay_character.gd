class_name FreeplayCharacter extends Node2D

## [code]start_frame[/code] - Starting frame
## [code]end_frame[/code] - Ending frame
@export var animation_data: Dictionary[String, String]:
	set(v):
		
		animation_data = v
		
		for a_name in animation_data:
			
			if a_name == animation:
				animation = a_name

@export var animation: String:
	set(v):
		
		if animated_symbol != null:
			
			animation = v
			animated_symbol.symbol = animation_data.get(v, "")

@onready var animated_symbol = $AnimateSymbol
