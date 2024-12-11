extends Node2D

@export var can_click: bool = true

@onready var week_icon_node = preload( "res://scenes/instances/story mode/week_icon.tscn" )

@onready var options: Dictionary = {
	
	"tutorial": {
		"animation_name": "tutorial",
		"display_node": $"UI/Week Display/SubViewport/Tutorial",
		"scene": "res://test/test_scene.tscn",
		"week_name": "Teaching Time",
		"song_list": "Tutorial",
		"difficulties": ["easy"],
	},
	"week1": {
		"animation_name": "week1",
		"display_node": $"UI/Week Display/SubViewport/Week 1",
		"scene": "res://scenes/playstate/songs/fresh/fresh.tscn",
		"week_name": "Daddy Dearest",
		"song_list": "Bopeeboo\nFresh\nDadbattle",
		"difficulties": ["nightmare"],
	},
	"week2": {
		"animation_name": "week2",
		"display_node": $"UI/Week Display/SubViewport/Week 2",
		"scene": "res://test/test_scene.tscn",
		"week_name": "Spooky Month",
		"song_list": "Spokeez\nSouth\nMonster",
		"difficulties": ["easy"],
	},
	"week3": {
		"animation_name": "week3",
		"display_node": $"UI/Week Display/SubViewport/Week 3",
		"scene": "res://test/test_scene.tscn",
		"week_name": "Pico",
		"song_list": "Pico\nPhilly\nBlammed",
		"difficulties": ["easy"],
	},
	"week4": {
		"animation_name": "week4",
		"display_node": $"UI/Week Display/SubViewport/Week 4",
		"scene": "res://test/test_scene.tscn",
		"week_name": "Mommy Must Murder",
		"song_list": "Satin-Panties\nHigh\nMilf",
		"difficulties": ["easy"],
	},
	"week5": {
		"animation_name": "week5",
		"display_node": $"UI/Week Display/SubViewport/Week 5",
		"scene": "res://test/test_scene.tscn",
		"week_name": "Red Snow",
		"song_list": "Cocoa\nEggnog\nWinter Horroland",
		"difficulties": ["easy"],
	},
	"week6": {
		"animation_name": "week6",
		"display_node": $"UI/Week Display/SubViewport/Week 6",
		"scene": "res://scenes/playstate/songs/senpai/senpai.tscn",
		"week_name": "Hating Simulator Ft. Moawling",
		"song_list": "Senpai\nRoses\nThorns",
		"difficulties": ["nightmare"],
	},
	"week7": {
		"animation_name": "week7",
		"display_node": $"UI/Week Display/SubViewport/Week 7",
		"scene": "res://test/test_scene.tscn",
		"week_name": "Tankman",
		"song_list": "Ugh\nGuns\nStress",
		"difficulties": ["easy"],
	},
	"weekend1": {
		"animation_name": "weekend1",
		"display_node": $"UI/Week Display/SubViewport/Weekend 1",
		"scene": "res://scenes/playstate/songs/darnell/darnell.tscn",
		"week_name": "Due Debts",
		"song_list": "Darnell\nLit Up\n2Hot\nBlazin\'",
		"difficulties": ["hard"],
	},
}

var option_nodes = []
var selected_week: int = 0
var selected_difficulty: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	Global.set_window_title( "Story Mode Menu" )
	
	if Global.song_playing():
		
		$Audio/Music.play( Global.get_song_position() )
	else:
		
		Global.play_song($Audio/Music.stream.resource_path)
		$Audio/Music.play()
	
	# Initalization
	
	var object_amount: int = 0
	
	for i in options:
		
		var week_icon_instance = week_icon_node.instantiate()
		
		week_icon_instance.position = Vector2( 1280 / 2, 1000 )
		
		$"UI/Week UI/SubViewport".add_child( week_icon_instance )
		week_icon_instance.play_animation( options.get( options.keys()[object_amount] ).animation_name )
		
		object_amount += 1
		option_nodes.append( week_icon_instance )
	
	update_week_selection( selected_week )


# Input Handler
func _input(event):
	
	if can_click:
		
		if event.is_action_pressed("ui_up"):
			
			update_week_selection( selected_week - 1 )
		elif event.is_action_pressed("ui_down"):
			
			update_week_selection( selected_week + 1 )
		elif event.is_action_pressed("ui_left"):
			
			update_difficulty_selection( selected_difficulty - 1 )
		elif event.is_action_pressed("ui_right"):
			
			update_difficulty_selection( selected_difficulty + 1 )
		elif event.is_action_pressed("ui_accept"):
			
			select_option(selected_week)
		elif event.is_action_pressed("ui_cancel"):
			
			can_click = false
			
			$"Audio/Menu Cancel".play()
			Transitions.transition("down")
			
			await get_tree().create_timer(1).timeout
			
			Global.change_scene_to("res://scenes/main menu/main_menu.tscn")


# Updates visually what happens when a new index is set for a selection
func update_week_selection( i: int ):
	
	selected_week = wrapi( i, 0, option_nodes.size() )
	i = selected_week
	var index = -selected_week
	$"Audio/Menu Scroll".play()
	
	for j in option_nodes:
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var node_position = Vector2( 1280 / 2, index * 135 + 64 )
		tween.tween_property( j, "position", node_position, 0.5 )
		
		j.modulate = Color( 0.5, 0.5, 0.5 )
		
		index += 1
	
	for j in $"UI/Week Display/SubViewport".get_children(): j.visible = false
	var display_node = options.get( options.keys()[i] ).display_node
	var difficulties = options.get( options.keys()[i] ).difficulties
	display_node.visible = true
	Global.bop_tween( display_node, "scale", display_node.scale, display_node.scale * Vector2(1.05, 1.05), 0.2, Tween.TRANS_SINE )
	GameHandeler.difficulty = difficulties[selected_difficulty]
	
	$"UI/Week UI/SubViewport/Song List Label".text = options.get( options.keys()[i] ).song_list
	$"UI/Week Name".text = options.get( options.keys()[i] ).week_name
	option_nodes[i].modulate = Color( 1, 1, 1 )
	update_difficulty_selection(selected_difficulty)


func update_difficulty_selection( i: int ):
	
	var difficulties = options.get( options.keys()[selected_week] ).difficulties
	
	selected_difficulty = wrapi( i, 0, difficulties.size() )
	i = selected_difficulty
	
	%"Difficulty Display".play_animation( difficulties[i] )
	
	var tween = create_tween()
	%"Difficulty Display".scale = Vector2( 1.1, 1.1 )
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property( %"Difficulty Display", "scale", Vector2( 1, 1 ), 0.2 )
	
	$"Audio/Menu Scroll".play()


# Called when an option was selected_week
func select_option( i: int ):
	
	if can_click:
		
		can_click = false
		$"Audio/Menu Confirm".play()
		
		$"Screen Flash".visible = true
		var tween = create_tween()
		tween.tween_property( $"Screen Flash/ColorRect", "color", Color( 1, 1, 1, 0 ), 0.2 )
		Transitions.transition("down")
		
		await get_tree().create_timer(1).timeout
		
		Global.stop_song()
		var scene = options.get( options.keys()[i] ).scene
		GameHandeler.freeplay = false
		Global.change_scene_to(scene)


func _on_conductor_new_beat(current_beat, measure_relative):
	
	if can_click:
		
		if SettingsHandeler.get_setting("ui_bops"):
			
			Global.bop_tween( $Camera2D, "zoom", Vector2( 1, 1 ), Vector2( 1.005, 1.005 ), 0.2, Tween.TRANS_CUBIC )
		
		var display_node = options.get( options.keys()[selected_week] ).display_node
		
		if ( current_beat % 2 ):
			
			for i in display_node.get_children():
				
				if i.is_in_group( "bop" ):
					
					i.play_animation( "idle" )
				
				elif i.is_in_group( "tween_bop" ):
					
					i.can_idle = true
					i.play_animation( "idle", $Conductor.seconds_per_beat * 2 )
