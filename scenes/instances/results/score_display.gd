extends Node2D

const DIGIT_PRELOAD = preload("res://scenes/instances/results/score_digit.tscn")

signal finished

@export var digits: int = 10:
	set(v):
		digits = v
		update_display()

@export var tween_time: float = 2.0

@export var number: int = 0:
	set(v):
		number = v
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "_number", v, tween_time)
		actual_digits = str(number).length()
		update_display()
		
		await tween.finished
		emit_signal("finished")

@export var spacing: float = 37.0:
	set(v):
		spacing = v
		update_display()

var instances: Array = []
var actual_digits: int
var _number: int:
	set(v):
		_number = v
		update_display()

# Called when the node enters the scene tree for the first time.
func _ready():
	update_display()

func update_display():
	
	if instances.size() == 0:
		
		for digit in digits:
			
			var digit_node_instance = DIGIT_PRELOAD.instantiate()
			
			digit_node_instance.position.x = spacing * digit
			if ((digits - digit - 1) > actual_digits):
				digit_node_instance.digit = 0
			else:
				digit_node_instance.digit = -1
			
			add_child(digit_node_instance)
			instances.append(digit_node_instance)
	else:
		for digit in digits:
			instances[digit].position.x = spacing * digit
	
	for digit in digits:
		
		var target_digit = int(number / pow(10, digits - digit - 1)) % 10
		var actual_digit = int(_number / pow(10, digits - digit - 1)) % 10
		
		if !((digits - digit) > actual_digits):
			
			instances[digit].glowing = (target_digit == actual_digit)
			instances[digit].digit = actual_digit
		else:
			instances[digit].digit = -1
