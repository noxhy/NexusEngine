extends Node2D

@export var direction: int = 1
@export_range( 1, 4 ) var car: int = 1
@export var time: float = 2.0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$AnimatedSprite2D.play( "car" + str(car) )
	$AnimatedSprite2D.scale.x = direction / abs( direction )
	
	position.x *= direction / abs( direction )
	
	# This is janky don't do this
	var tween = create_tween()
	tween.set_trans( Tween.TRANS_LINEAR )
	
	if direction == 1:
		
		scale = Vector2( 1, 1 )
		position = Vector2( 168, 111 )
		
		tween.tween_property( self, "position", Vector2( 572, 86 ), time / 2.0 ).set_ease( Tween.EASE_IN )
		tween.set_parallel(true)
		tween.tween_property( self, "position", Vector2( 1406, 204 ), time / 2.0 ).set_ease( Tween.EASE_OUT )
		tween.tween_property( self, "rotation_degrees", 15, time / 2.0 ).set_ease( Tween.EASE_IN )
	
	if direction == -1:
		
		scale = Vector2( 0.8, 0.8 )
		position = Vector2( 1406, 204 )
		rotation_degrees = 20
		
		tween.set_parallel(true)
		tween.tween_property( self, "position", Vector2( 728, 120 ), time / 2.0 ).set_ease( Tween.EASE_IN )
		tween.tween_property( self, "rotation_degrees", 0, time ).set_ease( Tween.EASE_IN )
		tween.tween_property( self, "position", Vector2( 98, 111 ), time / 2.0 ).set_ease( Tween.EASE_IN ).set_delay( time / 2.0 )
	
	await tween.finished
	
	queue_free()
