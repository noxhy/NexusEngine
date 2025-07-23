extends CanvasLayer

const SEPARATOR_PRELOAD = preload("res://scenes/instances/freeplay/separator.tscn")
const DIFFICULTY_COLORS = {
	
	"erect": [Color(0.761, 0.541, 1.0), Color(0.204, 0.161, 0.416), Color(0.204, 0.161, 0.416, 0.5)],
	"nightmare": [Color(0.761, 0.541, 1.0), Color(0.204, 0.161, 0.416), Color(0.204, 0.161, 0.416, 0.5)]
	
}

signal selected_difficulty(difficulty: String)

@export var difficulties: Array[String] = []
@export var can_press: bool = false
@export var available_difficulties: Array[String]:
	set(v):
		available_difficulties = v
		update_separators()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	await get_parent().ready
	
	update_selection(Global.freeplay_difficulty)
	$AnimationPlayer.play("start")
	
	await $AnimationPlayer.animation_finished
	
	var i: int = 0
	for difficulty in difficulties:
		
		var separator_instance = SEPARATOR_PRELOAD.instantiate()
		
		if DIFFICULTY_COLORS.has(difficulty):
			
			separator_instance.active_color = DIFFICULTY_COLORS[difficulty][0]
			separator_instance.inactive_color = DIFFICULTY_COLORS[difficulty][1]
			separator_instance.disabled_color = DIFFICULTY_COLORS[difficulty][2]
		separator_instance.position = Vector2(32 * (i - (difficulties.size() / 2)), 64)
		separator_instance.scale = Vector2(1.2, 1.2)
		separator_instance.difficulty = difficulty
		
		self.add_child(separator_instance)
		separator_instance.add_to_group("separators")
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(separator_instance, "scale", Vector2(1, 1), 0.2)
	
		i += 1


func _process(_delta: float) -> void:
	
	if can_press:
		
		if Input.is_action_just_pressed("ui_left"):
			update_selection(Global.freeplay_difficulty - 1)
		
		if Input.is_action_just_pressed("ui_right"):
			update_selection(Global.freeplay_difficulty + 1)


func update_selection(i: int):
	
	Global.freeplay_difficulty = wrapi(i, 0, difficulties.size())
	i = Global.freeplay_difficulty
	var difficulty = difficulties[i]
	
	%"Difficulty Display".play_animation(difficulties[i])
	
	var tween = create_tween()
	%"Difficulty Display".scale = Vector2(1.1, 1.1)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(%"Difficulty Display", "scale", Vector2(1, 1), 0.2)
	
	%Scroll.play()
	
	emit_signal("selected_difficulty", difficulty)


func update_separators():
	
	var difficulty = difficulties[Global.freeplay_difficulty]
	
	for node in get_tree().get_nodes_in_group("separators"):
		
		if available_difficulties.has(node.difficulty):
			
			if node.difficulty == difficulty:
				node.state = 1
			else:
				node.state = 0
		else:
			node.state = 2
