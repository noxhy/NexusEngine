@icon("res://assets/sprites/nodes/stage.png")
extends Node2D
class_name Stage

@export var slow_boppers: PackedStringArray
@export var fast_boppers: PackedStringArray

var tempo: float = 60.0

# Using the group feature, you can put some behaviors in nodes
#
# parallax - Scales a CanvasLayer by follow_viewport_scale
# autoplay - Plays the current animation the AnimatedSprite2D is on
# tween - Sets the scale of an AnimatedSprite2D to last the duration of 2 seconds per beat

func _ready():
	
	for i in get_children():
		
		if i.is_in_group("parallax"):
			
			var vector = Vector2(i.follow_viewport_scale, i.follow_viewport_scale)
			i.scale = Vector2(1, 1) + (Vector2(1, 1) - vector)
		
		for j in i.get_children():
			
			if j.is_in_group("autoplay"):
				
				j.play(j.get_animation())
		
		if !(i is WorldEnvironment):
			
			i.scale *= self.scale
			i.rotation = self.rotation
			if !(i is Parallax2D): i.offset += self.position
			i.visible = self.visible

func bop(allow_slow: bool = false):
	
	if allow_slow:
		
		for i in slow_boppers:
			
			if get_node(i) is OffsetSprite:
				
				get_node(i).play_animation("idle")
				get_node(i).set_frame_and_progress(0, 0)
				
				if get_node(i).is_in_group("tween"):
					
					# Calculates the speed it would need to go at the time requested
					var time: float = (60 / tempo) * 2
					var real_animation_name: String = get_node(i).get_real_animation("idle")
					
					var animatiom_speed: float = get_node(i).sprite_frames.get_animation_speed(real_animation_name)
					var frame_count: int = get_node(i).sprite_frames.get_frame_count(real_animation_name) 
					
					get_node(i).speed_scale = frame_count / (animatiom_speed * time)
	
	for i in fast_boppers:
		
		if get_node(i) is OffsetSprite:
			
			get_node(i).play_animation("idle")
			get_node(i).set_frame_and_progress(0, 0)
