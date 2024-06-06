@icon( "res://assets/sprites/nodes/stage.png" )

extends Stage

@onready var car_preload = preload( "res://scenes/instances/stages/4chan_philly/car.tscn" )

var total_bops: int = 0
var red_light: bool = true

var car_list: Array[ Node2D ] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var index = 0
	
	# This is janky don't do this
	for car in car_list:
		
		if car == null:
			
			car_list.remove_at(index)
			index -= 1
			continue
		
		index += 1


func bop( allow_slow: bool = false ):
	
	super( allow_slow )
	
	if ( total_bops % 32 == 0 ):
		
		red_light = !red_light
		
		var animation = "greentored" if red_light else "redtogreen"
		%"Traffic Light".play( animation, -1, true )
	
	if ( total_bops % 4 == 0 ):
		
		if !red_light:
			
			if car_list.size() < 2:
				
				print( "car spawned" )
				var car_instance = car_preload.instantiate()
				
				var rng = randi_range( 1, 2 )
				car_instance.direction = 1 if rng == 1 else -1
				
				%"Cars Layer".add_child( car_instance )
				car_list.append( car_instance )
	
	total_bops += 1
