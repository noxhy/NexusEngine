extends CanvasLayer
class_name BasicUI

@export_custom(PROPERTY_HINT_LINK, 'x') var target_zoom:Vector2 = Vector2.ONE

@export_group("Zoom Smoothing")
## If [code]true[/code], the camera's zoom smoothly zoom towards its target position at [member zoom_smoothing_speed].
@export_custom(PROPERTY_HINT_GROUP_ENABLE, '') var zoom_smoothing: bool = true
## The asymptotic speed of the camera's zoom smoothing effect when [member zoom_smoothing] is true.
@export_custom(PROPERTY_HINT_RANGE, '1, 64, suffix:weight') var zoom_smoothing_speed: float = 5

@onready var rating_marker: Node = $"Rating Marker"
@onready var combo_marker: Node = $"Combo Marker"

func _ready() -> void:
	if SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "downscroll"):
		downscroll_ui()
	apply_underlay()


func _process(delta: float) -> void:
	if zoom_smoothing:
		scale = Global.frame_independent_lerp(scale, target_zoom, zoom_smoothing_speed, delta)

func bump(strength: Vector2):
	scale += strength

func update_player(player: Character):
	pass

func update_enemy(enemy: Character):
	pass

func downscroll_ui():
	for strum_line in get_tree().get_nodes_in_group(&"strums"):
		strum_line.position.y *= -1
	
	$"Health Bar".position.y *= -1

func apply_underlay():
	var underlay: ColorRect = ColorRect.new()
	underlay.color = Color(0, 0, 0,
	SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "underlay_opacity"))
	underlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	underlay.position -= self.offset
	underlay.z_index = -1000
	
	add_child(underlay)
