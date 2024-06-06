@icon("res://assets/sprites/nodes/character.png")

extends Character

@onready var spectrum = AudioServer.get_bus_effect_instance(1, 0)
@export var visualizer_nodes: Array[AnimatedSprite2D] = []
@export var music_host: AudioStreamPlayer

@export var definition = 7
@export var accel = 5
@export var slope = 0.3

@export var update_rate = 0.25

var minFrequency = 20.0
var maxFrequency = 20000.0

@export var min_db = -55
@export var max_db = 0

var update_timer: float

func _ready():
	
	super()
	update_timer = update_rate


func _process(delta):
	
	var frequency = minFrequency
	var interval = (maxFrequency - minFrequency) / definition
	
	update_timer -= delta
	if ( update_timer <= 0 ): update_timer = update_rate
	
	for i in range(definition):
		
		var frequencyRangeLow = float(frequency - minFrequency) / float(maxFrequency - minFrequency)
		frequencyRangeLow = pow(frequencyRangeLow, 4)
		frequencyRangeLow = lerp(minFrequency, maxFrequency, frequencyRangeLow)
		
		frequency += interval
		
		var frequencyRangeHigh = float(frequency - minFrequency) / float(maxFrequency - minFrequency)
		frequencyRangeHigh *= pow(frequencyRangeHigh, 4)
		frequencyRangeHigh = lerp(minFrequency, maxFrequency, frequencyRangeHigh)
		
		
		var mag = spectrum.get_magnitude_for_frequency_range(frequencyRangeLow, frequencyRangeHigh)
		mag = linear_to_db( mag.length() )
		mag = (mag - min_db) / (max_db - min_db * 1.0)
		
		mag += slope * ( frequency - minFrequency ) / ( maxFrequency - minFrequency )
		mag = clamp(mag, 0.01, 1.0) * 7.0
		
		if ( update_timer == update_rate ):
			visualizer_nodes[i].frame = 7 - mag
