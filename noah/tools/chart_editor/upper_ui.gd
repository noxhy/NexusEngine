extends HBoxContainer
class_name ChartEditorUpperUI

var chart_editor: ChartEditor

@onready var file_button: MenuButton = %"File Button"
@onready var edit_button: MenuButton = %"Edit Button"
@onready var view_button: MenuButton = %"View Button"
@onready var audio_button: MenuButton = %"Audio Button"
@onready var test_button: MenuButton = %"Test Button"
@onready var window_button: MenuButton = %"Window Button"

@onready var help_button: MenuButton = %"Help Button"

@onready var export_external_popup: FileDialog = %"Export External Popup"
@onready var note_skin_window: FileDialog = %"Note Skin Window"
@onready var audios_window: Window = %"AudioWindow"
@onready var metadata_window: Window = %"Metadata Window"
@onready var note_type_window: Window = %"Note Type Window"
@onready var history_window: Window = %"History Window"



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chart_editor = get_parent().get_parent()
	
	file_button.get_popup().id_pressed.connect(file_button_item_pressed)
	file_button.get_popup().set_hide_on_checkable_item_selection(false)
	file_button.get_popup().set_item_checked(
		file_button.get_popup().get_item_index(3),
		SettingsManager.get_value(SettingsManager.SEC_CHART, "auto_save"))
	
	edit_button.get_popup().id_pressed.connect(chart_editor.edit_button_item_pressed)
	edit_button.get_popup().set_hide_on_checkable_item_selection(false)
	
	#audio button
	audio_button.get_popup().connect(&"id_pressed", chart_editor.audio_button_item_pressed)
	audio_button.get_popup().set_item_checked(
		audio_button.get_popup().get_item_index(7),
		SettingsManager.get_value(SettingsManager.SEC_CHART, "conductor_beat"))
	
	audio_button.get_popup().set_item_checked(
		audio_button.get_popup().get_item_index(8),
		SettingsManager.get_value(SettingsManager.SEC_CHART, "conductor_step"))
	audio_button.get_popup().set_hide_on_checkable_item_selection(false)
	
	audio_button.get_popup().set_item_checked(
		audio_button.get_popup().get_item_index(11), ChartEditor.vocal_waveforms)
		
	audio_button.get_popup().set_item_checked(
		audio_button.get_popup().get_item_index(12), ChartEditor.instrumental_waveforms)
	
	
	#audio_button.get_popup().set_item_checked(
		#audio_button.get_popup().get_item_index(10),
		#SettingsManager.get_value(SettingsManager.SEC_CHART, "hit_sounds"))
	
	#view button
	view_button.get_popup().connect(&"id_pressed", chart_editor.view_button_item_pressed)
	view_button.get_popup().set_hide_on_checkable_item_selection(false)
	
	
	test_button.get_popup().connect(&"id_pressed", chart_editor.test_button_item_pressed)
	test_button.get_popup().set_item_checked(
		test_button.get_popup().get_item_index(3),
		SettingsManager.get_value(SettingsManager.SEC_CHART, "start_at_current_position"))
	test_button.get_popup().set_hide_on_checkable_item_selection(false)
	
	
	window_button.get_popup().connect(&"id_pressed", chart_editor.window_button_item_pressed)
	window_button.get_popup().set_hide_on_checkable_item_selection(false)

	
	
	#setup windows
	
	audios_window.close_requested.connect(func():
		window_button.get_popup().set_item_checked(3, false)
		SoundManager.tool_close_window.play()
		)
	audios_window.updated_current_song.connect(func():
		if not chart_editor.instrumental.stream_paused:
			chart_editor.toggle_audios()
		chart_editor.instrumental.stream = SoundManager.get_stream(ChartManager.song.instrumental)
		chart_editor.waveform_dirty = true
		chart_editor.auto_save()
		)
	
	export_external_popup.connect(&"file_selected", chart_editor._on_export_external_popup_file_selected)
	
	note_skin_window.connect(&"file_selected", chart_editor._on_note_skin_window_file_selected)
	
	history_window.connect(&"close_requested", chart_editor._on_history_window_close_requested)
	
	metadata_window.connect(&"add_time_change", chart_editor._on_metadata_window_add_time_change)
	metadata_window.connect(&"remove_time_change", chart_editor._on_metadata_window_remove_time_change)
	metadata_window.connect(&"selected_time_change", chart_editor._on_metadata_window_selected_time_change)
	metadata_window.connect(&"updated_icon_texture", chart_editor._on_metadata_window_updated_icon_texture)
	metadata_window.connect(&"updated_scroll_speed", chart_editor._on_metadata_window_updated_scroll_speed)
	metadata_window.connect(&"updated_song_artist", chart_editor._on_metadata_window_updated_song_artist)
	metadata_window.connect(&"updated_song_charter", chart_editor._on_metadata_window_updated_song_charter)
	metadata_window.connect(&"updated_song_name", chart_editor._on_metadata_window_updated_song_name)
	metadata_window.connect(&"updated_song_scene", chart_editor._on_metadata_window_updated_song_scene)
	metadata_window.connect(&"updated_starting_tempo", chart_editor._on_metadata_window_updated_starting_tempo)
	metadata_window.connect(&"close_requested", chart_editor._on_metadata_window_close_requested)
	
	note_type_window.connect(&"selected_note_type", chart_editor.set_note_type)
	note_type_window.connect(&"close_requested", chart_editor._on_note_type_window_close_requested)
	
	
	
	setup_shortcuts()
	
	#add menupopups to the thing
	for child in get_children():
		if child is MenuButton:
			child.get_popup().add_to_group(&"windows")
	
func setup_shortcuts():
	var shortcut:Shortcut
	
	# file buttons
	file_button.get_popup().set_item_shortcut(
		file_button.get_popup().get_item_index(2), chart_editor.make_shortcut_quick(InputMap.action_get_events(&"save")))
	
	
	# edit button
	edit_button.get_popup().set_item_shortcut(
		edit_button.get_popup().get_item_index(0), chart_editor.make_shortcut_quick(InputMap.action_get_events(&"ui_undo")))
	
	edit_button.get_popup().set_item_shortcut(
		edit_button.get_popup().get_item_index(1), chart_editor.make_shortcut_quick(InputMap.action_get_events(&"ui_redo")))
	
	edit_button.get_popup().set_item_shortcut(
		edit_button.get_popup().get_item_index(3), chart_editor.make_shortcut_quick(InputMap.action_get_events(&"ui_cut")))
	
	edit_button.get_popup().set_item_shortcut(
		edit_button.get_popup().get_item_index(4), chart_editor.make_shortcut_quick(InputMap.action_get_events(&"ui_copy")))
	
	edit_button.get_popup().set_item_shortcut(
		edit_button.get_popup().get_item_index(5), chart_editor.make_shortcut_quick(InputMap.action_get_events(&"ui_paste")))
	
	edit_button.get_popup().set_item_shortcut(
		edit_button.get_popup().get_item_index(6), chart_editor.make_shortcut_quick(InputMap.action_get_events(&"ui_text_delete_word")))
	
	edit_button.get_popup().set_item_shortcut(
		edit_button.get_popup().get_item_index(8), chart_editor.make_shortcut_quick(InputMap.action_get_events(&"flip_notes")))
	
	edit_button.get_popup().set_item_shortcut(
		edit_button.get_popup().get_item_index(10), chart_editor.make_shortcut_quick(InputMap.action_get_events(&"ui_text_select_all")))
	
	edit_button.get_popup().set_item_shortcut(
		edit_button.get_popup().get_item_index(11), chart_editor.make_shortcut_quick(InputMap.action_get_events(&"deselect")))
	
	shortcut = chart_editor.make_shortcut_quick([InputEventKey.new()])
	shortcut.events[0].keycode = KEY_E
	edit_button.get_popup().set_item_shortcut(
		edit_button.get_popup().get_item_index(12), shortcut)
	
	shortcut = chart_editor.make_shortcut_quick([InputEventKey.new()])
	shortcut.events[0].keycode = KEY_Q
	edit_button.get_popup().set_item_shortcut(
		edit_button.get_popup().get_item_index(13), shortcut)
	
	#audio button
	
	shortcut = chart_editor.make_shortcut_quick([InputEventKey.new()])
	shortcut.events[0].keycode = KEY_SPACE
	audio_button.get_popup().set_item_shortcut(
		audio_button.get_popup().get_item_index(0), shortcut)
	
	shortcut = chart_editor.make_shortcut_quick([InputEventKey.new()])
	shortcut.events[0].keycode = KEY_EQUAL
	shortcut.events[0].shift_pressed = true
	
	audio_button.get_popup().set_item_shortcut(
		audio_button.get_popup().get_item_index(4), shortcut)
		
	shortcut = chart_editor.make_shortcut_quick([InputEventKey.new()])
	shortcut.events[0].keycode = KEY_MINUS
	shortcut.events[0].shift_pressed = true
	
	audio_button.get_popup().set_item_shortcut(
		audio_button.get_popup().get_item_index(5), shortcut)
		
	shortcut = chart_editor.make_shortcut_quick([InputEventKey.new()])
	shortcut.events[0].keycode = KEY_TAB
	
	#view button
	view_button.get_popup().set_item_shortcut(
		view_button.get_popup().get_item_index(0), shortcut)
		
	shortcut = chart_editor.make_shortcut_quick([InputEventKey.new(), InputEventKey.new()])
	shortcut.events[0].keycode = KEY_EQUAL
	shortcut.events[0].ctrl_pressed = true
	shortcut.events[0].command_or_control_autoremap = true
	
	shortcut.events[1].keycode = KEY_Z
	
	view_button.get_popup().set_item_shortcut(
		view_button.get_popup().get_item_index(3), shortcut)
		
	
	shortcut = chart_editor.make_shortcut_quick([InputEventKey.new(), InputEventKey.new()])
	
	shortcut.events[0].keycode = KEY_MINUS
	shortcut.events[0].ctrl_pressed = true
	shortcut.events[0].command_or_control_autoremap = true
	
	shortcut.events[1].keycode = KEY_X
	
	view_button.get_popup().set_item_shortcut(
		view_button.get_popup().get_item_index(4), shortcut)
		
	shortcut = chart_editor.make_shortcut_quick([InputEventKey.new(), InputEventKey.new()])
	shortcut.events[0].keycode = KEY_ENTER

	#test button
	test_button.get_popup().set_item_shortcut(
		test_button.get_popup().get_item_index(0), shortcut)
	
	shortcut = chart_editor.make_shortcut_quick([InputEventKey.new(), InputEventKey.new()])
	shortcut.events[0].keycode = KEY_ENTER
	shortcut.events[0].shift_pressed = true
	test_button.get_popup().set_item_shortcut(
		test_button.get_popup().get_item_index(1), shortcut)
	

func file_button_item_pressed(id):
	match id:
		21: # Load ZIP
			var file_dialog: FileDialog = FileDialog.new()
			file_dialog.filters = PackedStringArray(["*.zip"])
			file_dialog.access = FileDialog.ACCESS_FILESYSTEM
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			
			file_dialog.about_to_popup.connect(chart_editor.open_popup)
			file_dialog.close_requested.connect(chart_editor.close_popup)
			file_dialog.close_requested.connect(file_dialog.queue_free)
			file_dialog.theme = chart_editor.TOOL_THEME
			file_dialog.use_native_dialog = true
			file_dialog.mode_overrides_title = false
			file_dialog.title = 'Load a Song Zip'
			file_dialog.add_to_group(&"windows")
			
			add_child(file_dialog)
			file_dialog.popup()
			
			var load_zip = func(path: String) -> void:
				const TEMP_PATH: String = 'user://temp_song'
				
				if not DirAccess.dir_exists_absolute(TEMP_PATH):
					DirAccess.make_dir_absolute(TEMP_PATH)
				
				if not DirAccess.dir_exists_absolute(TEMP_PATH.path_join('charts')):
					DirAccess.make_dir_absolute(TEMP_PATH.path_join('charts'))
				
				var reader = ZIPReader.new()
				reader.open(path)
				
				var temp_song = Song.new()
				
				var misc_data = ZipTools.read_dict_from_zip(reader, 'misc_data.json')
				
				for key: String in misc_data.get('chart_keys', []):
					var chart = ZipTools.read_resource_from_zip(reader, 'charts/' + key + '.res')
					if not chart:
						chart = ZipTools.read_text_resource_from_zip(reader, 'charts/' + key + '.tres')
					var ch_path = TEMP_PATH.path_join('charts/' + key + '.res')
					ResourceSaver.save(chart, ch_path)
					
					temp_song.difficulties.set(key, {
						"chart": ch_path
					})
					
				
				var inst_buffer = reader.read_file('Inst.' + misc_data.get('inst_key', 'ogg'))
				var inst = SoundManager.get_stream_from_buffer(inst_buffer, misc_data.get('inst_key', 'ogg'))
				
				if inst:
					var inst_path = TEMP_PATH.path_join('inst.' + misc_data.get('inst_key', 'ogg'))
					var file = FileAccess.open(inst_path, FileAccess.WRITE)
					file.store_buffer(inst_buffer)
					file.close()
					temp_song.instrumental = inst_path
				
				
				var vocal_paths: Array[String] = []
				var idx: int = 0
				for key: String in misc_data.get('vocal_keys', []):
					var buffer = reader.read_file('Voices' + str(idx) + '.' + key)
					
					var stream: AudioStream = SoundManager.get_stream_from_buffer(buffer, key)
					
					if stream:
						var vocals_path = TEMP_PATH.path_join('Voices' + str(idx) + '.' + key)
						var file = FileAccess.open(vocals_path, FileAccess.WRITE)
						file.store_buffer(buffer)
						file.close()
						
						vocal_paths.append(vocals_path)
					
					idx += 1
				
				temp_song.vocals = vocal_paths
				
				temp_song.artist = misc_data.get('artist', 'unknown')
				temp_song.charter = misc_data.get('charter', 'unknown')
				temp_song.tempo = misc_data.get('tempo', 60)
				temp_song.title = misc_data.get('title', 'unknown')
				
				reader.close()
				chart_editor.load_song(temp_song, misc_data.get('chart_keys')[0])
			
			file_dialog.file_selected.connect(load_zip)
		20: #Export ZIP
			var file_dialog: FileDialog = FileDialog.new()
			file_dialog.filters = PackedStringArray(["*.zip"])
			file_dialog.access = FileDialog.ACCESS_FILESYSTEM
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.use_native_dialog = true
			file_dialog.mode_overrides_title = false
			file_dialog.title = 'Export a Song Zip'
			file_dialog.add_to_group(&"windows")
			
			file_dialog.about_to_popup.connect(chart_editor.open_popup)
			file_dialog.close_requested.connect(chart_editor.close_popup)
			file_dialog.close_requested.connect(file_dialog.queue_free)
			file_dialog.theme = chart_editor.TOOL_THEME
			
			add_child(file_dialog)
			file_dialog.popup()
			
			var export_zip = func(path: String) -> void:
				if not ChartManager.song:
					return
				
				var vocal_keys:Array = []
				var chart_keys:Array = []
				var misc_data:Dictionary = {}
				
				var zip = ZIPPacker.new()
				zip.open(path)
				
				var inst_path: String = ChartManager.song.instrumental
				if not inst_path.is_empty():
					if inst_path.begins_with('uid'):
						inst_path = ResourceUID.uid_to_path(inst_path)
					
					ZipTools.write_snd_to_zip(zip, 'Inst.' + inst_path.get_extension(), inst_path)
				
				var idx: int = 0
				for vocal_path: String in ChartManager.song.vocals:
					if vocal_path.begins_with('uid'):
						vocal_path = ResourceUID.uid_to_path(vocal_path)
					
					vocal_keys.append(vocal_path.get_extension())
					ZipTools.write_snd_to_zip(zip, 'Voices' + str(idx) + '.' + vocal_path.get_extension(), vocal_path)
					idx += 1
				
				for diff in ChartManager.song.difficulties:
					var chart = ChartManager.song.difficulties.get(diff).get('chart')
					if chart:
						chart_keys.append(diff)
						ZipTools.write_resource_to_zip(zip, 'charts/' + diff, Chart.load(chart))
					
				
				misc_data.set('artist', ChartManager.song.artist)
				misc_data.set('charter', ChartManager.song.charter)
				misc_data.set('title', ChartManager.song.title)
				misc_data.set('tempo', ChartManager.song.tempo)
				misc_data.set('vocal_keys', vocal_keys)
				misc_data.set('chart_keys', chart_keys)
				misc_data.set('inst_key', inst_path.get_extension())
				
				ZipTools.write_dict_to_zip(zip, 'misc_data.json', misc_data)
				
				zip.close()
			
			file_dialog.file_selected.connect(export_zip)
		0: # make a new song
			chart_editor.can_chart = false
			var new_file_popup_instance = chart_editor.NEW_FILE_POPUP_PRELOAD.instantiate()
			
			add_child(new_file_popup_instance)
			new_file_popup_instance.popup()
			new_file_popup_instance.connect("file_created", chart_editor.new_file)
			new_file_popup_instance.connect("close_requested", chart_editor.close_popup)
			SoundManager.tool_open_window.play()
		
		1: open_open_file_window()
		
		2:
			if ChartManager.song and ChartManager.chart:
				chart_editor.save()
		
		7:
			chart_editor.can_chart = false
			
			var convert_chart_popup_instance = chart_editor.CONVERT_CHART_POPUP_PRELOAD.instantiate()
			
			add_child(convert_chart_popup_instance)
			convert_chart_popup_instance.popup()
			# convert_chart_popup_instance.connect("file_created", chart_editor._on_save_folder_dialog_dir_selected)
			convert_chart_popup_instance.connect("file_created", chart_editor.new_file)
			convert_chart_popup_instance.connect("close_requested", chart_editor.close_popup)
			SoundManager.tool_open_window.play()
		
		3: #Autosave
			SettingsManager.set_value(SettingsManager.SEC_CHART, "auto_save",
			!SettingsManager.get_value(SettingsManager.SEC_CHART, "auto_save"))
			SettingsManager.flush()
			file_button.get_popup().set_item_checked(
				file_button.get_popup().get_item_index(id), SettingsManager.get_value(SettingsManager.SEC_CHART, "auto_save"))
			SoundManager.tool_mouse_click.play()
		
		6: #Exit
			chart_editor.set_chart_from_chart(chart_editor.backup_chart)
			Global.change_scene_to(Constants.START_MENU_SCENE)
			chart_editor.can_chart = false
		
		8: #Export External
			chart_editor.can_chart = false
			export_external_popup.popup()
			SoundManager.tool_open_window.play()
		
		9: #Save events
			chart_editor.can_chart = false
			SoundManager.tool_open_window.play()
			
			var export_window = FileDialog.new()
			export_window.current_file = 'events.tres'
			export_window.filters = PackedStringArray(['*.res','*.tres'])
			export_window.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			export_window.display_mode = FileDialog.DISPLAY_LIST
			export_window.add_to_group(&"windows")
			add_child(export_window)
			
			export_window.popup_centered()
			
			if ChartManager.song and !ChartManager.song.events.is_empty():
				if ResourceLoader.exists(ChartManager.song.events):
					export_window.current_path = ResourceUID.uid_to_path(ChartManager.song.events)
			
			var on_save = func(path:String):
				var event = ChartEvents.new()
				event.data = ChartManager.chart.get_events_data()
				ResourceSaver.save(event, path)
				export_window.hide()
			
			var on_close = func():
				export_window.queue_free()
			
			export_window.connect(&"file_selected", on_save)
			export_window.connect(&"close_requested", chart_editor.close_popup)
			export_window.connect(&"close_requested", on_close)
		10: #Load events
			chart_editor.can_chart = false
			SoundManager.tool_open_window.play()
			
			var export_window = FileDialog.new()
			export_window.filters = PackedStringArray(['*.res','*.tres'])
			export_window.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			export_window.display_mode = FileDialog.DISPLAY_LIST
			export_window.add_to_group(&"windows")
			add_child(export_window)
			
			export_window.popup_centered()
			if ChartManager.song and !ChartManager.song.events.is_empty():
				if ResourceLoader.exists(ChartManager.song.events):
					export_window.current_path = ResourceUID.uid_to_path(ChartManager.song.events)
			
			var on_open = func(path:String):
				if path.is_empty() and not ResourceLoader.exists(path): 
					printerr('File does not exist! [' + path + ']')
				if not ChartManager.chart:
					printerr("No chart is currenty loaded! Can't load events")
					export_window.hide()
					return
				
				var events_data = load(path)
				if events_data is not ChartEvents:
					printerr("Provided resource was not a chart event file!")
				
				ChartManager.chart.merge_events_into_this(events_data)
				chart_editor.load_section(chart_editor.song_position)
				export_window.hide()
			
			var on_close = func():
				export_window.queue_free()
			
			export_window.connect(&"file_selected", chart_editor.on_open)
			export_window.connect(&"close_requested", chart_editor.close_popup)
			export_window.connect(&"close_requested", on_close)

		_:
			print("id: ", id)

func open_open_file_window():
	chart_editor.can_chart = false
	var open_file_popup_instance = chart_editor.OPEN_FILE_POPUP_PRELOAD.instantiate()
	
	add_child(open_file_popup_instance)
	open_file_popup_instance.popup()
	open_file_popup_instance.connect("file_selected", chart_editor.load_song_path)
	open_file_popup_instance.connect("close_requested", chart_editor.close_popup)
	open_file_popup_instance.connect("canceled", chart_editor.close_popup)
	SoundManager.tool_open_window.play()
