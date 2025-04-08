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
	
	var temp_i = ChartHandeler.strum_data.keys().find(id)
	var temp: String = %"Strum ID".text
	var input: Dictionary = ChartHandeler.strum_data[id]
	ChartHandeler.strum_data.erase(id)
	var temp_dict: Dictionary = ChartHandeler.strum_data
	ChartHandeler.strum_data = {}
	
	var offset: int = 0
	for i in range(ChartHandeler.strum_data.size() + 2):
		
		
		if i == temp_i:
			
			ChartHandeler.strum_data[temp] = input
			offset = 1
		else:
			
			var key = temp_dict.keys()[i - offset]
			ChartHandeler.strum_data.merge({key: temp_dict[key]})
	
	id = temp
	
	muted = $"Window/VBoxContainer/HBoxContainer4/Check Box".button_pressed
	ChartHandeler.strum_data[id]["muted"] = muted
	track = %"Vocal Track".value
	ChartHandeler.strum_data[id]["track"] = track
	
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
	%"Vocal Track".max_value = ChartHandeler.song.vocals.size() - 1
	%"Vocal Track".value = ChartHandeler.strum_data[id]["track"]
	%"Strum ID".text = id
	$"Window/VBoxContainer/HBoxContainer4/Check Box".button_pressed = muted
	emit_signal("opened")
