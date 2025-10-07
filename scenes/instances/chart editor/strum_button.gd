extends HFlowContainer

signal move_bound_left(strum_id: String)
signal move_bound_right(strum_id: String)
signal updated
signal opened
signal closed

@export var id: String
@export var muted: bool
@export var track: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_window_about_to_popup()


func _on_button_pressed() -> void:
	
	$Window.popup()


func _on_save_button_pressed() -> void:
	
	var temp_i = ChartManager.strum_data.keys().find(id)
	var temp: String = %"Strum ID".text
	var input: Dictionary = ChartManager.strum_data[id]
	ChartManager.strum_data.erase(id)
	var temp_dict: Dictionary = ChartManager.strum_data
	ChartManager.strum_data = {}
	
	var offset: int = 0
	for i in range(ChartManager.strum_data.size() + 2):
		
		
		if i == temp_i:
			
			ChartManager.strum_data[temp] = input
			offset = 1
		else:
			
			var key = temp_dict.keys()[i - offset]
			ChartManager.strum_data.merge({key: temp_dict[key]})
	
	id = temp
	
	muted = $"Window/VBoxContainer/HBoxContainer4/Check Box".button_pressed
	ChartManager.strum_data[id]["muted"] = muted
	track = %"Vocal Track".value
	ChartManager.strum_data[id]["track"] = track
	
	$Window.hide()
	emit_signal("updated")


func _on_window_close_requested() -> void:
	
	$Window.hide()
	emit_signal("closed")


func _on_move_lane_left_pressed() -> void: emit_signal("move_bound_left", id)
func _on_move_lane_right_pressed() -> void: emit_signal("move_bound_right", id)


func _on_window_about_to_popup() -> void:
	
	$Button.text = id
	%"Vocal Track".min_value = 0
	if ChartManager.song != null:
		%"Vocal Track".max_value = ChartManager.song.vocals.size() - 1
	%"Vocal Track".value = ChartManager.strum_data[id]["track"]
	%"Strum ID".text = id
	$"Window/VBoxContainer/HBoxContainer4/Check Box".button_pressed = muted
	emit_signal("opened")
