extends CanvasLayer

signal selected_difficulty( difficulty: String )

@export var difficulties: Array = []
@export var can_press: bool = false

var selected: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	update_selection(selected)
	$AnimationPlayer.play("start")


func _process(delta: float) -> void:
	
	if can_press:
		
		if Input.is_action_just_pressed("ui_left"): update_selection( selected - 1 )
		
		elif Input.is_action_just_pressed("ui_right"): update_selection( selected + 1 )
		
		elif Input.is_action_just_pressed("ui_accept"): select_option(selected)
		
		elif Input.is_action_just_pressed("ui_cancel"):
			
			get_tree().paused = false
			emit_signal( "selected_difficulty", "null" )


func update_selection( i: int ):
	
	selected = wrapi( i, 0, difficulties.size() )
	i = selected
	
	%"Difficulty Display".play_animation( difficulties[i] )
	
	var tween = create_tween()
	%"Difficulty Display".scale = Vector2( 1.1, 1.1 )
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property( %"Difficulty Display", "scale", Vector2( 1, 1 ), 0.2 )
	
	%Scroll.play()


func select_option( i: int ):
	
	var difficulty = difficulties[i]
	
	get_tree().paused = false
	emit_signal( "selected_difficulty", difficulty )
