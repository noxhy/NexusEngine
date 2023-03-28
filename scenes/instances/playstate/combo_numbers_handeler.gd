extends Node2D

@onready var combo_number_node = preload( "res://scenes/instances/playstate/combo_number.tscn" )

@export var ui_skin: UISkin
@export var combo = 0
@export var fc = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var digits = str( combo ).length()
	
	for digit in digits:
		
		var combo_number_instance = combo_number_node.instantiate()
		
		combo_number_instance.position.x = ui_skin.numbers_spacing * ( digit - ( digits / 2.0 ) ) * ui_skin.numbers_scale
		combo_number_instance.ui_skin = ui_skin
		combo_number_instance.digit = int( combo / pow( 10, digits - digit - 1 ) ) % 10
		combo_number_instance.fc = fc
		
		add_child( combo_number_instance )
		


func _on_timer_timeout():
	queue_free()
