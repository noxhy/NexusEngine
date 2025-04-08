extends Window

signal file_created(path: String, song: Song)

var selected_vocals: PackedStringArray
var selected_instrumental: String

# Creates a new file that will send out a signal to the chart editor
func new_file(dir: String):
	
	# Creates the file base properties
	var song_file = Song.new()
	song_file.artist = %"Song Credits".text
	song_file.title = %"Song Title".text
	song_file.tempo = %"Starting Tempo".value
	
	song_file.instrumental = load(selected_instrumental)
	var streams: Array[AudioStream] = []
	for stream in selected_vocals: streams.append(load(stream))
	song_file.vocals = streams
	
	var difficulty: String = %"Starting Difficulty".text
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
	var difficulty_dict: Dictionary[String, Dictionary] = {difficulty: {"chart": chart_path}}
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

# "Create New File" button pressed
func _on_save_button_pressed(): %SaveFolderDialog.popup()

# When the directory of the folder the chart will save in is selected
func _on_save_folder_dialog_dir_selected(dir):
	
	new_file(dir)
	_on_close_requested()

func _on_close_requested(): self.queue_free()
