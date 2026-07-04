extends PanelContainer

#gibz
@onready var id_label: LineEdit = $"HBoxContainer/ID Label"
@onready var hit_sound_box: CheckBox = $"HBoxContainer/HBoxContainer/hit sound box"
@onready var delete_track: Button = $"HBoxContainer/VBoxContainer/Delete Track"
@onready var song_path: TextEdit = $"HBoxContainer/VBoxContainer2/song path"
@onready var vol_slider: HSlider = $"HBoxContainer/VBoxContainer2/VBoxContainer/vol Slider"
@onready var waveform: CheckBox = $HBoxContainer/HBoxContainer/waveform

@export var strum_id: int = -1

signal remove_requested


func set_id(id: int):
	if id == -1:
		id_label.text = 'Inst'
	else:
		id_label.text = 'ID: %s' % id
	strum_id = id

func set_path(path: String):
	if path.begins_with("uid"):
		path = ResourceUID.uid_to_path(path)
	
	song_path.text = path

func _on_vol_slider_value_changed(value: float) -> void:
	if not ChartManager.song:
		vol_slider.set_value_no_signal(0)
		return
	
	if strum_id == -1:
		ChartEditor.instrumental_volume = value
	elif is_valid_id():
		ChartManager.strum_data[strum_id]['volume'] = value

func _on_hit_sound_box_toggled(toggled_on: bool) -> void:
	
	if strum_id == -1:
		pass
	elif is_valid_id():
		ChartManager.strum_data[strum_id]['hit_sounds'] = toggled_on

func _on_delete_track_pressed() -> void:
	remove_requested.emit()

func _on_waveform_toggled(toggled_on: bool) -> void:
	ChartManager.strum_data[strum_id]['waveform'] = toggled_on

func is_valid_id():
	return strum_id == -1 or ChartManager.strum_data.size() > strum_id

func load_current_song():
	if not ChartManager.song:
		return
	
	delete_track.visible = strum_id != -1
	hit_sound_box.disabled = strum_id == -1
	
	var volume: float = ChartEditor.instrumental_volume
	var waveform_enabled: bool = ChartEditor.instrumental_waveforms
	
	
	if strum_id == -1:
		set_path(ChartManager.song.instrumental)
	elif is_valid_id():
		if ChartManager.song.vocals.size() > strum_id:
			set_path(ChartManager.song.vocals[strum_id])
		volume = ChartManager.strum_data[strum_id]['volume']
		waveform_enabled = ChartManager.strum_data[strum_id]['waveform']
	else:
		volume = 0
	
	vol_slider.set_value_no_signal(volume)
	waveform.set_pressed_no_signal(waveform_enabled)


func _on_change_track_pressed() -> void:
	%FileDialog.popup()

func _on_file_dialog_file_selected(path: String) -> void:
	set_path(path)
