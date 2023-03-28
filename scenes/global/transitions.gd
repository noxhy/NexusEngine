extends Node2D

func _ready():
	
	$Transitions/AnimationPlayer.play("RESET")

func transition(transition_name: String):
	
	$Transitions/AnimationPlayer.play(transition_name)
