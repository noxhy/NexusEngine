extends Node

const save_path = "user://settings.tres"
var settings = Settings.new()

# You can add any of these settings dynmaically it will be added to a dictionary in the settings resource
var default_settings: Dictionary = {
	
	# Gameplay
	
	"offset": 0.0, # Puts a delay on the notes
	"ghost_tapping": true, # Allows tapping when no notes are active
	"downscroll": false, # Notes go down instead of up, downscroll ui function is called
	"botplay": false, # By default it only works for one strumline, more support for botplay on strumlines will be need to be per song script.
	
	# Preferences
	
	"combo_ui": false, # Spawns the combo shit on the ui instead of world
	"enemy_strum_glow": false, # When notes are hit, the enemy strum will glow
	"glow_notes": false, # Glows notes when that are able to be pressed
	"note_splashes": true,
	"ui_bops": true, # The UI w"ill bop when called, this affetcs the main menus too
	"hit_sounds": false,
	"master_volume": 0,
	"music_volume": 0,
	"sfx_volume": 0,
	
	# Misc
	
	"song_speed": 1.0, # You have to scale time based events based on song speed since this only scales the speed of the music
	"scroll_speed_scale": 1.0, # Multiplies scroll speed
	"streamer_mode": false, # Hides less important UI elements, streamer mode ui function is called
	"show_performance": true, # Shows FPS, Memory, delta and shit
	
	"keybinds": {
		
		# Keybinds
		
		"press_left": [KEY_LEFT, KEY_A],
		"press_down": [KEY_DOWN, KEY_S],
		"press_up": [KEY_UP, KEY_W],
		"press_right": [KEY_RIGHT, KEY_D],
		
		"kill": [KEY_R],
		
		# Ui Keybinds
		
		"ui_plus": [KEY_EQUAL],
		"ui_minus": [KEY_MINUS],
		
		"fullscreen": [KEY_F11],
		
		"ui_cancel": [KEY_ESCAPE],
		"ui_accept": [KEY_ENTER, KEY_SPACE],
		
		"ui_left": [KEY_LEFT],
		"ui_down": [KEY_DOWN],
		"ui_up": [KEY_UP],
		"ui_right": [KEY_RIGHT]
		
	}
	
}

func load_settings():
	
	if load( save_path ) == null || settings.version != 2:
		init_settings()
	
	settings = load( save_path )
	
	refresh_settings()
	refresh_keybinds()
	
	print( save_path )


func save_settings():
	
	ResourceSaver.save( settings, save_path )
	print( "Setting Saved" )


func init_settings():
	
	settings = Settings.new()
	ResourceSaver.save( settings, save_path )
	print( "Setting Initialized" )


func refresh_settings():
	
	for s in default_settings.keys():
		
		if !settings.settings.has(s):
			
			settings.settings[s] = default_settings.get(s)
			print( "Set ", s, " to ", default_settings.get(s) )
	
	print( "Setting Refreshed" )


func get_setting( setting_name: String ): return settings.settings.get( setting_name )
func set_setting( setting_name: String, value: Variant ): settings.settings[setting_name] = value

func get_keybind( keybind_name: String ): return settings.settings.keybinds.get( keybind_name )

func set_keybind( keybind_name: String, keycode: int, index: int ):
	
	var new_keycodes = settings.settings.keybinds.get( keybind_name )
	new_keycodes[index] = keycode
	
	settings.settings.keybinds[keybind_name] = new_keycodes


func get_keycode_string( keycodes: Array ):
	
	var output: String = ""
	
	for i in keycodes:
		
		output += OS.get_keycode_string(i)
		if i != keycodes[ keycodes.size() - 1 ]: output += ", "
	
	return output


func refresh_keybinds():
	
	for i in settings.settings.keybinds.keys():
		
		InputMap.action_erase_events( i )
		
		for j in get_keybind( i ):
			
			var new_key = InputEventKey.new()
			new_key.keycode = j
			InputMap.action_add_event( i, new_key )
	
	print( "Keybinds Refreshed" )
