extends AnimatedSprite2D
class_name OffsetSprite

## Each key is the animation id and the value is the real animation name in the [code]SpriteFrames[/code]
@export var animation_names: Dictionary[StringName, StringName] = {}
## Each key is the animation name in the [code]SpriteFrames[/code] and the value is the offset
@export var offsets: Dictionary[StringName, Vector2] = {}
## The current animation ID being played.
var current_animation: StringName

func play_animation(animation_id: StringName, forced: bool = true):
	var animation_name = get_animation_name(animation_id)
	
	if animation_names.has(animation_id):
		if not forced and animation == animation_name:
			return
		
		play(animation_name)
		current_animation = animation_id
		offset = offsets.get(animation_name, Vector2.ZERO)

## Returns the animation name of the given id in SpriteFrames.
func get_animation_name(animation_id: StringName) -> Variant:
	return animation_names.get(animation_id)
