extends Node2D

@export var input: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if Input.is_action_pressed(input):
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property( $OffsetSprite, "scale", Vector2( 0.9, 0.9 ), 0.2 )
	
	if Input.is_action_just_released(input):
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property( $OffsetSprite, "scale", Vector2( 1, 1 ), 0.2 )
