extends HFlowContainer

signal move_bound_left(strum_id: int)
signal move_bound_right(strum_id: int)
signal updated
signal opened
signal closed

@export var id: int
@export var track: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_window_about_to_popup()
	$Window.add_to_group(&"windows")


func _on_button_pressed() -> void:
	$Window.popup()


func _on_save_button_pressed() -> void:
	ChartManager.strum_data[id]["name"] = %"Strum ID".text
	track = %"Vocal Track".value
	ChartManager.strum_data[id]["track"] = track
	
	$Window.hide()
	emit_signal("updated")


func _on_window_close_requested() -> void:
	$Window.hide()
	emit_signal("closed")


func _on_move_lane_left_pressed() -> void:
	emit_signal("move_bound_left", id)
func _on_move_lane_right_pressed() -> void:
	emit_signal("move_bound_right", id)


func _on_window_about_to_popup() -> void:
	$Button.text = ChartManager.strum_data[id].get("name", "")
	%"Vocal Track".min_value = 0
	if ChartManager.song != null:
		%"Vocal Track".max_value = ChartManager.song.vocals.size() - 1
	%"Vocal Track".value = ChartManager.strum_data[id]["track"]
	%"Strum ID".text = ChartManager.strum_data[id].get("name", "")
	emit_signal("opened")

func file_dailog_gui_focus_changed(node: Control) -> void:
	emit_signal(&"gui_focus_changed", node)
