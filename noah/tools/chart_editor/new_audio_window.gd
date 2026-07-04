extends Window

@onready var inst_panel: PanelContainer = $"VBoxContainer/inst panel"
@onready var vbox: VBoxContainer = $VBoxContainer/ScrollContainer/vbox

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
		var instance: Control = PANEL_PRELOAD.instantiate()
		vbox.add_child(instance)
		instance.set_id(idx)
		instance.load_current_song()
		instance.remove_requested.connect(remove_track.bind(idx))
		idx += 1

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
