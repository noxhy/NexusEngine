extends Node

# based off funkin cherry smile
# no it's not data shut up
const LOAD_PATH: String = 'user://settings.cfg'

## categories (this is our way of doing text enums
const SEC_PREFERENCES: String = 'preferences'
const SEC_GAMEPLAY: String = 'gameplay'
const SEC_AUDIO: String = 'audio'
const SEC_CHART: String = 'chart'
const SEC_DEBUG: String = 'debug'
const SEC_KEY_BINDS: String = 'keybinds'
const SEC_CONTROLLER_BINDS: String = 'controller_binds'
const SEC_SONGS: String = 'songs'
const SEC_WEEKS: String = 'weeks'


var instance: ConfigFile
#these are the only functions u need to worry about

## Grabs a save value from instance
func get_value(section: String, key: String, fallback: Variant = null) -> Variant:
	return instance.get_value(section, key, fallback)

## Sets a save value in instance
func set_value(section: String, key: String, value: Variant) -> void:
	instance.set_value(section, key, value)

## Saves to disk
func flush() -> void:
	instance.save(LOAD_PATH)
	print('(SettingsManager): Saved preferences')

static var _defaults: Dictionary = {
	SEC_GAMEPLAY: {
		"offset": 0.0, ## Puts a delay on the notes
		"ghost_tapping": true, ## Allows tapping when no notes are active
		"downscroll": false, ## Notes go down instead of up, downscroll ui function is called
		"botplay": false, ## By default it only works for one strumline, more support for botplay on strumlines will be need to be per song script.
		"song_speed": 1.0,
		"scroll_speed_scale": 1.0
	},
	
	SEC_PREFERENCES: {
		"combo_ui": false, ## Spawns the combo shit on the ui instead of world
		"glow_notes": false, ## Glows notes when that are able to be pressed
		"note_splashes": true,
		"ui_bops": true, ## The UI w"ill bop when called, this affetcs the main menus too
		"hit_sounds": false,
		"fullscreen": false, ##i dont like this here but where else,
		"underlay_opacity": 0.0 ## Adds a black ColorRect on the UI node with the given opacity.
	},
	
	SEC_AUDIO: {
		"master_volume": 0.5, ## the global sound volume. Affects everything
		"sfx_volume": 1, ## The sfx volume. Only Affects sfx
		"music_volume": 1, ## The music volume. Only applied to music tracks
		"is_muted": false
	},
	
	SEC_DEBUG: {
		"show_performance": true, ## Shows FPS, Memory, delta and shit,
		"cap_fps": true, ## caps fps
		"fps_cap": int(DisplayServer.screen_get_refresh_rate())
	},
	
	SEC_CHART: {
		"auto_save": true,
		"start_at_current_position": false,
		"conductor_beat": false,
		"conductor_step": false,
		"hit_sounds": true
	},
	
	SEC_KEY_BINDS: {
		"note_left": [KEY_LEFT, KEY_A],
		"note_down": [KEY_DOWN, KEY_S],
		"note_up": [KEY_UP, KEY_W],
		"note_right": [KEY_RIGHT, KEY_D],
		
		"pause": [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE, KEY_BACKSPACE],
		"kill": [KEY_R],
		
		# Ui Keybinds
		
		"volume_up": [KEY_EQUAL],
		"volume_down": [KEY_MINUS],
		
		"fullscreen": [KEY_F11],
		
		"menu_accept": [KEY_ENTER, KEY_Z],
		"menu_cancel": [KEY_ESCAPE, KEY_X],
		
		"character_select": [KEY_TAB],
		
		"menu_left": [KEY_LEFT, KEY_A],
		"menu_down": [KEY_DOWN, KEY_S],
		"menu_up": [KEY_UP, KEY_W],
		"menu_right": [KEY_RIGHT, KEY_D],
		"mute": [KEY_0]
	},
	
	SEC_CONTROLLER_BINDS: {
		"note_left": [JOY_BUTTON_X, JOY_BUTTON_DPAD_LEFT],
		"note_down": [JOY_BUTTON_A, JOY_BUTTON_DPAD_DOWN],
		"note_up": [JOY_BUTTON_Y, JOY_BUTTON_DPAD_UP],
		"note_right": [JOY_BUTTON_B, JOY_BUTTON_DPAD_RIGHT],
		
		"pause": [JOY_BUTTON_START],
		"kill": [JOY_BUTTON_BACK],
		
		# Ui Keybinds
		"menu_accept": [JOY_BUTTON_A],
		"menu_cancel": [JOY_BUTTON_B],
		"character_select": [JOY_BUTTON_START],
		
		"menu_left": [JOY_BUTTON_DPAD_LEFT],
		"menu_down": [JOY_BUTTON_DPAD_DOWN],
		"menu_up": [JOY_BUTTON_DPAD_UP],
		"menu_right": [JOY_BUTTON_DPAD_RIGHT]
	}
}


func _ready() -> void:
	instance = get_default()
	load_values()
	load_keybinds()

func load_values() -> void:
	if not FileAccess.file_exists(LOAD_PATH):
		print('(SettingsManager): Preferences not detected. Using defaults')
		return
	
	var temp_config = ConfigFile.new()
	var loadError: Error = temp_config.load(LOAD_PATH)
	
	if loadError == Error.OK:
		for section:String in temp_config.get_sections():
			for key in temp_config.get_section_keys(section):
				if instance.has_section_key(section, key):
					
					var instance_value = instance.get_value(section, key)
					
					if instance_value is Array: # this is kinda weird but sure
						var saved_value = temp_config.get_value(section, key)
						
						if saved_value and instance_value.size() != saved_value.size():
							for idx in range(instance_value.size() - 1):
								instance_value[idx] = saved_value[idx]
							
							instance.set_value(section, key, instance_value)
							continue
					
					instance.set_value(section, key, temp_config.get_value(section, key))
	
	# sets fullscreen
	var fullscreen = SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, 'fullscreen')
	
	var mode = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	
	print("(SettingsManager): Preferences loaded")

func get_default() -> ConfigFile:
	var temp_config = ConfigFile.new()
	
	for section:String in _defaults.keys():
		var section_val:Dictionary = _defaults.get(section, {})
		for key:String in section_val.keys():
			temp_config.set_value(section, key, section_val.get(key))
	
	return temp_config


func get_keybind(keybind_name: String) -> Array:
	return instance.get_value(SEC_KEY_BINDS, keybind_name, [])


func get_controller_bind(bind_name: String) -> Array:
	return instance.get_value(SEC_CONTROLLER_BINDS, bind_name, [])


func set_keybind(keybind_name: String, keycode: int, index: int):
	var new_keycodes = instance.get_value(SEC_KEY_BINDS, keybind_name)
	new_keycodes[index] = keycode
	
	instance.set_value(SEC_KEY_BINDS, keybind_name, new_keycodes)


func set_controller_bind(bind_name: String, button_index: int, index: int):
	var new_keycodes = instance.get_value(SEC_CONTROLLER_BINDS, bind_name)
	new_keycodes[index] = button_index
	
	instance.set_value(SEC_CONTROLLER_BINDS, bind_name, new_keycodes)


func load_keybinds():
	for key in instance.get_section_keys(SEC_KEY_BINDS):
		InputMap.action_erase_events(key)
		
		for bind in get_keybind(key):
			var new_key = InputEventKey.new()
			new_key.keycode = bind
			InputMap.action_add_event(key, new_key)
	
	for bind_id in instance.get_section_keys(SEC_CONTROLLER_BINDS):
		var new_key: InputEvent
		for bind in get_controller_bind(bind_id):
			if bind >= 100:
				new_key = InputEventJoypadMotion.new()
				new_key.axis = bind - 100
			else:
				new_key = InputEventJoypadButton.new()
				new_key.button_index = bind
			
			InputMap.action_add_event(bind_id, new_key)
	
#region Joystick Controls
	var event: InputEventJoypadMotion
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_RIGHT_X]:
		event = InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = -1
		InputMap.action_add_event("note_left", event)
		InputMap.action_add_event("menu_left", event)
		
		event = InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = 1
		InputMap.action_add_event("note_right", event)
		InputMap.action_add_event("menu_right", event)
	
	for axis in [JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_Y]:
		event = InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = -1
		InputMap.action_add_event("note_up", event)
		InputMap.action_add_event("menu_up", event)
		
		event = InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = 1
		InputMap.action_add_event("note_down", event)
		InputMap.action_add_event("menu_down", event)
#endregion
	
	print("(SettingsManager): Key and Controller binds loaded")


#region Controller Button Names
func translate_joy_bind(device: int, bind: int) -> String:
	var device_name: String = Input.get_joy_name(device)
	
	var joy_button_names: Dictionary = {
		JoyButton.JOY_BUTTON_A: "A",
		JoyButton.JOY_BUTTON_B: "B",
		JoyButton.JOY_BUTTON_X: "X",
		JoyButton.JOY_BUTTON_Y: "Y",
		JoyButton.JOY_BUTTON_LEFT_SHOULDER: "LB",
		JoyButton.JOY_BUTTON_RIGHT_SHOULDER: "RB",
		JoyButton.JOY_BUTTON_BACK: "Back",
		JoyButton.JOY_BUTTON_START: "Start",
		JoyButton.JOY_BUTTON_LEFT_STICK: "LS Click",
		JoyButton.JOY_BUTTON_RIGHT_STICK: "RS Click",
		JoyButton.JOY_BUTTON_DPAD_UP: "D-Pad Up",
		JoyButton.JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
		JoyButton.JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
		JoyButton.JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
		(JoyAxis.JOY_AXIS_TRIGGER_LEFT + 100): "LT",
		(JoyAxis.JOY_AXIS_TRIGGER_RIGHT + 100): "LR"
	}
	
	if device_name.to_lower().contains("dualsense") or device_name.to_lower().contains("dualshock"):
		joy_button_names = {
			JoyButton.JOY_BUTTON_A: "❌",
			JoyButton.JOY_BUTTON_B: "⭕",
			JoyButton.JOY_BUTTON_X: "□",
			JoyButton.JOY_BUTTON_Y: "🔺",
			JoyButton.JOY_BUTTON_LEFT_SHOULDER: "L1",
			JoyButton.JOY_BUTTON_RIGHT_SHOULDER: "R1",
			JoyButton.JOY_BUTTON_BACK: "Select",
			JoyButton.JOY_BUTTON_START: "Options",
			JoyButton.JOY_BUTTON_LEFT_STICK: "L3",
			JoyButton.JOY_BUTTON_RIGHT_STICK: "R3",
			JoyButton.JOY_BUTTON_DPAD_UP: "D-Pad Up",
			JoyButton.JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
			JoyButton.JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
			JoyButton.JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
			(JoyAxis.JOY_AXIS_TRIGGER_LEFT + 100): "L2",
			(JoyAxis.JOY_AXIS_TRIGGER_RIGHT + 100): "R2"
		}
	elif device_name.to_lower().contains("nintendo"):
		joy_button_names = {
			JoyButton.JOY_BUTTON_A: "B",
			JoyButton.JOY_BUTTON_B: "A",
			JoyButton.JOY_BUTTON_X: "Y",
			JoyButton.JOY_BUTTON_Y: "X",
			JoyButton.JOY_BUTTON_LEFT_SHOULDER: "L",
			JoyButton.JOY_BUTTON_RIGHT_SHOULDER: "R",
			JoyButton.JOY_BUTTON_BACK: "-",
			JoyButton.JOY_BUTTON_START: "+",
			JoyButton.JOY_BUTTON_LEFT_STICK: "LS Click",
			JoyButton.JOY_BUTTON_RIGHT_STICK: "RS Click",
			JoyButton.JOY_BUTTON_DPAD_UP: "D-Pad Up",
			JoyButton.JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
			JoyButton.JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
			JoyButton.JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
			(JoyAxis.JOY_AXIS_TRIGGER_LEFT + 100): "ZL",
			(JoyAxis.JOY_AXIS_TRIGGER_RIGHT + 100): "ZR"
		}
	
	return joy_button_names.get(bind, "?")
#endregion
