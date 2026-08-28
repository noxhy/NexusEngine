@tool
extends AnimatedSprite2D
class_name OffsetSprite2D

## Each key is the animation name in the [code]SpriteFrames[/code] and the value is the offset
@export var offsets: Dictionary[StringName, Vector2] = {}:
	set(v):
		offsets = v
		update_ghost()

@export_group("Ghost Settings")
@export var _ghost_behind_parent: bool = true:
	set(v):
		_ghost_behind_parent = v
		update_ghost()

@export var _ghost_animation: StringName = &"":
	set(v):
		_ghost_animation = v
		update_ghost()

## The current animation ID being played.
var current_animation: StringName

@export_category("Tools")
@warning_ignore("unused_private_class_variable")
@export_tool_button("Save Offset", "Save") var _save_button: Callable = self._save_offset
@warning_ignore("unused_private_class_variable")
@export_tool_button("Reset Position", "UndoRedo") var _reset_button: Callable = self._reset_position

var _ghost_sprite: Sprite2D

func _ready() -> void:
	if Engine.is_editor_hint():
		animation_changed.connect(update_ghost)
	else:
		animation_changed.connect(update_offset)

## Updates the offset to the corresponding [member animation]
func update_offset() -> void:
	offset = offsets.get(animation, Vector2.ZERO)

func _cleanup_ghost():
	if _ghost_sprite:
		remove_child(_ghost_sprite)
		_ghost_sprite.queue_free()

func _is_character_root():
	if not is_inside_tree():
		return false
	
	var tree = get_tree()
	return tree and tree.edited_scene_root == self

func _validate_property(property: Dictionary) -> void:
	match property.get("name"):
		"_ghost_animation":
			if !sprite_frames:
				return
			
			property.hint = PROPERTY_HINT_PLACEHOLDER_TEXT
			property.hint_string = "Name"
			
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ",".join(sprite_frames.get_animation_names())

func update_ghost():
	if !Engine.is_editor_hint() or not _is_character_root():
		return
	
	_cleanup_ghost()
	
	_ghost_sprite = Sprite2D.new()
	
	if sprite_frames:
		var animation_name: StringName = _ghost_animation
		_ghost_sprite.texture = sprite_frames.get_frame_texture(
			animation_name, sprite_frames.get_frame_count(animation_name) - 1) 
		_ghost_sprite.offset = offsets.get(animation_name, Vector2.ZERO)
	
	_ghost_sprite.modulate = Color(1.825, 1.825, 1.825, 0.5)
	_ghost_sprite.z_index = z_index
	_ghost_sprite.scale = scale
	_ghost_sprite.centered = centered
	_ghost_sprite.show_behind_parent = _ghost_behind_parent
	
	add_child(_ghost_sprite)


## [b]Tool Script[/b] - Used for offsetring.
## [br][br]Resets the current sprite back to the corresponding offset.
func _reset_position():
	if !Engine.is_editor_hint():
		return
	
	var undo_redo = __get_editor_undo_redo()
	undo_redo.create_action("Reset Position")
	undo_redo.add_do_property(self, &"offset", offsets.get(animation, Vector2.ZERO))
	undo_redo.add_undo_property(self, &"offset", offset)
	undo_redo.commit_action()

## [b]Tool Script[/b] - Used for offsetring.
## [br][br]Saves the offset into the [member offsets] dictionary.
func _save_offset():
	if !Engine.is_editor_hint():
		return
	
	var undo_redo = __get_editor_undo_redo()
	undo_redo.create_action("Save Offset")
	var temp: Dictionary[StringName, Vector2] = offsets.duplicate()
	temp[animation] = offset
	undo_redo.add_do_property(self, &"offsets", temp)
	undo_redo.add_undo_property(self, &"offsets", self.offsets)
	undo_redo.commit_action()

## helper function to get the editors undo and redo.
## only works in editor dont use this elsewhere
func __get_editor_undo_redo() -> Object:
	var ei: Object = Engine.get_singleton(&"EditorInterface")
	if not ei:
		return null
	var undo_redo: Object = ei.get_editor_undo_redo()
	return undo_redo
