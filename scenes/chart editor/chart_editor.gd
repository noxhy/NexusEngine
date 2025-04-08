extends Node2D

const LABEL_FONT: Font = preload("res://assets/fonts/Bold Normal Text.ttf")
const NOTE_PRELOAD = preload("res://scenes/instances/playstate/note/note.tscn")
const NOTE_SKIN = preload("res://assets/sprites/playstate/developer/developer_note_skin.tres")
const STRUM_BUTTON_PRELOAD = preload("res://scenes/instances/chart editor/strum_button.tscn")

const NEW_FILE_POPUP_PRELOAD = preload("res://scenes/instances/chart editor/new_file_popup.tscn")
const OPEN_FILE_POPUP_PRELOAD = preload("res://scenes/instances/chart editor/open_file_popup.tscn")
const CONVERT_CHART_POPUP_PRELOAD = preload("res://scenes/instances/chart editor/convert_chart_popup.tscn")

const WAVEFORM_PRELOAD = preload("res://addons/audio_preview/AudioStreamPreview.tscn")

const SNAPS = [4.0, 8.0, 12.0, 16.0, 20.0, 24.0, 32.0, 48.0, 64.0, 96.0, 192.0]

@onready var undo_redo: UndoRedo = UndoRedo.new()

@export var song_data: Song = null

@export_group("Colors")
@export var hover_color: Color = Color(1, 1, 1, 0.5)
@export var divider_color: Color = Color(1, 1, 1, 0.5)
@export var current_time_color: Color = Color(1, 0, 0, 1)
@export var muted_color: Color = Color(0.8, 0.8, 0.8, 0.5)
@export var box_color: Color = Color.LIGHT_GREEN
@export var selected_color: Color = Color.GREEN

## Chart Variables
var chart: Chart = null
# So it turns out that the track ID's are not sequential and can be whatever number they want, I did this so it'd be easier
var vocal_tracks: Array = []
var scene: String

## Editor Variables
var song_position: float = 0.0
var start_offset: float = 0.0
var song_speed: float = 1.0
var current_tempo: float = 60.0
var current_beats_per_measure: int = 4
var current_steps_per_measure: int = 16
var current_difficulty: String
var note_list: Array = []
var waveform_list: Array = []
var can_chart: bool = false

var current_snap: int = 3
var chart_snap: float = SNAPS[current_snap]

var selected_notes: Array = []
var selected_note_nodes: Array = []
var placing_note: bool = false
var changed_length: bool = false
var current_note: int = -1
var start_box: Vector2 = Vector2.ZERO
var bounding_box: bool = false
var moving_notes: bool = false
var start_lane: int = 0
var start_time: float = 0.0
var min_lane: int = 0
var max_lane: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	Global.set_window_title("Chart Editor")
	song_speed = 1.0
	
	if ChartHandeler.song != null:
		
		var old_song = null
		var song = ChartHandeler.song
		load_song(song, ChartHandeler.difficulty)
		var action: String = "Loaded Song"
		undo_redo.create_action(action)
		undo_redo.add_do_property(self, "song", song)
		undo_redo.add_do_reference(%"History Window".add_action(action))
		undo_redo.add_undo_property(self, "song", old_song)
		undo_redo.commit_action()
		can_chart = true
	else: Global.change_scene_to("res://scenes/main menu/main_menu.tscn")
	update_grid()
	
	%"Chart Snap".value = chart_snap
	
	## Initializing Popup Signals
	
	%"File Button".get_popup().connect("id_pressed", self.file_button_item_pressed)
	%"File Button".get_popup().set_item_checked(5, SettingsHandeler.get_setting("autosave"))
	%"File Button".get_popup().set_hide_on_checkable_item_selection(false)
	
	%"Edit Button".get_popup().connect("id_pressed", self.edit_button_item_pressed)
	%"Edit Button".get_popup().set_hide_on_checkable_item_selection(false)
	
	%"Window Button".get_popup().connect("id_pressed", self.window_button_item_pressed)
	%"Window Button".get_popup().set_hide_on_checkable_item_selection(false)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if start_offset < 0: start_offset = 0
	
	if song_data != null:
		
		if %Instrumental.playing:
			
			song_position = %Instrumental.get_playback_position() - start_offset
			%"Song Slider".value = song_position
			
			var notes_list = chart.get_notes_data()
			
			if notes_list.size() > 0:
				
				if current_note < notes_list.size():
					
					var note = notes_list[current_note]
					
					if note[0] <= (song_position + start_offset):
						
						var time: float = note[0]
						var lane: float = note[1]
						
						for strum in ChartHandeler.strum_data:
							
							if ((lane >= ChartHandeler.strum_data[strum]["strums"][0]) and (lane <= ChartHandeler.strum_data[strum]["strums"][1])):
								
								if (!ChartHandeler.strum_data[strum]["muted"]): %"Hit Sound".play()
						
						current_note += 1
			
			for strum in ChartHandeler.strum_data:
				
				var track = ChartHandeler.strum_data[strum]["track"]
				
				if track < vocal_tracks.size():
					
					if ChartHandeler.strum_data[strum]["muted"]:
						
						%Vocals.get_stream_playback().set_stream_volume(vocal_tracks[track], -80)
					else:
						
						%Vocals.get_stream_playback().set_stream_volume(vocal_tracks[track], 0)
			
		else:
			
			if Input.is_action_just_pressed("mouse_scroll_up"):
				
				if !Input.is_action_pressed("control"):
					
					if can_chart:
						
						song_position -= $Conductor.seconds_per_beat
						song_position = snapped(song_position, $Conductor.seconds_per_beat)
						song_position = clamp(song_position, start_offset, %Instrumental.stream.get_length())
				else:
					
					current_snap += 1
					chart_snap = SNAPS[current_snap % SNAPS.size()]
					%"Chart Snap".value = chart_snap
			
			if Input.is_action_just_pressed("mouse_scroll_down"):
				
				if !Input.is_action_pressed("control"):
					
					if can_chart:
						
						song_position += $Conductor.seconds_per_beat
						song_position = snapped(song_position, $Conductor.seconds_per_beat)
						song_position = clamp(song_position, start_offset, %Instrumental.stream.get_length())
				else:
					
					current_snap -= 1
					chart_snap = SNAPS[current_snap % SNAPS.size()]
					%"Chart Snap".value = chart_snap
		
		if chart != null:
			
			if Input.is_action_pressed("control") and Input.is_action_just_pressed("save"):
				
				ResourceSaver.save(song_data, song_data.resource_path)
				ResourceSaver.save(chart, chart.resource_path)
	
	if chart != null:
		
		current_tempo = chart.get_tempo_at(song_position + start_offset)
		$Conductor.tempo = current_tempo
		var meter = chart.get_meter_at(song_position + start_offset)
		current_beats_per_measure = meter[0]
		current_steps_per_measure = meter[1]
		$Camera2D.position.y = 360 + time_to_y_position(song_position)
		
		if Input.is_action_pressed("control") and Input.is_action_just_pressed("undo"): undo()
		if Input.is_action_pressed("control") and Input.is_action_just_pressed("redo"): redo()
	
	%"Current Time Label".text = float_to_time(song_position + start_offset)
	%"Time Left Label".text = "-" + float_to_time(int(%Instrumental.stream.get_length() - song_position) * 1.0)
	
	if Input.is_action_just_pressed("ui_accept"): _on_play_button_toggled(!%Instrumental.stream_paused)
	
	var measure_height = %Grid/TextureRect.size.y * %Grid/TextureRect.scale.y
	var grid_offset: Vector2 = %Grid.position + $"Grid Layer".offset
	var mouse_position: Vector2 = get_global_mouse_position() - grid_offset
	var grid_position: Vector2 = %Grid.get_grid_position(mouse_position)
	var snapped_position: Vector2i = Vector2i(%Grid.get_grid_position(mouse_position, %Grid.grid_size * Vector2(1, current_steps_per_measure / chart_snap)))
	
	var screen_mouse_position = get_global_mouse_position() - Vector2(0, $Camera2D.position.y - 360)
	
	
	if Input.is_action_just_pressed("mouse_left"):
		
		if !Input.is_action_pressed("control"):
			
			if screen_mouse_position.y > 64 and screen_mouse_position.y < 640:
				
				if can_chart:
					
					if !Input.is_action_pressed("control"):
						
						if ((grid_position.x - 1) > 0 and (grid_position.x - 1) < ChartHandeler.strum_count):
							
							var lane: int = snapped_position.x - 1
							var time: float = grid_position_to_time(snapped_position, true)
							
							if !is_note_at(lane, Vector2i(snapped_position).y / chart_snap * $Conductor.seconds_per_beat * current_steps_per_measure / current_beats_per_measure):
								
								var action: String = "Add Note"
								undo_redo.create_action(action)
								undo_redo.add_do_method(self.place_note.bind(time, lane, 0, 0, true))
								undo_redo.add_do_reference(%"History Window".add_action(action))
								undo_redo.add_undo_method(self.remove_note.bind(lane, time))
								undo_redo.commit_action()
								%"Note Place".play()
								placing_note = true
							
							else:
								
								var i: int = find_note(lane, time)
								if selected_notes.has(i):
									
									moving_notes = true
									start_lane = lane
									start_time = time
									
									var k: int = 0
									for j in selected_notes:
										
										chart.chart_data["notes"].remove_at(j - k)
										k += 1
								
								else:
									
									selected_notes = [find_note(lane, time)]
									selected_note_nodes = [selected_notes[0]]
		
		else:
			
			bounding_box = true
			start_box = get_global_mouse_position()
	
	if Input.is_action_pressed("mouse_right"):
		
		if !Input.is_action_pressed("control"):
				
				if screen_mouse_position.y > 64 and screen_mouse_position.y < 640:
					
					if can_chart:
						
						if !Input.is_action_pressed("control"):
							
							var lane: int = snapped_position.x - 1
							var time: float = grid_position_to_time(snapped_position, true)
							
							if is_note_at(lane, time):
								
								var i: int = find_note(lane, time)
								var note = chart.get_notes_data()[i]
								var length: float = note[2]
								var note_type: int = note[3]
								
								var action: String = "Remove Note"
								undo_redo.create_action(action)
								undo_redo.add_do_method(self.remove_note.bind(lane, time))
								undo_redo.add_do_reference(%"History Window".add_action(action))
								undo_redo.add_undo_method(self.place_note.bind(time, lane, length, note_type, true))
								undo_redo.commit_action()
								
								%"Note Remove".play()
								
								selected_notes.erase(i)
								var j: int = 0
								for k in selected_notes:
									
									if k > i:
										selected_notes[j] = k - 1
									j += 1
								
								if SettingsHandeler.get_setting("autosave"): ResourceSaver.save(chart, chart.resource_path)
	
	if Input.is_action_pressed("mouse_left"):
		
		if !Input.is_action_pressed("control"):
			
			if screen_mouse_position.y > 64 and screen_mouse_position.y < 640:
				
				if !%Instrumental.playing:
					
					if can_chart:
						
						## Song Position Slider
						if int(grid_position.x) == 0:
							start_offset = grid_position_to_time(grid_position) - song_position
						
						if ((grid_position.x - 1) > 0 and (grid_position.x - 1) < ChartHandeler.strum_count):
							
							if placing_note:
								
								var cursor_time = grid_position_to_time(snapped_position, true)
								
								for i in selected_notes:
									
									var note: Array = chart.get_notes_data()[i]
									
									var time: float = note[0]
									var lane: int = note[1]
									var note_type: int = note[3]
									
									var distance = snappedf(clamp(cursor_time - time, 0.0, 16.0) / $Conductor.seconds_per_beat, 1.0 / chart_snap)
									chart.chart_data.notes[i] = [time, lane, distance, note_type]
									
									changed_length = (distance > 0)
									if changed_length:
										
										if (note_list[i].length != distance): %"Note Stretch".play()
										note_list[i].length = distance
									
									if SettingsHandeler.get_setting("autosave"): 
										ResourceSaver.save(chart, chart.resource_path)
						
						if ((grid_position.x - 1) > 0 and (grid_position.x - 1) < ChartHandeler.strum_count):
							
							if moving_notes:
								
								var cursor_time = grid_position_to_time(snapped_position, true)
								var cursor_lane = snapped_position.x - 1
								
								var lane_distance = cursor_lane - start_lane
								var time_distance = cursor_time - start_time
								changed_length = (abs(lane_distance) > 0 or abs(time_distance) > 0)
								
								print("min lane: ", min_lane)
								print("max lane: ", max_lane)
								
								var diff: int = max_lane - min_lane
								
								if ((min_lane + lane_distance) >= 0 and (max_lane + lane_distance) < ChartHandeler.strum_count):
									
									if changed_length:
										
										var temp: Array = selected_notes
										selected_notes = []
										
										var j: int = 0
										for i in temp:
											
											var note: Array = chart.get_notes_data()[i]
											
											var time: float = note[0]
											var lane: int = note[1]
											var length: float = note[2]
											var note_type: int = note[3]
											
											var node = selected_note_nodes[j]
											
											node.time += time_distance
											node.lane += lane_distance
											node.position = Vector2(%Grid.get_real_position(Vector2(1.5 + node.lane, 0)).x, time_to_y_position(node.time) + %Grid.grid_size.y * %Grid.zoom.y / 2)
											j += 1
										
										if SettingsHandeler.get_setting("autosave"): 
											ResourceSaver.save(chart, chart.resource_path)
										
										start_time += time_distance
										start_lane += lane_distance
										min_lane += lane_distance
										max_lane = min_lane + diff
	
	if Input.is_action_just_released("mouse_left"):
		
		if placing_note:
			
			if changed_length:
				
				var action: String = "Changed Note Length(s)"
				undo_redo.create_action(action)
				for i in selected_notes:
					
					undo_redo.add_do_property(note_list[i], "length", note_list[i].length)
					undo_redo.add_undo_property(note_list[i], "length", 0.0)
				
				undo_redo.add_do_reference(%"History Window".add_action(action))
				undo_redo.commit_action()
			
			placing_note = false
			changed_length = false
		
		if bounding_box:
			
			bounding_box = false
			
			var rect = Rect2(start_box, get_global_mouse_position() - start_box).abs()
			# Added leniency since notes are centered from the top
			var pos_1: Vector2 = %Grid.get_grid_position(rect.position - grid_offset) - Vector2(1, 0.5)
			var pos_2: Vector2 = %Grid.get_grid_position(rect.end - grid_offset) - Vector2(1, 0.5)
			var time_a: float = grid_position_to_time(pos_1, true)
			var time_b: float = grid_position_to_time(pos_2, true)
			
			var L: int = bsearch_left_range(chart.get_notes_data(), chart.get_notes_data().size(), time_a)
			var R: int = bsearch_right_range(chart.get_notes_data(), chart.get_notes_data().size(), time_b)
			
			if (L == R + 1): L -= 1
			selected_notes = range(L, R + 1)
			selected_note_nodes = []
			for i in selected_notes: selected_note_nodes.append(note_list[i])
			
			var j: int = 0
			min_lane = ChartHandeler.strum_count
			max_lane = 0
			for i in range(selected_notes.size()):
				
				i -= j
				var lane: int = int(chart.get_notes_data()[selected_notes[i]][1])
				if !(range(int(pos_1.x), int(pos_2.x) + 1).has(lane)):
					
					selected_notes.erase(selected_notes[i])
					j += 1
				else:
					
					if lane < min_lane: min_lane = lane
					if lane > max_lane: max_lane = lane
			
			print("bounds set: ", min_lane, " - ", max_lane)
			
			if selected_notes.size() > 0:
				%"Note Place".play()
		
		if moving_notes:
			
			for note in selected_note_nodes:
				
				place_note(note.time, note.lane, note.length, note.note_type, true)
				note.queue_free()
			
			moving_notes = false
			%"Note Place".play()
	
	
	if Input.is_action_just_released("control"): bounding_box = false
	
	
	if Input.is_action_pressed("ui_text_delete"):
		
		GameHandeler.play_mode = GameHandeler.PLAY_MODE.CHARTING
		GameHandeler.difficulty = current_difficulty
		Global.change_scene_to("res://scenes/playstate/chart_tester.tscn")
	
	queue_redraw()


func _draw() -> void:
	
	var rect: Rect2
	
	## Box when you're holding control
	if bounding_box:
		
		rect = Rect2(start_box, get_global_mouse_position() - start_box).abs()
		draw_rect(rect, box_color)
	
	if chart != null:
		
		## The offset the grid has from the normal canvas layer
		var grid_offset: Vector2 = %Grid.position + $"Grid Layer".offset
		var mouse_position: Vector2 = get_global_mouse_position() - grid_offset
		var grid_position: Vector2i = Vector2i(%Grid.get_grid_position(mouse_position))
		var snapped_position: Vector2i = Vector2i(%Grid.get_grid_position(mouse_position, %Grid.grid_size * Vector2(1, current_steps_per_measure / chart_snap)))
		
		var measure_height = %Grid/TextureRect.size.y * %Grid/TextureRect.scale.y
		
		## Song Start Offset Marker
		var time_to_y: Vector2
		rect = Rect2(grid_offset + %Grid.get_real_position(Vector2(1, 0)) + Vector2(0, time_to_y_position(song_position + start_offset) - 2), \
		%Grid.get_real_position(Vector2(%Grid.columns, 0)) - %Grid.get_real_position(Vector2(1, 0)) + Vector2(0, 4))
		draw_rect(rect, current_time_color)
		# The box at the end of the marker
		rect = Rect2(grid_offset + %Grid.get_real_position(Vector2(0, 0)) + Vector2(0, time_to_y_position(song_position + start_offset) - 4), \
		%Grid.get_real_position(Vector2(1, 0)) - %Grid.get_real_position(Vector2(0, 0)) + Vector2(0, 8))
		draw_rect(rect, current_time_color)
		
		## Hover Box
		if (grid_position.x >= 0 and grid_position.x < %Grid.columns):
			
			rect = Rect2(%Grid.get_real_position(snapped_position, %Grid.grid_size * Vector2(1, current_steps_per_measure / chart_snap)) + grid_offset, \
			%Grid.grid_size * %Grid.zoom * Vector2(1, current_steps_per_measure / chart_snap))
			draw_rect(rect, hover_color)
		
		## Measure Markers
		var current_beat = $Conductor.get_beat_at(song_position)
		var current_step = $Conductor.get_step_at(song_position)
		var seconds_per_step = ($Conductor.seconds_per_beat * 1.0 / ($Conductor.steps_per_measure * 1.0 / $Conductor.beats_per_measure))
		
		for row in range(current_steps_per_measure * 2):
			
			var time_at_row: float = (current_step + row) * seconds_per_step
			var step_at_row: int = $Conductor.get_step_at(time_at_row)
			time_to_y = Vector2(0, time_to_y_position(time_at_row))
			
			if ((current_step + row) % current_beats_per_measure) == 0:
				
				var size: float = 4.0 if (step_at_row % current_steps_per_measure / current_beats_per_measure) == 0 else 2.0
				rect = Rect2(grid_offset + %Grid.get_real_position(Vector2(0, 0)) + Vector2(0, time_to_y.y - (size / 2)), \
				%Grid.get_real_position(Vector2(%Grid.columns + 1, 0)) - %Grid.get_real_position(Vector2(1, 0)) + Vector2(0, size))
				draw_rect(rect, divider_color)
				
				draw_string(LABEL_FONT, \
				grid_offset + %Grid.get_real_position(Vector2(0, 0)) + Vector2(0, time_to_y.y + 16), \
				str($Conductor.get_beat_at(time_at_row) + 1), HORIZONTAL_ALIGNMENT_LEFT, %Grid.grid_size.x * %Grid.zoom.x, 16)
		
		var time_at_row = current_step * seconds_per_step
		time_to_y = %Grid.get_grid_position(Vector2(0, time_to_y_position(time_at_row)))
		
		## Events Divider
		rect = Rect2(grid_offset + %Grid.get_real_position(Vector2(1, time_to_y.y)) - Vector2(2, 2), \
		%Grid.get_real_position(Vector2(0, %Grid.rows * 2)) - %Grid.get_real_position(Vector2(0, 0)) + Vector2(4, 2))
		draw_rect(rect, divider_color)
		
		## Position Divider
		rect = Rect2(grid_offset + %Grid.get_real_position(Vector2(%Grid.columns - 1, time_to_y.y)) - Vector2(2, 2), \
		%Grid.get_real_position(Vector2(0, %Grid.rows * 2)) - %Grid.get_real_position(Vector2(0, 0)) + Vector2(4, 2))
		draw_rect(rect, divider_color)
		
		## Strum Markers
		for strum_name in ChartHandeler.strum_data:
			
			var start_strum = ChartHandeler.strum_data[strum_name]["strums"][0]
			var end_strum = ChartHandeler.strum_data[strum_name]["strums"][1]
			
			## Measure Divider
			rect = Rect2(grid_offset + %Grid.get_real_position(Vector2(end_strum + 2, time_to_y.y)) - Vector2(1, 2), \
			%Grid.get_real_position(Vector2(0, %Grid.rows * 2)) - %Grid.get_real_position(Vector2(0, 0)) + Vector2(2, 2))
			draw_rect(rect, divider_color)
			
			if ChartHandeler.strum_data[strum_name]["muted"]:
				
				rect = Rect2(grid_offset + %Grid.get_real_position(Vector2(start_strum + 1, time_to_y.y)), \
				%Grid.get_real_position(Vector2(end_strum - start_strum + 1, %Grid.rows * 2)) - %Grid.get_real_position(Vector2(0, 0)))
				draw_rect(rect, muted_color)
		
		## Note Highlighting
		for index in selected_notes:
			
			var note = note_list[index]
			var length: float = note.length + ($Conductor.beats_per_measure * 1.0 / $Conductor.steps_per_measure)
			length *= %Grid.grid_size.y * %Grid.zoom.y
			length *= ($Conductor.steps_per_measure * 1.0 / $Conductor.beats_per_measure)
			rect = Rect2(note.global_position + grid_offset - (%Grid.grid_size / 2), Vector2(%Grid.grid_size.x, length))
			draw_rect(rect, selected_color)


func update_grid():
	
	%Grid.columns = 2 + ChartHandeler.strum_count
	%Grid.rows = current_steps_per_measure
	%"Strum Labels".position = %Grid.get_real_position(Vector2(1, -1)) - Vector2(2, 296)
	%"Strum Labels".custom_minimum_size.x = ChartHandeler.strum_count * %Grid.grid_size.x * %Grid.zoom.x + 4
	
	for n in %"Strum Labels".get_children(): n.queue_free()
	
	for n in waveform_list: n.queue_free()
	waveform_list = []
	
	for id in ChartHandeler.strum_data:
		
		var strum_label_instance = STRUM_BUTTON_PRELOAD.instantiate()
		
		strum_label_instance.id = id
		strum_label_instance.muted = ChartHandeler.strum_data[id]["muted"]
		
		%"Strum Labels".add_child(strum_label_instance)
		strum_label_instance.custom_minimum_size.x = (ChartHandeler.strum_data[id]["strums"][1] + 1 - ChartHandeler.strum_data[id]["strums"][0]) * %Grid.grid_size.x * %Grid.zoom.x
		strum_label_instance.size.y = 32
		
		if ChartHandeler.strum_data[id]["strums"][0] == 0: strum_label_instance.get_node("Move Lane Left").visible = false
		if ChartHandeler.strum_data[id]["strums"][1] == ChartHandeler.strum_count - 1: strum_label_instance.get_node("Move Lane Right").visible = false
		
		var waveform_instance = WAVEFORM_PRELOAD.instantiate()
		
		waveform_instance.position = %Grid.get_real_position(Vector2(ChartHandeler.strum_data[id]["strums"][1] + 2, 0))
		waveform_instance.size.y = (ChartHandeler.strum_data[id]["strums"][1] + 1 - ChartHandeler.strum_data[id]["strums"][0]) * %Grid.grid_size.x * %Grid.zoom.x
		waveform_instance.rotation_degrees = 90
		
		var track: int = ChartHandeler.strum_data[id]["track"]
		if track < song_data.vocals.size():
			
			var stream = song_data.vocals[track]
			if stream is AudioStreamWAV:
				
				waveform_instance.stream_path = stream.resource_path
				print(stream.resource_path)
		
		waveform_list.append(waveform_instance)
		$"Waveform Layer".add_child(waveform_instance)
		
		strum_label_instance.connect("move_bound_left", self.move_bound_left)
		strum_label_instance.connect("move_bound_right", self.move_bound_right)
		strum_label_instance.connect("opened", self.disable_charting)
		strum_label_instance.connect("closed", self.close_popup)
		strum_label_instance.connect("updated", self.updated_strums)
	
	%"Strum Labels".size.y = 32
	update_waveforms()


func update_waveforms():
	
	var i: int = 0
	for n in waveform_list:
		
		var id: String = ChartHandeler.strum_data.keys()[i]
		n.size.y = (ChartHandeler.strum_data[id]["strums"][1] + 1 - ChartHandeler.strum_data[id]["strums"][0]) * %Grid.grid_size.x * %Grid.zoom.x
		n.size.x = time_to_y_position(song_data.instrumental.get_length()) - time_to_y_position(0.0)
		i += 1


func load_song(song: Song, difficulty: Variant = null):
	
	ChartHandeler.song = song
	song_data = song
	if difficulty == null: difficulty = song_data.difficulties.keys()[0]
	current_difficulty = difficulty
	var difficulty_data: Dictionary = song.difficulties.get(difficulty)
	chart = load(difficulty_data.chart)
	scene = song.scene if !difficulty_data.has("scene") else difficulty_data.scene
	ChartHandeler.difficulty = difficulty
	undo_redo.clear_history()
	play_audios(0.0)
	
	%"Song Slider".max_value = %Instrumental.stream.get_length()
	%"Song Slider".value = 0.0
	current_tempo = chart.get_tempo_at(0.0)
	var meter = chart.get_meter_at(0.0)
	current_beats_per_measure = meter[0]
	current_steps_per_measure = meter[1]
	$Conductor.offset = chart.offset
	
	%"Difficulty Button".get_popup().clear()
	for d in song_data.difficulties.keys():
		
		%"Difficulty Button".get_popup().add_item(d)
	
	%"Difficulty Button".select(song_data.difficulties.keys().find(difficulty))
	
	load_chart(chart)
	can_chart = true


func load_song_path(path: String, difficulty: Variant = null):
	
	var old_song = self.song_data
	var song = load(path)
	load_song(song, difficulty)
	var action: String = "Loaded Song"
	undo_redo.create_action(action)
	undo_redo.add_do_property(self, "song", song)
	undo_redo.add_do_reference(%"History Window".add_action(action))
	undo_redo.add_undo_property(self, "song", old_song)
	undo_redo.commit_action()
	can_chart = true


func load_chart(file: Chart, ghost: bool = false):
	
	if !ghost:
		
		for n in note_list: n.queue_free()
		note_list = []
	
	for note in file.get_notes_data():
		
		place_note(note[0], note[1], note[2], note[3])
		selected_notes = []


func new_file(path: String, song: Song):
	
	var old_song = self.song_data
	load_song(song)
	var action: String = "Created New Song"
	undo_redo.create_action(action)
	undo_redo.add_do_property(self, "song", song)
	undo_redo.add_do_reference(%"History Window".add_action(action))
	undo_redo.add_undo_property(self, "song", old_song)
	undo_redo.commit_action()
	can_chart = true

## Adds an instance of a note on the chart editor, placed boolean adds it to the chart data.
func place_note(time: float, lane: int, length: float, type: int, placed: bool = false, moved: bool = false):
	
	var directions = ["left", "down", "up", "right"]
	
	var note_instance = NOTE_PRELOAD.instantiate()
	
	note_instance.chart_note = true
	note_instance.tempo = chart.get_tempo_at(time)
	var meter = chart.get_meter_at(time)
	note_instance.seconds_per_beat = 60.0 / note_instance.tempo
	
	note_instance.time = time
	note_instance.length = length
	note_instance.lane = lane
	note_instance.note_type = type
	note_instance.position = Vector2(%Grid.get_real_position(Vector2(1.5 + lane, 0)).x, time_to_y_position(time) + %Grid.grid_size.y * %Grid.zoom.y / 2)
	note_instance.grid_size = (%Grid.grid_size * %Grid.zoom)
	# I am treating scroll speed as a multiplier that would've acted like the grid size for
	# sizing purposes
	note_instance.scroll_speed = (meter[1] * 1.0 / meter[0])
	note_instance.direction = directions[int(lane) % 4]
	note_instance.animation = directions[int(lane) % 4]
	
	note_instance.note_skin = NOTE_SKIN
	
	if placed: 
		
		var L: int = bsearch_left_range(chart.get_notes_data(), chart.get_notes_data().size(), time)
		
		if L != -1:
			
			note_list.insert(L, note_instance)
			chart.chart_data["notes"].insert(L, [time, lane, length, type])
			
			if !moved:
				
				selected_notes = [L]
				selected_note_nodes = [note_list[L]]
		
		else:
			
			note_list.append(note_instance)
			chart.chart_data["notes"].append([time, lane, length, type])
			selected_notes = [chart.get_notes_data().size() - 1]
			selected_note_nodes = [note_list[chart.get_notes_data().size() - 1]]
		
	else:
		note_list.append(note_instance)
	
	$"Notes Layer".add_child(note_instance)


func remove_note(lane: int, time: float):
	
	var i: int = find_note(lane, time)
	if i <= -1: return
	note_list[i].queue_free()
	note_list.remove_at(i)
	chart.chart_data["notes"].remove_at(i)

## Returns the index of the given note in the notes list.
func find_note(lane: int, time: float) -> int:
	
	var L: int = bsearch_left_range(chart.get_notes_data(), chart.get_notes_data().size(), time - 0.1)
	var R: int = bsearch_right_range(chart.get_notes_data(), chart.get_notes_data().size(), time + 0.1)
	
	if (L == -1 or R == -1): return -1
	
	# Just so I don't have to make a new return case because I'm lazy
	if (L == R + 1): L -= 1
	for i in range(L, R + 1):
		
		var note: Array = chart.get_notes_data()[i]
		
		if (note[1] == lane):
			if is_equal_approx(note[0], time): return i
	
	return -1


func play_audios(time: float):
	
	%Instrumental.stream = song_data.instrumental
	%Vocals.stream = AudioStreamPolyphonic.new()
	# This is to prevent null references
	%Vocals.play()
	%Vocals.stream.polyphony = song_data.vocals.size()
	
	var playback = %Vocals.get_stream_playback()
	vocal_tracks = []
	for stream in song_data.vocals: vocal_tracks.append(\
	playback.play_stream(stream, time - chart.offset + start_offset, 0.0, song_speed))
	
	time = clamp(time, 0, %Instrumental.stream.get_length() - 0.1)
	%Instrumental.play(time - chart.offset + start_offset)
	%Instrumental.pitch_scale = song_speed
	song_position = time - chart.offset + start_offset
	
	current_note = bsearch_left_range(chart.get_notes_data(), chart.get_notes_data().size(), song_position)
	
	if chart.get_notes_data().size() > 0:
		
		if song_position > chart.get_notes_data()[chart.get_notes_data().size() - 1][0]:
			
			current_note = chart.get_notes_data().size() - 1

## Converts a float of seconds into a time format of MM:SS.mmm
func float_to_time(time: float) -> String:
	
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = (time - int(time))
	milliseconds = snapped(milliseconds, 0.01)
	
	if seconds < 10:
		return str(minutes) + ":0" + str(int(seconds) % 60) + str(milliseconds).trim_prefix("0")
	else:
		return str(minutes) + ":" + str(int(seconds) % 60) + str(milliseconds).trim_prefix("0")


## This assumes that the tempo and meter dictionaries are sorted
func time_to_y_position(time: float) -> float:
	
	var tempo_data: Dictionary = chart.get_tempos_data()
	var offset: float = -chart.offset
	var y_offset: float = 0
	
	var i: int = 0
	var meter: Array = []
	
	var L: float = -chart.offset
	var R: float = -chart.offset
	
	var tempo: float = 60.0
	
	while R < time:
		
		if i + 1 >= tempo_data.size(): R = time
		else: R = tempo_data.keys()[i + 1]
		
		if R > time: R = time
		
		tempo = tempo_data.get(L)
		meter = chart.get_meter_at(L)
		
		offset += R - L
		y_offset += %Grid.get_real_position(Vector2(0, (R - L) / (60.0 / tempo) * (meter[1] / meter[0]))).y
		
		L = R
		i += 1
	
	return y_offset


func grid_position_to_time(p: Vector2, factor_in_snap: bool = false) -> float:
	
	var tempo_data: Dictionary = chart.get_tempos_data()
	var meter_data: Dictionary = chart.get_meters_data()
	var i: int = 0
	var meter: Array = []
	var L: float = tempo_data.keys()[0]
	var R: float = 0.0
	var yL: float = time_to_y_position(L)
	var yR: float = 0.0
	var yC: float = yL
	var seconds_per_beat: float = 0.0
	var output: float = chart.offset
	
	while yL <= yC:
		
		if i + 1 >= tempo_data.keys().size(): R = %Instrumental.stream.get_length()
		else: R = tempo_data.keys()[i + 1]
		
		meter = chart.get_meter_at(L)
		var tempo = tempo_data.get(L)
		seconds_per_beat = 60.0 / tempo
		yL = time_to_y_position(L)
		yR = time_to_y_position(R)
		yC = p.y * %Grid.grid_size.y * %Grid.zoom.y
		if factor_in_snap: yC *= meter[1] / chart_snap
		
		if (yC >= yL and yC < yR):
			
			output += (yC - yL) / (%Grid.grid_size.y * %Grid.zoom.y * (meter[1] / meter[0])) * seconds_per_beat
			return output
		else: output += R - L
		
		L = R
		i += 1
	
	return output

## Binary searches for both notes and events
func bsearch_left_range(value_set: Array, length: int, left_range: float) -> int:
	
	if (length == 0): return -1
	if (value_set[length - 1][0] < left_range): return -1
	
	var low: int = 0
	var high: int = length - 1
	
	while (low <= high):
		
		@warning_ignore("integer_division")
		var mid: int = low + ((high - low) / 2)
		
		if (value_set[mid][0] >= left_range): high = mid - 1
		else: low = mid + 1
	
	return high + 1


func bsearch_right_range(value_set: Array, length: int, right_range: float) -> int:
	
	if (length == 0): return -1
	if (value_set[0][0] > right_range): return -1
	
	var low: int = 0
	var high: int = length - 1
	
	while (low <= high):
		
		@warning_ignore("integer_division")
		var mid: int = low + ((high - low) / 2)
		
		if value_set[mid][0] > right_range: high = mid - 1
		else: low = mid + 1
	
	return low - 1


func is_note_at(lane: int, time: float) -> bool: return (find_note(lane, time) != -1)


func add_action(state_name: String, song: Song = song_data.duplicate(true), chart_file: Chart = chart.duplicate(true)):
	pass


func _on_play_button_toggled(toggled_on: bool) -> void:
	
	%Vocals.stream_paused = !toggled_on
	%Instrumental.stream_paused = !toggled_on
	
	if toggled_on:
		
		%"Play Button".icon = load("res://assets/sprites/menus/chart editor/pause_button.png")
		if song_position != %Instrumental.get_playback_position(): play_audios(song_position)
	
	else: %"Play Button".icon = load("res://assets/sprites/menus/chart editor/play_button.png")


func move_bound_left(strum_id: String):
	
	ChartHandeler.strum_data[strum_id]["strums"][0] = clamp(ChartHandeler.strum_data[strum_id]["strums"][0] - 1, 0, ChartHandeler.strum_count - 1)
	
	for id in ChartHandeler.strum_data:
		if ChartHandeler.strum_data[id]["strums"][1] == ChartHandeler.strum_data[strum_id]["strums"][0]:
			ChartHandeler.strum_data[id]["strums"][1] = clamp(ChartHandeler.strum_data[id]["strums"][1] - 1, 0, ChartHandeler.strum_count - 1)
	
	update_grid()


func move_bound_right(strum_id: String):
	
	ChartHandeler.strum_data[strum_id]["strums"][1] = clamp(ChartHandeler.strum_data[strum_id]["strums"][1] + 1, 0, ChartHandeler.strum_count - 1)
	
	for id in ChartHandeler.strum_data:
		if ChartHandeler.strum_data[id]["strums"][0] == ChartHandeler.strum_data[strum_id]["strums"][1]:
			ChartHandeler.strum_data[id]["strums"][0] = clamp(ChartHandeler.strum_data[id]["strums"][0] + 1, 0, ChartHandeler.strum_count - 1)
	
	update_grid()


func _on_song_slider_value_changed(value: float) -> void: song_position = value


func _on_skip_forward_pressed() -> void:
	
	song_position += 10
	_on_play_button_toggled(true)


func _on_skip_backward_pressed() -> void:
	
	song_position -= 10
	_on_play_button_toggled(true)


func _on_skip_to_beginning_pressed() -> void:
	
	song_position = start_offset
	_on_play_button_toggled(true)


func _on_skip_to_end_pressed() -> void:
	
	song_position = %Instrumental.stream.get_length() - 0.1
	_on_play_button_toggled(true)


func _on_instrumental_finished() -> void: _on_play_button_toggled(false)


func _on_conductor_new_beat(current_beat: int, measure_relative: int) -> void:
	if measure_relative == 0:
		%"Conductor Beat".play(0.55)
	else:
		%"Conductor Off Beat".play(0.55)


func _on_conductor_new_step(current_step: int, measure_relative: int) -> void:
	%"Conductor Step".play(0.55)

## File button item pressed
func file_button_item_pressed(id):
	
	var item_name: String = %"File Button".get_popup().get_item_text(id)
	
	# Create New Song
	if item_name == "Create New Song":
		
		can_chart = false
		
		var new_file_popup_instance = NEW_FILE_POPUP_PRELOAD.instantiate()
		
		add_child(new_file_popup_instance)
		new_file_popup_instance.popup()
		new_file_popup_instance.connect("file_created", self.new_file)
		new_file_popup_instance.connect("close_requested", self.close_popup)
		%"Open Window".play()
	
	# Open Song
	elif item_name == "Open Song":
		
		can_chart = false
		
		var open_file_popup_instance = OPEN_FILE_POPUP_PRELOAD.instantiate()
		
		add_child(open_file_popup_instance)
		open_file_popup_instance.popup()
		open_file_popup_instance.connect("file_selected", self.load_song_path)
		open_file_popup_instance.connect("close_requested", self.close_popup)
		open_file_popup_instance.connect("canceled", self.close_popup)
		%"Open Window".play()
	
	# Save Chart
	elif id == 2: ResourceSaver.save(chart, chart.resource_path)
	
	# Convert Chart
	elif id == 7:
		
		can_chart = false
		
		var convert_chart_popup_instance = CONVERT_CHART_POPUP_PRELOAD.instantiate()
		
		add_child(convert_chart_popup_instance)
		convert_chart_popup_instance.popup()
		# convert_chart_popup_instance.connect("file_created", self._on_save_folder_dialog_dir_selected)
		convert_chart_popup_instance.connect("file_created", self.new_file)
		convert_chart_popup_instance.connect("close_requested", self.close_popup)
		%"Open Window".play()
	
	# Autosave
	elif id == 3:
		
		SettingsHandeler.set_setting("autosave", !SettingsHandeler.get_setting("autosave"))
		%"File Button".get_popup().set_item_checked(5, SettingsHandeler.get_setting("autosave"))
		%"Note Place".play()
	
	# Exit
	elif id == 6:
		Global.change_scene_to("res://scenes/main menu/main_menu.tscn")

## Edit button item pressed
func edit_button_item_pressed(id):
	
	if id == 0: undo()
	elif id == 1: redo()

## Window button item pressed
func window_button_item_pressed(id):
	
	if id == 0:
		
		%"History Window".position = get_local_mouse_position()
		%"History Window".popup()
		%"Window Button".get_popup().set_item_checked(0, true)


func disable_charting(): can_chart = false
func close_popup():
	
	can_chart = true
	%"Close Window".play()


func undo():
	
	if undo_redo.has_undo():
		
		%Undo.play()
		undo_redo.undo()
		if SettingsHandeler.get_setting("autosave"): ResourceSaver.save(chart, chart.resource_path)
	
	%"Edit Button".get_popup().set_item_checked(0, !undo_redo.has_undo())

func redo():
	
	if undo_redo.has_redo():
		
		%Redo.play()
		undo_redo.redo()
		if SettingsHandeler.get_setting("autosave"): ResourceSaver.save(chart, chart.resource_path)
	
	%"Edit Button".get_popup().set_item_checked(1, !undo_redo.has_redo())


func updated_strums():
	
	can_chart = true
	update_grid()


func _on_chart_snap_value_changed(value: float) -> void:
	
	# This is really dumb and janky
	chart_snap = value


func _on_difficulty_button_item_selected(index: int) -> void:
	
	var option = %"Difficulty Button".get_popup().get_item_text(index)
	if song_data.difficulties.keys().has(option): load_song(song_data, option)


func _on_history_window_close_requested() -> void:
	%"Window Button".get_popup().set_item_checked(0, false)
