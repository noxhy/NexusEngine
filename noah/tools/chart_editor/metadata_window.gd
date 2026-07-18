extends Window

signal updated_song_name(text: String)
signal updated_song_artist(text: String)
signal updated_song_charter(text: String)
signal updated_icon_texture(path: String)
signal updated_starting_tempo(tempo: float)
signal updated_song_scene(path: String)
signal updated_scroll_speed(speed: float)
signal selected_time_change(time: float)
signal add_time_change
signal remove_time_change

var scroll_speed: float
var has_updated_scroll_speed: bool = false
var current_time_change: int = -1

func update_stats():
	%"Song Name".text = ChartManager.song.title
	%"Song Artist".text = ChartManager.song.artist
	%"Song Charter".text = ChartManager.song.charter
	
	var path: String = ""
	
	if ChartManager.song.icons:
		path = ChartManager.song.icons.resource_path
	
	_on_icon_file_dailog_file_selected(path)
	_on_scene_file_dailog_file_selected(ChartManager.song.scene)
	
	%Difficulty.text = ChartManager.difficulty
	if has_updated_scroll_speed:
		%"Scroll Speed".value = ChartManager.chart.scroll_speed
	else:
		%"Scroll Speed".set_value_no_signal(ChartManager.chart.scroll_speed)
		%"Scroll Speed Label".text = str("Scroll Speed: ", ChartManager.chart.scroll_speed, "x")
	
	%"Time Changes".clear()
	var chart: Chart = ChartManager.chart
	var i: int = 0
	for time in chart.get_tempos_data():
		%"Time Changes".add_item(format_time_change(i))
		i += 1
	_on_time_changes_item_selected(0, false)

func _on_icon_file_dailog_file_selected(path: String) -> void:
	path = ResourceUID.path_to_uid(path)
	if !ResourceLoader.exists(path):
		printerr("Icon file doesn't exist.")
		return
	
	var sprite_frames = load(path)
	if sprite_frames is not SpriteFrames:
		printerr("Icon file is not a SpriteFrames")
		return
	
	if not sprite_frames.has_animation('default'):
		printerr("Icon file is missing a default animation")
		return
	var texture: Texture = sprite_frames.get_frame_texture("default", 0)
	%Icon.texture = texture
	$HBoxContainer/VBoxContainer/Icons/LineEdit.text = path
	updated_icon_texture.emit(path)

func _on_icon_button_pressed() -> void:
	%"Icon FileDailog".popup()

func _on_scene_file_dailog_file_selected(path: String) -> void:
	path = ResourceUID.path_to_uid(path)
	if !ResourceLoader.exists(path):
		printerr("Scene doesn't exist.")
		return
	
	%"Song Scene".text = path
	updated_song_scene.emit(path)

func _on_starting_tempo_value_changed(value: float) -> void:
	%"Tempo".value = value
	updated_starting_tempo.emit(value)

func _on_song_name_text_changed(new_text: String) -> void:
	updated_song_name.emit(new_text)

func _on_song_artist_text_changed(new_text: String) -> void:
	updated_song_artist.emit(new_text)

func _on_close_requested() -> void:
	self.visible = false
	gui_release_focus()

func _on_song_scene_button_pressed() -> void:
	%"Scene FileDailog".popup()

func file_dailog_gui_focus_changed(node: Control) -> void:
	emit_signal(&"gui_focus_changed", node)

func _on_scroll_speed_value_changed(value: float) -> void:
	%"Scroll Speed Label".text = str("Scroll Speed: ", value, "x")
	emit_signal(&"updated_scroll_speed", value)

func _on_time_changes_item_selected(index: int, emit: bool = true) -> void:
	%"Remove Time Change".disabled = (index == 0)
	current_time_change = index
	
	var tempo_data: Dictionary = ChartManager.chart.get_tempos_data()
	var time: float = tempo_data.keys()[index]
	%Tempo.value = tempo_data.get(time, 60)
	var meter_data: Dictionary = ChartManager.chart.get_meters_data()
	var meter: Array = meter_data.get(meter_data.keys()[min(index, meter_data.size() - 1)])
	%Numerator.value = meter[0]
	%Denominator.value = meter[1]
	if emit:
		emit_signal(&"selected_time_change", time)

func _on_add_time_change_pressed() -> void:
	emit_signal(&"add_time_change")

func _on_remove_time_change_pressed() -> void:
	var tempo_data: Dictionary = ChartManager.chart.get_tempos_data()
	var time: float = tempo_data.keys()[current_time_change]
	
	ChartManager.chart.chart_data["tempos"].erase(time)
	ChartManager.chart.chart_data["meters"].erase(time)
	%"Time Changes".remove_item(current_time_change)
	%"Time Changes".select(current_time_change - 1)
	_on_time_changes_item_selected(current_time_change - 1)
	
	emit_signal(&"remove_time_change")

func _on_tempo_value_changed(value: float) -> void:
	var tempo_data: Dictionary = ChartManager.chart.get_tempos_data()
	var time: float = tempo_data.keys()[current_time_change]
	
	ChartManager.song.tempo = tempo_data.get(0.0)
	ChartManager.chart.chart_data["tempos"][time] = value
	%"Time Changes".set_item_text(current_time_change, format_time_change(current_time_change))

func format_time_change(index: int) -> String:
	var tempo_data: Dictionary = ChartManager.chart.get_tempos_data()
	var meter_data: Dictionary = ChartManager.chart.get_meters_data()
	var time: float = tempo_data.keys()[index]
	var meter: Array = meter_data.get(meter_data.keys()[min(index, meter_data.size() - 1)])
	return str(Global.format_time(time), " - BPM: ", tempo_data[time], " in ", meter[0], "/", meter[1])

func _on_numerator_value_changed(value: float) -> void:
	var tempo_data: Dictionary = ChartManager.chart.get_tempos_data()
	var time: float = tempo_data.keys()[current_time_change]
	
	ChartManager.chart.chart_data["meters"][time] = [int(value), int(%Denominator.value)]
	%"Time Changes".set_item_text(current_time_change, format_time_change(current_time_change))

func _on_denominator_value_changed(value: float) -> void:
	var tempo_data: Dictionary = ChartManager.chart.get_tempos_data()
	var time: float = tempo_data.keys()[current_time_change]
	
	ChartManager.chart.chart_data["meters"][time] = [int(%Numerator.value), int(value)]
	%"Time Changes".set_item_text(current_time_change, format_time_change(current_time_change))


func _on_song_charter_text_changed(new_text: String) -> void:
	updated_song_charter.emit(new_text)
