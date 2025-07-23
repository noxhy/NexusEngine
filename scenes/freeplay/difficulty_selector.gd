extends CanvasLayer

signal selected_difficulty(difficulty: String)

@export var difficulties: Array[String] = []
@export var can_press: bool = false

var selected: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	await get_parent().ready
	
	update_selection(selected)
	$AnimationPlayer.play("start")


func _process(_delta: float) -> void:
	
	if can_press:
		
		if Input.is_action_just_pressed("ui_left"):
			update_selection(selected - 1)
		
		if Input.is_action_just_pressed("ui_right"):
			update_selection(selected + 1)


func update_selection(i: int):
	
	selected = wrapi(i, 0, difficulties.size())
	i = selected
	var difficulty = difficulties[i]
	
	%"Difficulty Display".play_animation(difficulties[i])
	
	var tween = create_tween()
	%"Difficulty Display".scale = Vector2( 1.1, 1.1 )
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property( %"Difficulty Display", "scale", Vector2( 1, 1 ), 0.2 )
	
	%Scroll.play()
	emit_signal("selected_difficulty", difficulty)
