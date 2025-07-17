extends Node2D

var digit: int:
	set(v):
		digit = v
		var animation: String = str(digit, " small")
		if $AnimatedSprite2D.sprite_frames.has_animation(animation):
			$AnimatedSprite2D.play(animation)
