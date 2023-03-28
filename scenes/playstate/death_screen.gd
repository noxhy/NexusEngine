extends Node2D

var can_press = true

# Called when the node enters the scene tree for the first time.
func _ready():
	
	Global.set_window_title("Dead")
	$AnimationPlayer.play( "intro" )
	
	%Player.position = Global.death_stats.player_position 
	$Camera2D.position = %Player.global_position + $UI.offset
	
	var tween = create_tween()
	tween.set_parallel( true )
	tween.set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_OUT )
	tween.tween_property( %Player, "scale", Global.death_stats.player_scale, 2 )
	tween.tween_property( $Camera2D, "zoom", Global.death_stats.camera_zoom, 2 )


func _on_conductor_new_beat(current_beat, measure_relative):
	
	if can_press:
		%Player.play_animation( "idle" )

func _input(event):
	
	if event.is_action_pressed( "ui_accept" ):
		
		if can_press:
			
			can_press = false
			%Player.play_animation( "accept" )
			$AnimationPlayer.play( "end" )


func exit_scene():
	
	Transitions.transition( "down fade in" )
	Global.change_scene_to( Global.song_scene )


func _on_animation_player_animation_finished(anim_name):
	pass
