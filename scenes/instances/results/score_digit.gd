extends Node2D

@export var animation_names: Dictionary[int, String]
@export var glowing = false

var digit: int = -1:
	set(v):
		
		if (digit != v):
			
			digit = v
			var animation: String = animation_names.get(v, "GONE")
			if $AnimatedSprite2D.sprite_frames.has_animation(animation):
				
				if glowing:
					$AnimatedSprite2D.play(animation)
				else:
					$AnimatedSprite2D.play(animation)
					var frames = $AnimatedSprite2D.sprite_frames.get_frame_count($AnimatedSprite2D.animation)
					$AnimatedSprite2D.set_frame_and_progress(frames, 0)
			else:
				printerr(animation, "is not in the animation dictionary.")
