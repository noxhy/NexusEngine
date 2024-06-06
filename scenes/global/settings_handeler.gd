extends Node

const save_path = "user://settings.tres"
var settings = Settings.new()


func load_settings():
	
	if settings == null || settings.version != 1:
		reset_settings()
	
	settings = load( save_path )
	
	refresh_keybinds()
	
	print( settings )


func save_settings():
	
	ResourceSaver.save( settings, save_path )
	print( "Setting Saved" )


func reset_settings():
	
	settings = Settings.new()
	ResourceSaver.save( settings, save_path )
	print( "Setting Reset" )


func get_setting( setting_name: String ): return settings.get( setting_name )
func set_setting( setting_name: String, value: Variant ): settings.set( setting_name, value )

func get_keybind( keybind_name: String ): return settings.keybinds.get( keybind_name )

func set_keybind( keybind_name: String, keycode: int, index: int ):
	
	var new_keycodes = settings.keybinds.get( keybind_name )
	new_keycodes[index] = keycode
	
	var new_keybind: Dictionary = {
		
		keybind_name: new_keycodes
		
	}
	
	settings.keybinds.merge( new_keybind, true )


func get_keycode_string( keycodes: Array ):
	
	var output: String
	
	for i in keycodes:
		
		output += OS.get_keycode_string( i )
		if i != keycodes[ keycodes.size() - 1 ]: output += ", "
	
	return output


func refresh_keybinds():
	
	for i in settings.keybinds.keys():
		
		InputMap.action_erase_events( i )
		
		for j in get_keybind( i ):
			
			var new_key = InputEventKey.new()
			new_key.keycode = j
			InputMap.action_add_event( i, new_key )
	
	print( "Keybinds Refreshed" )
