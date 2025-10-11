extends Window

signal file_created(path: String, song: Song)

var selected_vocals: PackedStringArray
var selected_instrumental: String
var save_dir: String

# Creates a new file that will send out a signal to the chart editor
func new_file(dir: String):
	
	# Creates the file base properties
	var song_file = Song.new()
	song_file.artist = %"Song Credits".text
	song_file.title = %"Song Title".text
	song_file.tempo = %"Starting Tempo".value
	
	song_file.instrumental = selected_instrumental
	var streams: Array[String] = []
	for stream in selected_vocals:
		streams.append(stream)
	song_file.vocals = streams
	
	var difficulties: Array[String] = []
	
	var selected = %"Difficulty Options".get_selected_items()[0]
	if selected == 0:
		difficulties = ["easy", "normal", "hard"]
	elif selected == 1:
		difficulties = ["erect", "nightmare"]
	else:
		difficulties = []
	
	var difficulty_dict: Dictionary[String, Dictionary] = {}
	
	for difficulty in difficulties:
		
		var chart: Chart = Chart.new()
		
		# Barebones chart data
		chart.chart_data = {
			
			"notes": [],
			"events": [],
			"tempos": {0.0: song_file.tempo},
			"meters": {0.0: [4, 16]},
			
		}
		
		var chart_path: String = dir + "/" + song_file.title + "-" + difficulty + ".res"
		ResourceSaver.save(chart, chart_path)
		difficulty_dict[difficulty] = {"chart": chart_path}
	
	song_file.difficulties = difficulty_dict
	var song_path: String = dir + "/" + song_file.title + ".res"
	ResourceSaver.save(song_file, song_path)
	
	# Emits signal to return to the chart editor
	emit_signal("file_created", song_path, song_file)


# "Select File Location" button pressed
func _on_vocals_button_pressed(): %"Vocals File Dialog".popup()

# "Select File Location" button pressed
func _on_inst_button_pressed(): %"Inst File Dialog".popup()

# When the vocals file is selected
func _on_vocals_file_dialog_files_selected(paths: PackedStringArray) -> void:
	
	selected_vocals = paths
	%"Vocals File Location".text = str(selected_vocals)

# When the Inst file is selected
func _on_inst_file_dialog_file_selected(path):
	
	selected_instrumental = path
	%"Inst File Location".text = selected_instrumental

# When the directory of the folder the chart will save in is selected
func _on_save_folder_dialog_dir_selected(dir):
	save_dir = dir
	%"Export File Location".text = dir

func _on_close_requested(): self.queue_free()

# "Select File Location" button pressed
func _on_export_button_pressed() -> void:
	%SaveFolderDialog.popup()

# "Create New Song" button pressed
func _on_create_button_pressed() -> void:
	
	if %"Difficulty Options".get_selected_items().size() == 0:
		printerr("Difficulties not selected")
		return
	
	if !FileAccess.file_exists(selected_instrumental):
		printerr("Instrumental file does not exist")
		return
	
	if !DirAccess.dir_exists_absolute(save_dir):
		printerr("Save Directory does not exist")
		return
	
	new_file(save_dir)
	_on_close_requested()
