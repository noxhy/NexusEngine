extends Node2D

signal waiting

func _ready():
	
	$AnimationPlayer.play("RESET")

func transition(transition_name: String):
	
	$AnimationPlayer.play(transition_name)
	$AnimationPlayer.seek(0)
	print("starting transition: ", $AnimationPlayer.assigned_animation)

func pause():
	
	if Global.transitioning:
		
		$AnimationPlayer.pause()
		print("holding transition: ", $AnimationPlayer.assigned_animation)
		self.waiting.emit()

func resume():
	
	if !$AnimationPlayer.is_playing():
		
		$AnimationPlayer.play()
		print("continuing transition: ", $AnimationPlayer.assigned_animation)


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	$AnimationPlayer.play("RESET")
