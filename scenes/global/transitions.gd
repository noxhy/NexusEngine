extends Node2D

func _ready():
	
	$AnimationPlayer.play("RESET")

func transition(transition_name: String):
	
	$AnimationPlayer.play(transition_name)
	print("starting transition: ", $AnimationPlayer.assigned_animation)

func pause():
	
	if Global.transitioning:
		
		$AnimationPlayer.pause()
		print("holding transition: ", $AnimationPlayer.assigned_animation)

func resume():
	
	if !$AnimationPlayer.is_playing():
		
		$AnimationPlayer.play()
		print("continuing transition: ", $AnimationPlayer.assigned_animation)


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	$AnimationPlayer.play("RESET")
