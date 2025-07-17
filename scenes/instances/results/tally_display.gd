extends Node2D

const DIGIT_PRELOAD = preload("res://scenes/instances/results/digit.tscn")

@export var number: int = 0:
	set(v):
		number = v
		update_display()

@export var spacing: float = 37.0:
	set(v):
		spacing = v
		update_display()

var instances: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	update_display()


func update_display():
	
	if number < 0: return
	
	var digits = str(number).length()
	
	for i in instances.size():
		
		instances[0].queue_free()
		instances.remove_at(0)
	
	for digit in digits:
		
		var digit_node_instance = DIGIT_PRELOAD.instantiate()
		
		digit_node_instance.position.x = spacing * digit
		digit_node_instance.digit = int(number / pow(10, digits - digit - 1)) % 10
		
		add_child(digit_node_instance)
		instances.append(digit_node_instance)
