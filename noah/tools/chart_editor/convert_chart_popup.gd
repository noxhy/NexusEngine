extends Window

signal file_created(path: String, song: Song)

var selected_vocals: PackedStringArray
var selected_instrumental: String
var files_to_save: PackedStringArray

func _ready() -> void:
	pass

# Creates a new file that will send out a signal to the chart editor
func new_file(files: Array[String]):
	# Creates the file base properties
	var song_file = Song.new()
	
	song_file.artist = %"Song Credits".text
	song_file.title = %"Song Title".text
	
	song_file.instrumental = selected_instrumental
	song_file.vocals = Array(Array(selected_vocals),TYPE_STRING, '', null)
	
	var chart_format = %"Format Options".get_selected_id()
	
	var difficulty_dict: Dictionary[String, Dictionary] = {}
	
	var save_chart = func(chart:Chart, dir:String, diff:String):
		song_file.tempo = chart.get_tempos_data().get(chart.get_tempos_data().keys()[0])
		
		var path = dir + song_file.title + '-' + diff + '.tres'
		
		ResourceSaver.save(chart, path)
		difficulty_dict[diff] = {"chart": path}
	
	var charts:Array[String] = files.duplicate()
	match chart_format:
		999: # whatever.
			#filter out all metas or events
			charts = charts.filter(func (file:String): 
				var is_events_json = file.ends_with('events.json')
				var is_cne_meta = file.substr(file.get_base_dir().length() + 1).begins_with('meta')
				var is_vslice_meta = file.contains('-metadata')
				
				return not is_events_json and not is_cne_meta and not is_vslice_meta
			)
			
			if not charts.is_empty():
				var chart_path = charts[0]
				
				chart_format = Chart.resolve_chart_type(JSON.parse_string(FileAccess.open(chart_path,FileAccess.READ).get_as_text()))
			
		Chart.ChartFormat.CODENAME:
			charts = charts.filter(func (file:String): 
				file = file.substr(file.get_base_dir().length() + 1)
				return not file.begins_with('meta')
			)
		Chart.ChartFormat.PSYCH, Chart.ChartFormat.PSYCH_V1:
			charts = charts.filter(func (file:String): 
				return not file.ends_with('events.json')
			)
		Chart.ChartFormat.VSLICE:
			charts = charts.filter(func (file:String): 
				return file.contains('-chart')
			)
	
	print(charts)
	
	if charts.is_empty():
		printerr("failed to find any charts")
	
	var core_directory = charts[0].get_base_dir() + '/'
	
	for file in charts:
		
		match chart_format:
			Chart.ChartFormat.VSLICE:
				var dir = file.get_base_dir()
				
				var meta_file = file.substr(dir.length())
				meta_file = dir + meta_file.replace('chart', 'metadata')
				
				assert(FileAccess.file_exists(meta_file), str('Failed to find metadata at: ', meta_file))
				
				var raw_meta = FileAccess.open(meta_file, FileAccess.READ)
				var meta_json = JSON.parse_string(raw_meta.get_as_text())
				
				var raw_file = FileAccess.open(file,FileAccess.READ)
				var chart_json = JSON.parse_string(raw_file.get_as_text())
				
				if chart_json and meta_json:
					for diff in meta_json.get('playData').get('difficulties'):
						save_chart.call(Chart.convert_vslice(chart_json, meta_json, diff), core_directory, diff)
				
				
			Chart.ChartFormat.CODENAME:
				
				var meta_file = files.filter(func (input:String): 
					return input.substr(input.get_base_dir().length() + 1).begins_with('meta')
				)
				
				assert(!meta_file.is_empty(), "failed to find cne meta")
				
				var events = []
				var events_file = FileAccess.open(file.get_base_dir() + '/events.json', FileAccess.READ)
				
				if events_file:
					var events_json = JSON.parse_string(events_file.get_as_text())
					if events_json:
						if events_json is Dictionary:
							if events_json.has('events'):
								events = events_json.get('events')
				
				var raw_meta = FileAccess.open(meta_file[0], FileAccess.READ)
				
				var raw_file = FileAccess.open(file,FileAccess.READ)
				if raw_file:
					var assumed_diff = file.substr(file.get_base_dir().length() + 1)
					assumed_diff = assumed_diff.substr(0,assumed_diff.length() - (assumed_diff.get_extension().length() + 1))
					
					var chart = Chart.convert_cne(JSON.parse_string(raw_file.get_as_text()), JSON.parse_string(raw_meta.get_as_text()), events)
					save_chart.call(chart, core_directory, assumed_diff)
				
			Chart.ChartFormat.PSYCH_V1, Chart.ChartFormat.PSYCH:
				
				var raw_file = FileAccess.open(file,FileAccess.READ)
				if raw_file:
					var events = []
					var events_files = files.filter(func (input:String): return input.ends_with('events.json'))
					if not events_files.is_empty():
						var raw_events = FileAccess.open(events_files[0], FileAccess.READ)
						var events_json = JSON.parse_string(raw_events.get_as_text())
						if not events_json.has('events'):
							events_json = events_json.get('song')
						
						events = events_json.get('events', [])
					
					var split_name = file.substr(file.get_base_dir().length() + 1).split('-')
					var assumed_diff:String = 'normal'
					
					if split_name.size() > 1:
						assumed_diff = split_name[split_name.size() - 1]
						assumed_diff = assumed_diff.substr(0,assumed_diff.length() - 5)
					
					var chart = Chart.convert_psych(JSON.parse_string(raw_file.get_as_text()), events, chart_format == Chart.ChartFormat.PSYCH_V1)
					
					save_chart.call(chart, core_directory, assumed_diff)
					
	
	
	song_file.difficulties = difficulty_dict
	var song_path: String = core_directory + song_file.title + '.res'
	ResourceSaver.save(song_file, song_path)
	
	#Emits signal to return to the chart editor
	emit_signal("file_created", song_path, song_file)

# "Select File Location" button pressed
func _on_vocals_button_pressed(): %"Vocals File Dialog".popup()

# "Select File Location" button pressed
func _on_inst_button_pressed(): %"Inst File Dialog".popup()

# When the vocals file is selected 
func _on_vocals_file_dialog_files_selected(paths: PackedStringArray) -> void:
	selected_vocals = paths
	%"Vocals File Location".text = str(paths)

# When the Inst file is selected
func _on_inst_file_dialog_file_selected(path):
	selected_instrumental = path
	%"Inst File Location".text = path

# "Create New File" button pressed
func _on_export_file_button_pressed():
	%SaveFolderDialog.popup()

# "Select File Location" button pressed
func _on_chart_button_pressed(): %"Chart File Dialog".popup()

func _on_close_requested(): self.queue_free()

func _on_create_button_pressed() -> void:
	
	if !FileAccess.file_exists(selected_instrumental):
		printerr("No instrumental file found")
	
	if files_to_save.is_empty():
		printerr("No files selected")
		return
	
	new_file(files_to_save)
	self.queue_free()

func file_dailog_gui_focus_changed(node: Control) -> void:
	emit_signal(&"gui_focus_changed", node)


func _on_save_folder_dialog_files_selected(paths: PackedStringArray) -> void:
	files_to_save = paths
	%"Export File Location".text = ', '.join(files_to_save)
