extends Node2D

@export var can_click = true

@onready var menu_option_node = preload( "res://scenes/instances/menu_option.tscn" )


# Called when the node enters the scene tree for the first time.
func _ready():
	
	Global.set_window_title( "Options Menu" )
	
	$Foreground/Options.play("options white")
	
	if Global.song_playing():
		
		$Audio/Music.play( Global.get_song_position() )
	else:
		
		Global.play_song($Audio/Music.stream.resource_path)
		$Audio/Music.play()


# Input Manager
func _input(event):
	
	if event.is_action_pressed("ui_cancel"):
		
		
		can_click = false
		
		$"Audio/Menu Cancel".play()
		Transitions.transition("down")
		
		await get_tree().create_timer(1).timeout
		
		if Global.song_scene != null:
			
			Global.stop_song()
			Global.change_scene_to(Global.song_scene)
		else:
			
			Global.change_scene_to("res://scenes/main menu/main_menu.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_conductor_new_beat(current_beat, measure_relative):
	
	if SettingsManager.get_setting("ui_bops"):
		
		Global.bop_tween( $Background/Background, "scale", Vector2( 1, 1 ), Vector2( 1.005, 1.005 ), 0.2, Tween.TRANS_CUBIC )
