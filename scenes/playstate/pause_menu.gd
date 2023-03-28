extends Node2D

@onready var menu_option_node = preload( "res://scenes/instances/menu_option.tscn" )
@onready var options_menu_node = preload( "res://scenes/instances/options/options_menu.tscn" )

var options: Dictionary = {
	
	"resume": {
		"option_name": "Resume",
		"icon": null,
	},
	
	"options": {
		"option_name": "Options",
		"icon": null,
	},
	
	"restart": {
		"option_name": "Restart Song",
		"icon": null,
	},
	
	"exit": {
		"option_name": "Exit to Menu",
		"icon": null,
	},
	
}

var option_nodes = []
var selected: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	
	var tween = create_tween()
	tween.tween_property( $Audio/Music, "volume_db", 0, 4 )
	$AnimationPlayer.play( "intro" )
	
	render_options()
	update_selection( selected )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	Global.set_window_title( "Paused" )
	
	if Input.is_action_just_pressed( "ui_up" ):
		
		selected -= 1
		update_selection( selected )
	elif Input.is_action_just_pressed( "ui_down" ):
		
		selected += 1
		update_selection( selected )
	
	if Input.is_action_just_pressed( "ui_cancel" ) || Input.is_action_just_pressed( "ui_accept" ):
		
		select_option( selected )


func render_options():
	
	var index = 0
	
	for i in options.keys():
		
		var menu_option_instance = menu_option_node.instantiate()
		
		menu_option_instance.position.x = -640 + 45 + ( 25 * index ) - 1000
		menu_option_instance.position.y = index * 175
		menu_option_instance.option_name = options.get( i ).option_name
		menu_option_instance.icon = options.get( i ).icon
		
		$UI.add_child( menu_option_instance )
		option_nodes.append( menu_option_instance )
		
		index += 1


func update_selection( i: int ):
	
	selected = wrapi( i, 0, options.keys().size())
	i = selected
	var index = -selected
	$"Audio/Menu Scroll".play()
	
	for j in option_nodes:
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var node_position = Vector2( -640 + 45 + ( 25 * index ), index * 175 ) 
		tween.tween_property( j, "position", node_position, 0.5 )
		j.modulate = Color( 0.5, 0.5, 0.5 )
		
		index += 1
	
	option_nodes[i].modulate = Color( 1, 1, 1 )
	


func select_option( i: int ):
	
	var option = options.keys()[i]
	
	if option == "resume":
		
		get_tree().paused = false
		queue_free()
	
	elif option == "options":
		
		get_tree().paused = false
		Global.change_scene_to( "res://scenes/options/options.tscn" )
	
	elif option == "restart":
		
		get_tree().paused = false
		Global.change_scene_to( Global.new_scene )
	
	elif option == "exit":
		
		get_tree().paused = false
		
		if Global.freeplay:
			
			Global.change_scene_to( "res://scenes/freeplay/freeplay.tscn" )
		else:
			
			Global.change_scene_to( "res://scenes/story mode/story_mode.tscn" )
