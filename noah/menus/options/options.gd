extends Node2D
class_name OptionsMenu

var OPTIONS_SUBMENU_PRELOAD = load("uid://c7jk6j1osvapw")
var MENU_OPTION_PRELOAD = load("uid://dp453vkw4s2xg")

var can_click = true
var pages: Dictionary = {
	SettingsManager.SEC_KEY_BINDS: {
		"name": "Keybinds",
		"options": [
			[&"label", "Gameplay"],
			[&"option", {"id": "note_left"}],
			[&"option", {"id": "note_down"}],
			[&"option", {"id": "note_up"}],
			[&"option", {"id": "note_right"}],
			[&"option", {"id": "pause"}],
			[&"option", {"id": "kill"}],
			[&"label", "Volume"],
			[&"option", {"id": "volume_up"}],
			[&"option", {"id": "volume_down"}],
			[&"option", {"id": "mute"}],
			[&"label", "UI"],
			[&"option", {"id": "menu_left"}],
			[&"option", {"id": "menu_down"}],
			[&"option", {"id": "menu_up"}],
			[&"option", {"id": "menu_right"}],
			[&"option", {"id": "menu_accept"}],
			[&"option", {"id": "menu_cancel"}],
			[&"label", "Miscellaneous"],
			[&"option", {"id": "character_select"}]
		]
	},
	SettingsManager.SEC_CONTROLLER_BINDS: {
		"name": "Controller Binds",
		"options": [
			[&"label", "Gameplay"],
			[&"option", {"id": "note_left"}],
			[&"option", {"id": "note_down"}],
			[&"option", {"id": "note_up"}],
			[&"option", {"id": "note_right"}],
			[&"option", {"id": "pause"}],
			[&"option", {"id": "kill"}],
			[&"label", "UI"],
			[&"option", {"id": "menu_left"}],
			[&"option", {"id": "menu_down"}],
			[&"option", {"id": "menu_up"}],
			[&"option", {"id": "menu_right"}],
			[&"option", {"id": "menu_accept"}],
			[&"option", {"id": "menu_cancel"}]
		]
	},
	SettingsManager.SEC_GAMEPLAY: {
		"name": "Gameplay",
		"options": [
			[&"option", {"id": "offset",
			"description": "Visual note offset.",
			"min": -500,
			"max": 500,
			"snap": 1,
			"unit": "ms",
			"scale": 0.001
			}],
			[&"button", {"text": "Offset Calibrator", "id": &"offset"}],
			[&"option", {"id": "ghost_tapping", "description": "Disables the health and score penalty when pressing a key when there's no active notes."}],
			[&"option", {"id": "downscroll", "description": "Makes the notes go downwards rather than upwards."}],
			[&"option", {"id": "botplay", "description": "Automatically hits perfect notes."}],
			[&"option", {"id": "song_speed",
			"description": "Adjusts the speed of the song.\nWARNING: Some events do not work properly with different song speeds.",
			"min": 0.5,
			"max": 2,
			"snap": 0.05,
			"unit": "x"
			}],
			[&"option", {"id": "scroll_speed_scale",
			"description": "Adjusts the scroll speed of the notes.",
			"min": 0.5,
			"max": 2,
			"snap": 0.05,
			"unit": "x"
			}]
		]
	},
	SettingsManager.SEC_PREFERENCES: {
		"name": "Preferences",
		"options": [
			[&"option", {"id": "combo_ui", "description": "Displays the rating and combo on the UI layer rather than the world layer."}],
			[&"option", {"id": "glow_notes", "description": "Makes the notes brighter when active."}],
			[&"option", {"id": "note_splashes", "description": "Makes the notes brighter when active."}],
			[&"option", {"id": "ui_bops", "description": "Makes the UI layer bop in menus and gameplay."}],
			[&"option", {"id": "hit_sounds", "description": "Plays a sound upon hitting a note."}],
			[&"option", {"id": "underlay_opacity",
			"description": "Adds a black underlay to the UI with the given opacity.",
			"min": 0,
			"max": 100,
			"snap": 10,
			"unit": "%",
			"scale": 0.01
			}]
		]
	},
	SettingsManager.SEC_AUDIO: {
		"name": "Audio",
		"options": [
			[&"option", {"id": "master_volume",
			"min": 0,
			"max": 100,
			"snap": 5,
			"unit": "%",
			"scale": 0.01}],
			[&"option", {"id": "sfx_volume",
			"min": 0,
			"max": 100,
			"snap": 5,
			"unit": "%",
			"scale": 0.01}],
			[&"option", {"id": "music_volume",
			"min": 0,
			"max": 100,
			"snap": 5,
			"unit": "%",
			"scale": 0.01}],
		]
	},
	SettingsManager.SEC_DEBUG: {
		"name": "Debug",
		"options": [
			[&"option", {"id": "show_performance"}],
			[&"option", {"id": "cap_fps"}],
			[&"option", {"id": "fps_cap",
			"min": 30,
			"max": 3000,
			"snap": 1,
			"unit": "FPS"}],
			[&"button", {"text": "Clear Save", "id": &"clear_save"}]
		]
	}
}
var selected: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.set_window_title("Options Menu")
	
	for i in pages.size():
		var page = pages.keys()[i]
		var menu_option_instance = MENU_OPTION_PRELOAD.instantiate()
		
		menu_option_instance.text = pages[page].get("name", page.capitalize())
		menu_option_instance.icon = null
		
		$UI.add_child(menu_option_instance)
		menu_option_instance.add_to_group(&"pages")
	
	update(selected)
	
	if not SoundManager.music.playing:
		SoundManager.music.play()
	
	$Conductor.stream_player = SoundManager.music
	
	await $Conductor.ready
	
	$Conductor.tempo = SoundManager.music.stream.get_bpm()
	print(SoundManager.music.stream.get_bpm())


func _process(delta: float) -> void:
	if can_click:
		if Input.is_action_just_pressed(&"menu_cancel"):
			can_click = false
			SoundManager.cancel.play()
			
			if GameManager.song_scene != null:
				SoundManager.music.stop()
				Global.change_scene_to(GameManager.song_scene)
			else:
				Global.change_scene_to(Constants.MAIN_MENU_SCENE)
		
		if Input.is_action_just_pressed(&"menu_up"):
			update(selected - 1)
		
		if Input.is_action_just_pressed(&"menu_down"):
			update(selected + 1)
		
		if Input.is_action_just_pressed(&"menu_accept"):
			select(selected)


func _exit_tree() -> void:
	SettingsManager.load_keybinds()


func update(i: int):
	selected = wrapi(i, 0, pages.size())
	var nodes = get_tree().get_nodes_in_group(&"pages")
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for j in pages.size():
		var node = nodes[j]
		tween.tween_property(node, "position", Vector2(45 + 25 * (j - selected), 360 + 175 * (j - selected)), 0.5)
		node.modulate = Color(0.5, 0.5, 0.5)
	
	nodes[selected].modulate = Color.WHITE
	SoundManager.scroll.play()


func select(i: int):
	SoundManager.accept.play()
	var page = pages.keys()[i]
	var option_menu_instance = OPTIONS_SUBMENU_PRELOAD.instantiate()
	add_child(option_menu_instance)
	Global.manual_pause = true
	get_tree().paused = true
	print("loading: ", page)
	option_menu_instance.load_category(page, pages.get(page).get("options", [[&"label", "This page is empty."]]))


func _on_conductor_new_beat(current_beat, measure_relative):
	if SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "ui_bops"):
		Global.bop_tween($Background/Background, "scale", Vector2(1, 1), Vector2(1.005, 1.005), 0.2, Tween.TRANS_CUBIC)
