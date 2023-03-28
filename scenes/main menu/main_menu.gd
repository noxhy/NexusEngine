extends Node2D

@export var can_press: bool = true

@onready var options: Dictionary = {
	
	"story_mode": {
		"node": $"UI/Button Manager/Story Mode",
		"scene": "res://scenes/story mode/story_mode.tscn",
		"stop_music": false,
	},
	"freeplay": {
		"node": $"UI/Button Manager/Freeplay",
		"scene": "res://scenes/freeplay/freeplay.tscn",
		"stop_music": true,
	},
	"credits": {
		"node": $"UI/Button Manager/Credits",
		"scene": "res://scenes/credits/credits.tscn",
		"stop_music": false,
	},
	"options": {
		"node": $"UI/Button Manager/Options",
		"scene": "res://scenes/options/options.tscn",
		"stop_music": false,
	},
	
}
var selected: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	Transitions.transition("down fade out")
	Global.set_window_title( "Main Menu" )
	Global.song_scene = null
	
	if Global.song_playing():
		
		$Audio/Music.play( Global.get_song_position() )
	else:
		
		Global.play_song($Audio/Music.stream.resource_path)
		$Audio/Music.play()
	
	# Button Positions
	
	var i = 0
	var button_count = $"UI/Button Manager".get_children().size()
	
	for button in $"UI/Button Manager".get_children():
		
		button.position.y = ( 720.0 / ( button_count ) ) * i
		button.play( button.animation )
		i += 1
	
	# Initalization
	
	update_selection( selected )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Input Handler
func _input(event):
	
	if can_press:
		
		if event.is_action_pressed("ui_up"):
			
			update_selection( selected - 1 )
		elif event.is_action_pressed("ui_down"):
			
			update_selection( selected + 1 )
		elif event.is_action_pressed("ui_accept"):
			
			select_option(selected)
		elif event.is_action_pressed("ui_cancel"):
			
			Transitions.transition("down fade in")
			can_press = false
			
			await get_tree().create_timer(1).timeout
			
			Global.change_scene_to("res://scenes/start menu/start_menu.tscn")


# Updates visually what happens when a new index is set for a selection
func update_selection(i: int):
	
	var old_node = ( options.get( options.keys()[selected] ) ).node
	old_node.play_animation("idle")
	
	var old_node_tween = create_tween()
	old_node_tween.tween_property( old_node, "scale", old_node.scale - Vector2(0.1, 0.1), 0.2 ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	selected = wrapi( i, 0, options.keys().size())
	$"Audio/Menu Scroll".play()
	
	var new_node = ( options.get( options.keys()[selected] ) ).node
	new_node.play_animation("selected")
	
	var camera_tween = create_tween()
	camera_tween.tween_property( $Camera2D, "position", new_node.position, 0.2 ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var new_node_tween = create_tween()
	new_node_tween.tween_property( new_node, "scale", new_node.scale + Vector2(0.1, 0.1), 0.2 ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Called when an option was selected
func select_option(i: int):
	
	var node = ( options.get( options.keys()[i] ) ).node
	$"Audio/Menu Confirm".play()
	$Background/Background.play("selected")
	
	can_press = false
	
	var camera_tween = create_tween()
	camera_tween.tween_property( $Camera2D, "zoom", Vector2(1.2, 1.2), 0.5 ).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	for n in options.keys():
		
		var temp_node = options.get( n ).node
		
		if n != options.keys()[i]:
			
			var node_tween = create_tween()
			node_tween.tween_property( temp_node, "scale", Vector2(0, 0), 0.2 ).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	var stop_music = ( options.get( options.keys()[i] ) ).stop_music
	
	if stop_music:
		
		Global.stop_song()
	
	await get_tree().create_timer(1).timeout
	
	Transitions.transition("down fade in")
	var scene = ( options.get( options.keys()[i] ) ).scene
	Global.change_scene_to(scene)


func _on_conductor_new_beat(current_beat, measure_relative):
	
	if can_press:
		
		if SettingsHandeler.get_setting("ui_bops"):
			
			Global.bop_tween( $Camera2D, "zoom", Vector2( 1, 1 ), Vector2( 1.005, 1.005 ), 0.2, Tween.TRANS_CUBIC )
			Global.bop_tween( $Background/Background, "scale", Vector2( 1, 1 ), Vector2( 1.005, 1.005 ), 0.2, Tween.TRANS_CUBIC )
