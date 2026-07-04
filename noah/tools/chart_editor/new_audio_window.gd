extends Window

@onready var inst_panel: PanelContainer = $"VBoxContainer/inst panel"
@onready var vbox: VBoxContainer = $VBoxContainer/ScrollContainer/vbox

@onready var save_button: Button = $"VBoxContainer/HBoxContainer/Save Button"
@onready var add_track_button: Button = $"VBoxContainer/HBoxContainer/Add Track"

var PANEL_PRELOAD = load("uid://bc4d7j7ifsf86")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	close_requested.connect(hide_popup)
	about_to_popup.connect(prepare_tracks)
	

func prepare_tracks():
	if not ChartManager.song:
		return
	
	inst_panel.set_id(-1)
	inst_panel.load_current_song()
	
	for panel in vbox.get_children():
		vbox.remove_child(panel)
		panel.queue_free()
	
	
	var idx: int = 0
	
	for vocals in ChartManager.song.vocals:
		add_track(idx)
		idx += 1

func add_track(idx:int):
	var instance: Control = PANEL_PRELOAD.instantiate()
	vbox.add_child(instance)
	instance.set_id(idx)
	instance.load_current_song()
	instance.remove_requested.connect(remove_track.bind(idx))

func remove_track(id: int):
	var track = vbox.get_child(id)
	if not track:
		return
	vbox.remove_child(track)
	track.queue_free()
	
	var idx: int = 0
	for node in vbox.get_children():
		node.set_id(idx)
		node.load_current_song()
		idx += 1

func hide_popup():
	hide()


func _on_add_track_pressed() -> void:
	add_track(vbox.get_child_count())

func _on_save_button_pressed() -> void:
	ChartManager.song.instrumental = inst_panel.song_path.text
	ChartManager.song.vocals.clear()
	for node in vbox.get_children():
		ChartManager.song.vocals.append(node.song_path.text)
	
