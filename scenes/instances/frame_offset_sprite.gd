extends AnimatedSprite2D
class_name FrameOffsetSprite

@export var animation_names = { "default": "default", }
@export var offsets = { "default": [ Vector2( 0, 0 ) ], }


func play_animation(animation_name: String = ""):
	
	if animation_names.has(animation_name):
		
		var real_animation_name: String = animation_names.get( animation_name )
		
		play( real_animation_name )
		
		if offsets.has( real_animation_name ):
			
			offset = offsets.get( real_animation_name )[0]


func get_real_animation(animation_name: String = ""):
	
	if animation_names.has( animation_name ):
		
		var real_animation_name: String = animation_names.get( animation_name )
		return real_animation_name
	else:
		
		return null


func _on_frame_changed():
	
	if offsets.has( animation ):
		
		var offset_list: PackedVector2Array = offsets.get( animation )
		offset = offset_list[frame]
