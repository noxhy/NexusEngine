@tool
extends Marker2D
class_name NoahMarker2D

@export var _bounds_colour: Color = Color.RED
@export var _bounds_visible: bool = true 

var window_size: Vector2
var _draw_helper: Node2D

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		if _draw_helper:
			_draw_helper.queue_free()

func _gen_camera_view():
	window_size = Vector2(
		ProjectSettings.get_setting_with_override(&"display/window/size/viewport_width"),
		ProjectSettings.get_setting_with_override(&"display/window/size/viewport_height")
	)
	if not is_inside_tree():
		return
	
	_draw_helper = Node2D.new()
	_draw_helper.z_index = 4096
	_draw_helper.top_level = true
	_draw_helper.draw.connect(_draw_camera_view)
	get_tree().edited_scene_root.add_child.call_deferred(_draw_helper)
	
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if _draw_helper:
			_draw_helper.queue_redraw()
		else:
			_gen_camera_view()
			

var _camera2d_ref: Camera2D
func _find_camera_2d(parent: Node):
	if _camera2d_ref:
		return
		
	for child in parent.get_children():
		if _camera2d_ref:
			break
		
		if child is Camera2D:
			_camera2d_ref = child
		
		_find_camera_2d(child)

func _draw_camera_view() -> void:
	if Engine.is_editor_hint() and _bounds_visible and visible:
		
		_find_camera_2d(get_tree().edited_scene_root)
		if not _camera2d_ref:
			return
		
		var rect := Rect2(global_position.x - _camera2d_ref.position.x * 0.5, \
			global_position.y - _camera2d_ref.position.y * 0.5, \
			window_size.x / _camera2d_ref.zoom.x, \
			window_size.y / _camera2d_ref.zoom.y)
		
		_draw_helper.draw_set_transform(global_position, global_rotation)
		_draw_helper.draw_rect(Rect2(-rect.size / 2, rect.size), _bounds_colour, false, 3)
