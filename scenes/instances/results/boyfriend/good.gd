extends Node2D


func _on_animated_sprite_2d_animation_finished() -> void:
	$AnimatedSprite2D.play("loop")
