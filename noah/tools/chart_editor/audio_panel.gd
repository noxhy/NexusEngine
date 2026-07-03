extends PanelContainer

#gibz
@onready var id_label: LineEdit = $"HBoxContainer/ID Label"
@onready var hit_sound_box: CheckBox = $"HBoxContainer/HBoxContainer/hit sound box"
@onready var vol_slider: HSlider = $"HBoxContainer/HBoxContainer/vol Slider"
@onready var delete_track: Button = $"HBoxContainer/VBoxContainer/Delete Track"
@onready var song_path: TextEdit = $"HBoxContainer/song path"

@export var strum_id: int = -1

#func _ready():

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
		pass
	else:
		ChartManager.strum_data[strum_id]['volume'] = value
		print('id: ',strum_id, ' vol ', ChartManager.strum_data[strum_id]['volume'])

func _on_hit_sound_box_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.



func load_current_song():
	if not ChartManager.song:
		return
	
	if strum_id == -1:
		set_path(ChartManager.song.instrumental)
	else:
		set_path(ChartManager.song.vocals[strum_id])
		
	
	
	
