extends Node2D
class_name ChartEditor

static var note_skin: NoteSkin = load(Constants.DEFAULT_NOTE_SKIN): 
	get():
		if !note_skin:
			note_skin = load(Constants.DEFAULT_NOTE_SKIN)
		
		return note_skin

static var song_position: float = 0.0
static var start_offset: float = 0.0
static var vocal_waveforms: bool = false
static var instrumental_waveforms: bool = false

var TOOL_THEME = load("uid://b1gv0wfdmojbx")

var NOTE_PRELOAD = load("uid://yyfqg2jvwcmt")
var EVENT_PRELOAD = load("uid://n6k15grja0uh")
var STRUM_BUTTON_PRELOAD: PackedScene = load("uid://ddohksqocyhnx")

var NEW_FILE_POPUP_PRELOAD = load("uid://d05iuopxfqlhj")
var OPEN_FILE_POPUP_PRELOAD = load("uid://388mdmn1mwun")
var CONVERT_CHART_POPUP_PRELOAD = load("uid://c6cl2ayvb4ms3")

@export_group("Colors")
@export var hover_color: Color = Color(1, 1, 1, 0.5)
@export var divider_color: Color = Color(1, 1, 1, 0.5)
@export var current_time_color: Color = Color(1, 0, 0, 1)
@export var muted_color: Color = Color(0.8, 0.8, 0.8, 0.5)
@export var box_color: Color = Color.LIGHT_GREEN
@export var selected_color: Color = Color.GREEN
@export var time_change_color: Color = Color.PURPLE

@onready var upper_ui: ChartEditorUpperUI = %"Upper UI"
@onready var lower_ui: ChartEditorLowerUI = %"Lower UI"
@onready var instrumental: AudioStreamPlayer = %Instrumental
@onready var vocals: AudioStreamPlayer = %Vocals
@onready var conductor: Conductor = $Conductor
@onready var camera_2d: Camera2D = $Camera2D
@onready var song_slider: HSlider = %"Song Slider"
@onready var notes_layer: CanvasLayer = $"Notes Layer"
@onready var grid: Grid = %Grid

## Chart Variables
var backup_chart: Chart = null
# So it turns out that the track ID's are not sequential and can be whatever number they want, I did this so it'd be easier
var vocal_tracks: Array = []

#some settings
static var instrumental_volume: float = 1

## Editor Variables
var undo_redo: UndoRedo = UndoRedo.new()

var song_speed: float = 1.0
var note_nodes: Array = []
var clipboard: Array = []
var can_chart: bool = false

var current_snap: int = 4
var chart_snap: float:
	get():
		return conductor.numerator * current_snap

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
var moved_time_distance: float
var moved_lane_distance: int
var hovered_note: int = -1
var hovered_event: int = -1
var current_visible_notes_L: int = -1
var current_visible_notes_R: int = -1
var current_note_type: String = ""

var waveform_nodes: Dictionary = {}
var waveform_dirty: bool = false

var event_nodes: Array = []
var current_visible_events_L: int = -1
var current_visible_events_R: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if name == "Chart Editor":
		if ChartManager.event_editor:
			get_tree().change_scene_to_file(Constants.EVENT_EDITOR_SCENE)
			return
	
	get_window().content_scale_size = Vector2(1280, 720)
	Global.set_window_title("Chart Editor")
	song_speed = SettingsManager.get_value("gameplay", "song_speed")
	
	$"UI/LoadedSong error".visible = not ChartManager.song
	
	if ChartManager.song:
		var song = ChartManager.song
		load_song(song, ChartManager.difficulty)
		var action: String = "Loaded Song"
		undo_redo.create_action(action)
		undo_redo.add_do_property(self, "song", song)
		undo_redo.add_do_reference(upper_ui.history_window.add_action(action))
		undo_redo.add_undo_property(self, "song", null)
		undo_redo.commit_action()
		enable_can_chart_on_next_frame()
	
	update_ui_usable_state()
	
	update_grid()
	
	## Initializing Popup Signals
	
	lower_ui.chart_snap.value = current_snap
	
	get_tree().get_root().files_dropped.connect(on_files_dropped)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	start_offset = clampf(start_offset, 0, start_offset)
	
	var can_interact_with_chart: bool = can_chart and not is_mouse_over_any_ui() and ChartManager.chart
	
	if ChartManager.song and instrumental.playing:
		song_position = instrumental.get_playback_position() - start_offset
		song_slider.value = song_position
		
		var notes_list = ChartManager.chart.get_notes_data()
		
		if notes_list.size() > 0:
			if current_note < notes_list.size():
				var note = notes_list[current_note]
				if note[0] <= (song_position + start_offset):
					var lane: float = note[1]
					if vocal_tracks.size() == 1 and ChartManager.strum_data.size() > 0:
						if ChartManager.strum_data[0].get('hit_sounds', true):
							SoundManager.tool_hit.play()
					else:
						for id in ChartManager.strum_data.size():
							if ((lane >= ChartManager.strum_data[id]["strums"][0]) and (lane <= ChartManager.strum_data[id]["strums"][1])):
								if ChartManager.strum_data[id].get('hit_sounds', true):
									SoundManager.tool_hit.play()
					
					current_note += 1
		
		refresh_audios()
	
	var axis: int = int(Input.is_action_just_pressed("mouse_scroll_down")) - int(Input.is_action_just_pressed("mouse_scroll_up"))
	if axis:
		if can_interact_with_chart:
			if not instrumental.stream_paused:
				toggle_audios(true)
			
			song_position += conductor.seconds_per_beat * axis
			song_position = snapped(song_position - conductor.offset, conductor.seconds_per_beat) + conductor.offset
			song_position = clamp(song_position, start_offset, instrumental.stream.get_length())
			song_slider.value = song_position
	
	conductor.time = song_position
	
	if ChartManager.chart:
		var time: float = song_position + start_offset
		conductor.tempo = ChartManager.chart.get_tempo_at(time)
		var meter = ChartManager.chart.get_meter_at(time)
		conductor.numerator = meter[0]
		conductor.denominator = meter[1]
		conductor.offset = ChartManager.chart.get_tempo_time_at(time) + ChartManager.chart.offset
		$"Grid Layer/Parallax2D".scroll_offset.y = time_to_y_position(conductor.offset - ChartManager.chart.offset)
		
		update_camera_song_position(instrumental.playing)
	
	var grid_offset: Vector2 = %Grid.position + $"Grid Layer".offset + $"Grid Layer/Parallax2D".scroll_offset
	var mouse_position: Vector2 = get_global_mouse_position() - grid_offset
	var grid_position: Vector2 = %Grid.get_grid_position(mouse_position)
	var snapped_position: Vector2i = Vector2i(%Grid.get_grid_position(
		mouse_position, %Grid.grid_size * Vector2(1, conductor.numerator * conductor.denominator / chart_snap)).floor())
	
	$"Grid Layer/Parallax2D".repeat_size.y = %Grid.get_size().y
	
	if can_interact_with_chart and Input.is_action_just_pressed(&"mouse_left"):
		if Input.is_action_pressed(&"control"):
			bounding_box = true
			start_box = get_global_mouse_position()
		elif is_mouse_over_grid() and not is_mouse_over_any_ui():
			if (((grid_position.x - 1) > 0 and (grid_position.x - 1) < ChartManager.strum_count)):
				var lane: int = snapped_position.x - 1
				var time: float = grid_position_to_time(snapped_position, true)
				time += ChartManager.chart.get_tempo_time_at(song_position + start_offset)
				
				if time <= instrumental.stream.get_length():
					if !is_note_at(lane, time):
						add_action("Placed Note", self.place_note.bind(time, lane, 0, current_note_type, true),
						self.remove_note.bind(lane, time))
						
						SoundManager.tool_note_place.play()
						placing_note = true
					else:
						var i: int = find_note(lane, time)
						if selected_notes.has(i):
							moving_notes = true
							start_lane = lane
							start_time = time
							min_lane = ChartManager.strum_count
							max_lane = 0
							for j in selected_notes:
								var note = ChartManager.chart.get_notes_data()[j]
								min_lane = min(min_lane, note[1])
								max_lane = max(max_lane, note[1])
							
							min_lane = 0 + (start_lane - min_lane)
							max_lane = ChartManager.strum_count - 1 - (max_lane - start_lane)
						else:
							var index: int = find_note(lane, time)
							selected_notes = [index]
							selected_note_nodes = [note_nodes[index - current_visible_notes_L]]
							min_lane = 0
							max_lane = ChartManager.strum_count - 1
						
						SoundManager.tool_mouse_click.play()
	
	if can_interact_with_chart and Input.is_action_pressed(&"mouse_right") and not Input.is_action_pressed(&"control") and is_mouse_over_grid():
		var lane: int = snapped_position.x - 1
		if hovered_note != -1:
			var i: int = hovered_note
			var note = ChartManager.chart.chart_data.notes[i]
			var length: float = note[2]
			var note_type = note[3]
			
			add_action("Removed Note", self.remove_note.bind(i),
			self.place_note.bind(note[0], lane, length, note_type, true))
			SoundManager.tool_note_remove.play()
			
			if selected_notes.has(i):
				var j: int = selected_notes.find(i)
				
				selected_notes.remove_at(j)
				selected_note_nodes.remove_at(j)
				
				if selected_notes.size() > 1:
					var k: int = 0
					for _i in range(selected_notes.size()):
						if k >= j:
							selected_notes[k] -= 1
						k += 1
			
			hovered_note = -1
			
			auto_save()
	
	if can_interact_with_chart and Input.is_action_pressed(&"mouse_left") and not Input.is_action_pressed(&"control") and \
		is_mouse_over_grid() and not instrumental.playing:
		## Song Position Slider
		if grid_position.x < 1 and grid_position.x >= 0:
			if Input.is_action_pressed(&"shift"):
				var time: float = grid_position_to_time(snapped_position, true)
				time += ChartManager.chart.get_tempo_time_at(song_position + start_offset)
				time += ChartManager.chart.offset
				start_offset = time - song_position
			else:
				var time: float = grid_position_to_time(grid_position)
				time += ChartManager.chart.get_tempo_time_at(song_position + start_offset)
				time += ChartManager.chart.offset
				start_offset = time - song_position
			
		elif ((grid_position.x - 1) > 0 and (grid_position.x - 1) < ChartManager.strum_count):
			if placing_note:
				var cursor_time = grid_position_to_time(snapped_position, true)
				cursor_time += ChartManager.chart.get_tempo_time_at(song_position + start_offset)
				
				for i in selected_notes:
					var note: Array = ChartManager.chart.get_notes_data()[i]
					
					var time: float = note[0]
					var lane: int = note[1]
					var note_type = note[3]
					
					var distance = snappedf(max(cursor_time - time, 0.0) / conductor.seconds_per_beat, 1.0 / chart_snap)
					ChartManager.chart.chart_data.notes[i] = [time, lane, distance, note_type]
					
					changed_length = (distance > 0)
					if changed_length:
						if (note_nodes[i - current_visible_notes_L].length != distance):
							SoundManager.tool_note_stretch.play()
						note_nodes[i - current_visible_notes_L].length = distance
					
					auto_save()
		
		if ((grid_position.x - 1) > 0 and (grid_position.x - 1) < ChartManager.strum_count):
			if moving_notes:
				var cursor_time = grid_position_to_time(snapped_position, true)
				cursor_time += ChartManager.chart.get_tempo_time_at(song_position + start_offset)
				var cursor_lane = snapped_position.x - 1
				
				var lane_distance = cursor_lane - start_lane
				var time_distance = cursor_time - start_time
				changed_length = true
				
				if ((start_lane + lane_distance) >= min_lane and (start_lane + lane_distance) <= max_lane):
					if changed_length:
						for node in selected_note_nodes:
							if node:
								var time: float = node.time
								var lane: int = node.lane
								
								node.position = Vector2(
									%Grid.get_real_position(Vector2(1.5 + node.lane + lane_distance, 0)).x,
									time_to_y_position(node.time + time_distance) + %Grid.grid_size.y * %Grid.zoom.y / 2) + $"Grid Layer".offset
						
						auto_save()
						moved_time_distance = time_distance
						moved_lane_distance = lane_distance
	
	
	if Input.is_action_just_released(&"mouse_left"):
		if placing_note:
			if changed_length:
				var action: String = "Changed Note Length(s)"
				undo_redo.create_action(action)
				for i in selected_notes:
					undo_redo.add_do_property(note_nodes[i - current_visible_notes_L],
					"length", note_nodes[i - current_visible_notes_L].length)
					undo_redo.add_do_method(self.change_length.bind(i, note_nodes[i - current_visible_notes_L].length))
					undo_redo.add_undo_property(note_nodes[i - current_visible_notes_L],
					"length", 0.0)
					undo_redo.add_undo_method(self.change_length.bind(i, 0))
				
				undo_redo.add_do_reference(%"Upper UI".get_node("%History Window").add_action(action))
				undo_redo.commit_action()
			
			placing_note = false
			changed_length = false
		
		if bounding_box:
			bounding_box = false
			
			var rect = Rect2(start_box, get_global_mouse_position() - start_box).abs()
			# Added leniency since notes are centered from the top
			var pos_1: Vector2 = %Grid.get_grid_position(rect.position - grid_offset) - Vector2(1, 0.5)
			var pos_2: Vector2 = %Grid.get_grid_position(rect.end - grid_offset) + Vector2(-1, 0.5)
			
			var time_a: float = grid_position_to_time(pos_1, true) + conductor.offset
			var time_b: float = grid_position_to_time(pos_2, true) + conductor.offset
			var lane_a: int = floor(pos_1.x)
			var lane_b: int = floor(pos_2.x)
			
			print(time_a, " - ", time_b)
			
			var L: int = bsearch_left_range(ChartManager.chart.get_notes_data(), time_a)
			var R: int = bsearch_right_range(ChartManager.chart.get_notes_data(), time_b)
			
			if (L == R + 1):
				L -= 1
			
			L = max(0, L)
			add_action("Selected Area", self.select_area.bind(L, R, lane_a, lane_b), self.set.bind(&"selected_notes", self.selected_notes))
		
		if moving_notes:
			add_action("Moved Note(s)", self.move_selection.bind(moved_time_distance, moved_lane_distance),
			self.move_selection.bind(-moved_time_distance, -moved_lane_distance))
	
	if Input.is_action_just_released(&"control"):
		bounding_box = false
	
	queue_redraw()

func refresh_audios():
	instrumental.volume_linear = instrumental_volume
	
	for strum in ChartManager.strum_data.size():
		var track = ChartManager.strum_data[strum]["track"]
		if track < vocal_tracks.size():
			vocals.get_stream_playback().set_stream_volume(vocal_tracks[track], linear_to_db(ChartManager.strum_data[track]['volume']))


func is_mouse_over_any_ui() -> bool:
	var mouse = get_corrected_mouse_position()
	
	if is_point_in_any_window(mouse):
		return true
	
	if Rect2i(upper_ui.global_position + upper_ui.get_parent().offset, upper_ui.size).has_point(mouse):
		return true
	
	if Rect2i(lower_ui.global_position + lower_ui.get_parent().offset, lower_ui.size).has_point(mouse):
		return true
	
	for button:HFlowContainer in get_tree().get_nodes_in_group(&"strum_buttons"):
		#they sahre the same parent as lower ui so this is fine
		if Rect2i(button.global_position + lower_ui.get_parent().offset, button.size).has_point(mouse):
			return true
	
	return false


func is_point_in_any_window(point: Vector2) -> bool:
	for window: Window in get_tree().get_nodes_in_group(&"windows"):
		if not window or not window.visible or window is not Window:
			continue
		
		var position_offset = window.get_position_with_decorations() - window.position
		
		#the decoration addition is only needed for the y
		var window_rect = Rect2i(window.get_position_with_decorations() + position_offset, window.get_size_with_decorations())
		window_rect.position.x = window.position.x
		window_rect.size.x = window.size.x
		
		if window_rect.has_point(point):
			return true
	return false

func is_mouse_over_grid() -> bool:
	var screen_mouse_pos = get_corrected_mouse_position()
	return screen_mouse_pos.y > 64 and screen_mouse_pos.y < 640

func get_corrected_mouse_position() -> Vector2:
	return get_global_mouse_position() - Vector2(0, camera_2d.position.y - 360)

func _draw() -> void:
	var rect: Rect2
	
	## Box when you're holding control
	if bounding_box:
		rect = Rect2(start_box, get_global_mouse_position() - start_box).abs()
		draw_rect(rect, box_color)
	
	if ChartManager.chart:
		# The offset the grid has from the normal canvas layer
		var grid_offset: Vector2 = %Grid.position + $"Grid Layer".offset + $"Grid Layer/Parallax2D".scroll_offset
		var mouse_position: Vector2 = get_global_mouse_position() - grid_offset
		var grid_position: Vector2i = Vector2i(%Grid.get_grid_position(mouse_position).floor())
		var snapped_position: Vector2i = Vector2i(
			%Grid.get_grid_position(mouse_position, %Grid.grid_size * Vector2(1, conductor.numerator * conductor.denominator / chart_snap))
			)
		
		# Song Start Offset Marker
		rect = Rect2(grid_offset - $"Grid Layer/Parallax2D".scroll_offset + Vector2(%Grid.get_real_position(Vector2(0, 0)).x,
		time_to_y_position(song_position - ChartManager.chart.offset + start_offset) - 2), \
		%Grid.get_real_position(Vector2(%Grid.columns, 0)) - %Grid.get_real_position(Vector2(0, 0)) + Vector2(0, 4))
		draw_rect(rect, current_time_color)
		
		# The box at the start of the marker
		rect = Rect2(grid_offset - $"Grid Layer/Parallax2D".scroll_offset + Vector2(%Grid.get_real_position(Vector2(0, 0)).x,
		time_to_y_position(song_position - ChartManager.chart.offset + start_offset) - 4), \
		%Grid.get_real_position(Vector2(1, 0)) - %Grid.get_real_position(Vector2(0, 0)) + Vector2(0, 8))
		draw_rect(rect, current_time_color)
		
		# Hover Box
		if grid_position.x >= 0 and grid_position.x < %Grid.columns and not is_mouse_over_any_ui():
			rect = Rect2(%Grid.get_real_position(snapped_position, %Grid.grid_size * Vector2(1, conductor.numerator * conductor.denominator / chart_snap)) + grid_offset, \
			%Grid.grid_size * %Grid.zoom * Vector2(1, conductor.numerator * conductor.denominator / chart_snap))
			draw_rect(rect, hover_color)
		
		## Note Highlighting
		for note in selected_note_nodes:
			if note:
				var length: float = note.length + 1.0 / conductor.numerator
				length *= %Grid.grid_size.y * %Grid.zoom.y
				length *= conductor.numerator
				rect = Rect2(note.global_position - (%Grid.grid_size / 2 * %Grid.zoom),
				Vector2(%Grid.grid_size.x * %Grid.zoom.x, length))
				draw_rect(rect, selected_color)

func on_files_dropped(files: PackedStringArray):
	var file: String = files[0]
	var local_file: String = ProjectSettings.localize_path(file)
	print("File taken: ", local_file)
	if ResourceLoader.exists(local_file) and ["res", "tres"].has(file.get_extension()):
		var resource = load(local_file)
		if resource is Song:
			load_song(resource)
		elif resource is Chart:
			load_chart(resource)
		else:
			printerr("(ChartEdtior) File is not a song is %s correct?" % local_file)


func update_grid():
	%Grid.columns = 2 + ChartManager.strum_count
	%Grid.rows = conductor.numerator * conductor.denominator
	%"Strum Labels".position = %Grid.get_real_position(Vector2(1, -1)) - Vector2(2, 296)
	%"Strum Labels".size.x = 0
	%"Strum Labels".custom_minimum_size.x = ChartManager.strum_count * (
		%Grid.grid_size.x * %Grid.zoom.x) + (4 * ChartManager.strum_data.size())
	
	for n in %"Strum Labels".get_children():
		n.queue_free()
	
	for id in ChartManager.strum_data.size():
		var strum_label_instance = STRUM_BUTTON_PRELOAD.instantiate()
		
		strum_label_instance.id = id
		
		%"Strum Labels".add_child(strum_label_instance)
		strum_label_instance.custom_minimum_size.x = (
			ChartManager.strum_data[id]["strums"][1] + 1 - ChartManager.strum_data[id]["strums"][0]
			) * %Grid.grid_size.x * %Grid.zoom.x
		strum_label_instance.size.y = 32
		
		if ChartManager.strum_data[id]["strums"][0] == 0:
			strum_label_instance.get_node("Move Lane Left").visible = false
		if ChartManager.strum_data[id]["strums"][1] == ChartManager.strum_count - 1:
			strum_label_instance.get_node("Move Lane Right").visible = false
		
		strum_label_instance.connect(&"move_bound_left", self.move_bound_left)
		strum_label_instance.connect(&"move_bound_right", self.move_bound_right)
		strum_label_instance.connect(&"opened", self.disable_charting)
		strum_label_instance.connect(&"closed", self.close_popup)
		strum_label_instance.connect(&"updated", self.updated_strums)
		strum_label_instance.add_to_group(&"strum_buttons")
	
	%"Strum Labels".size.y = 32


func load_song(song: Song, difficulty: Variant = null):
	if ChartManager.song != song:
		song_position = 0.0
	else:
		song_position -= start_offset
	
	$"UI/LoadedSong error".visible = false
	ChartManager.song = song
	if difficulty == null:
		difficulty = ChartManager.song.difficulties.keys()[0]
	
	var difficulty_data: Dictionary = song.difficulties.get(difficulty)
	ChartManager.chart = Chart.load(difficulty_data.chart)
	ChartManager.difficulty = difficulty
	undo_redo.clear_history()
	get_tree().call_group(&"history", &"queue_free")
	instrumental.stream = SoundManager.get_stream(ChartManager.song.instrumental)
	play_audios(song_position)
	
	toggle_audios()
	
	song_slider.max_value = instrumental.stream.get_length()
	song_slider.value = 0.0
	conductor.tempo = ChartManager.chart.get_tempo_at(0.0)
	var meter = ChartManager.chart.get_meter_at(0.0)
	conductor.numerator = meter[0]
	conductor.denominator = meter[1]
	conductor.offset = ChartManager.chart.offset
	
	lower_ui.get_node("%Difficulty Button").get_popup().clear()
	for d in ChartManager.song.difficulties.keys():
		lower_ui.get_node("%Difficulty Button").get_popup().add_item(d)
	
	lower_ui.get_node("%Difficulty Button").select(ChartManager.song.difficulties.keys().find(difficulty))
	%"Upper UI".get_node("%Metadata Window").update_stats()
	
	load_chart(ChartManager.chart)
	current_snap = conductor.numerator
	
	waveform_dirty = true
	update_waveforms(song_position)
	
	enable_can_chart_on_next_frame()
	update_ui_usable_state()


func load_song_path(path: String, difficulty: Variant = null):
	var song = load(path)
	if song is not Song:
		printerr("File: ", path, " is not a song file.")
		return
	
	load_song(song, difficulty)


func load_chart(file: Chart, ghost: bool = false):
	if file:
		backup_chart = file.duplicate(true)
	
	selected_notes = []
	selected_note_nodes = []
	current_visible_notes_L = -1
	current_visible_notes_R = -1
	current_visible_events_L = -1
	current_visible_events_R = -1
	get_tree().call_group(&"notes", &"queue_free")
	note_nodes = []
	
	get_tree().call_group(&"events", &"queue_free")
	event_nodes = []
	
	undo_redo.clear_history()
	get_tree().call_group(&"history", &"queue_free")
	var action: String = "Loaded Chart"
	undo_redo.create_action(action)
	undo_redo.add_do_property(self, SettingsManager.SEC_CHART, file)
	undo_redo.add_do_reference(upper_ui.history_window.add_action(action))
	undo_redo.commit_action()
	
	upper_ui.metadata_window.update_stats()
	enable_can_chart_on_next_frame()
	load_section(song_position)
	update_grid()
	load_dividers()
	update_camera_song_position(true)

## Loads all the notes and waveforms for the next two waveforms.
func load_section(time: float):
	if not ChartManager.chart or ChartManager.chart.get_notes_data().is_empty():
		return
	
	var _range: float = conductor.seconds_per_beat * conductor.numerator * 2 / %Grid.zoom.y
	var L: int = bsearch_left_range(ChartManager.chart.get_notes_data(), time - _range)
	var R: int = bsearch_right_range(ChartManager.chart.get_notes_data(), time + _range)
	
	if selected_notes.size() > 0:
		L = min(selected_notes.front(), L)
		R = max(R, selected_notes.back())
	
#region Loading Notes
	if L > -1 and R > -1:
		## Clearing any invisible notes
		if current_visible_notes_L != L or current_visible_notes_R != R:
			var i: int = 0
			for _i in range(note_nodes.size()):
				var note = note_nodes[i]
				if (note.time < ChartManager.chart.get_notes_data()[L][0]
				or note.time > ChartManager.chart.get_notes_data()[R][0]):
					note.queue_free()
					note_nodes.remove_at(i)
					i -= 1
				
				i += 1
		
		for i in range(L, R + 1):
			if i >= current_visible_notes_L and i <= current_visible_notes_R:
				if (i - L) >= 0 and (i - L) < note_nodes.size():
					update_note_position(note_nodes[i - L])
				continue
			
			var note = ChartManager.chart.get_notes_data()[i]
			place_note(note[0], note[1], note[2], note[3], false, false, true, i - L)
		
		current_visible_notes_L = L
		current_visible_notes_R = R
#endregion
#region Loading Events
	L = bsearch_left_range(ChartManager.chart.get_events_data(), time - _range)
	R = bsearch_right_range(ChartManager.chart.get_events_data(), time + _range)
	
	if L > -1 and R > -1:
		## Clearing any invisible notes
		if current_visible_events_L != L or current_visible_events_R != R:
			var i: int = 0
			for _i in range(event_nodes.size()):
				var event = event_nodes[i]
				if (event.time < ChartManager.chart.get_events_data()[L][0]
				or event.time > ChartManager.chart.get_events_data()[R][0]):
					event.queue_free()
					event_nodes.remove_at(i)
					i -= 1
				
				i += 1
		
		for i in range(L, R + 1):
			if i >= current_visible_events_L and i <= current_visible_events_R:
				if (i - L) >= 0 and (i - L) < event_nodes.size():
					update_note_position(event_nodes[i - L])
				continue
			
			var event = ChartManager.chart.get_events_data()[i]
			place_event(event[0], event[1], event[2], false, false, true, i - L)
		
		current_visible_events_L = L
		current_visible_events_R = R
		#endregion
	
	update_selected_notes()


func load_dividers():
	get_tree().call_group(&"dividers",  &"queue_free")
	for i in range(conductor.numerator):
		var rect = ColorRect.new()
		var size: float = 4 if i == 0 else 2
		
		rect.color = divider_color
		rect.size = Vector2(%Grid.get_size().x, size)
		rect.position = %Grid.position
		rect.position.x -= %Grid.get_size().x / 2
		rect.position.y += (%Grid.grid_size.y * %Grid.zoom.y) * conductor.denominator * i
		rect.position.y -= rect.size.y / 2
		
		$"Grid Layer/Parallax2D".add_child(rect)
		rect.add_to_group(&"dividers")
	
	for i in [0, 1, %Grid.columns]:
		var rect = ColorRect.new()
		var size: float = 2
		
		rect.color = divider_color
		rect.size = Vector2(size, %Grid.get_size().y)
		rect.position = %Grid.position
		rect.position.x += (%Grid.grid_size.x * %Grid.zoom.x) * i
		rect.position.x -= %Grid.get_size().x / 2
		rect.position.x -= rect.size.x / 2
		
		$"Grid Layer/Parallax2D".add_child(rect)
		rect.add_to_group(&"dividers")
	
	for packet in ChartManager.strum_data:
		var rect = ColorRect.new()
		var size: float = 2
		
		rect.color = divider_color
		rect.size = Vector2(size, %Grid.get_size().y)
		rect.position = %Grid.position
		rect.position.x += (%Grid.grid_size.x * %Grid.zoom.x) * (packet.get("strums")[1] + 2)
		rect.position.x -= %Grid.get_size().x / 2
		rect.position.x -= rect.size.x / 2
		
		$"Grid Layer/Parallax2D".add_child(rect)
		rect.add_to_group(&"dividers")
	
	var times: Array = [instrumental.stream.get_length()]
	times.append_array(ChartManager.chart.get_tempos_data().keys())
	times.erase(0.0)
	for i in times:
		var rect = ColorRect.new()
		var size: float = 2
		
		rect.size = Vector2(%Grid.get_size().x, size)
		rect.position = %Grid.position
		rect.position.x -= %Grid.get_size().x / 2
		rect.position.y = time_to_y_position(i)
		rect.position.y -= rect.size.y / 2
		rect.position += %Grid.position + $"Grid Layer".offset
		rect.color = time_change_color
		
		self.add_child(rect)
		rect.add_to_group(&"dividers")


func new_file(path: String, song: Song):
	var old_song = ChartManager.song
	load_song(song)
	var action: String = "Created New Song"
	undo_redo.create_action(action)
	undo_redo.add_do_property(self, "song", song)
	undo_redo.add_do_reference(%"Upper UI".get_node("%History Window").add_action(action))
	undo_redo.add_undo_property(self, "song", old_song)
	undo_redo.commit_action()
	enable_can_chart_on_next_frame()

## Adds an instance of a note on the chart editor, placed boolean adds it to the chart data.
## Reset the select notes and note nodes list before calling moved
func place_note(time: float, lane: int, length: float, type: String, placed: bool = false, moved: bool = false,
sorted: bool = false, sort_index: int = -1) -> int:
	var directions: Array = ["left", "down", "up", "right"]
	
	var note_instance = NOTE_PRELOAD.instantiate()
	
	var meter: Array = ChartManager.chart.get_meter_at(time)
	
	note_instance.time = time
	note_instance.length = length
	note_instance.lane = lane
	note_instance.note_type = type
	# I am treating scroll speed as a multiplier that would've acted like the grid size for
	# sizing purposes
	note_instance.scroll_speed = meter[0]
	note_instance.direction = directions[lane % 4]
	note_instance.animation = str(Constants.NOTE_TYPES.get(type, ""), directions[lane % 4])
	
	update_note_position(note_instance)
	
	note_instance.note_skin = note_skin
	
	var output: int
	if placed:
		var L: int = bsearch_left_range(ChartManager.chart.get_notes_data(), time)
		if L != -1:
			ChartManager.chart.chart_data["notes"].insert(L, [time, lane, length, type])
			
			if note_nodes.is_empty():
				note_nodes.append(note_instance)
			elif (L - current_visible_notes_L) < 0:
				note_nodes.insert(0, note_instance)
			elif (L - current_visible_notes_L) >= note_nodes.size():
				note_nodes.append(note_instance)
			else:
				note_nodes.insert(L - current_visible_notes_L, note_instance)
			
			if !moved:
				selected_notes = [L]
				selected_note_nodes = [note_instance]
				min_lane = 0
				max_lane = ChartManager.strum_count - 1
			
			output = L
		else:
			note_nodes.append(note_instance)
			ChartManager.chart.chart_data["notes"].append([time, lane, length, type])
			L = ChartManager.chart.get_notes_data().size() - 1
			selected_notes = [L]
			selected_note_nodes = [note_instance]
			min_lane = 0
			max_lane = ChartManager.strum_count - 1
			output = L
		
		# Preventing fake notes
		current_visible_notes_L = max(min(L, current_visible_notes_L), 0)
		current_visible_notes_R += 1
	else:
		if sorted:
			var L: int = sort_index
			if note_nodes.is_empty():
				note_nodes.append(note_instance)
			elif L < 0:
				note_nodes.insert(0, note_instance)
			elif L >= note_nodes.size():
				note_nodes.append(note_instance)
			else:
				note_nodes.insert(L, note_instance)
		else:
			note_nodes.append(note_instance)
	
	notes_layer.add_child(note_instance)
	note_instance.add_to_group(&"notes")
	note_instance.area.connect(&"mouse_entered", self.update_note.bind(note_instance))
	note_instance.area.connect(&"mouse_exited", self.update_note.bind(null))
	return output

## Adds an instance of a event on the chart editor, placed boolean adds it to the chart data.
func place_event(time: float, event: String, parameters: Array, placed: bool = false, moved: bool = false,
sorted: bool = false, sort_index: int = -1) -> int:
	var event_instance = EVENT_PRELOAD.instantiate()
	
	event_instance.time = time
	event_instance.event = event
	event_instance.parameters = parameters
	update_note_position(event_instance)
	
	var output: int
	
	if placed:
		var L: int = bsearch_left_range(ChartManager.chart.get_events_data(), time)
		if L != -1:
			ChartManager.chart.chart_data["events"].insert(L, [time, event, parameters])
			
			if event_nodes.is_empty():
				event_nodes.append(event_instance)
			elif (L - current_visible_events_L) < 0:
				event_nodes.insert(0, event_instance)
			elif (L - current_visible_events_L) >= event_nodes.size():
				event_nodes.append(event_instance)
			else:
				event_nodes.insert((L - current_visible_events_L), event_instance)
			
			if !moved:
				selected_notes = [L]
				selected_note_nodes = [event_instance]
				min_lane = 0
				max_lane = ChartManager.strum_count - 1
			
			output = L
		else:
			event_nodes.append(event_instance)
			ChartManager.chart.chart_data["events"].append([time, event, parameters])
			L = ChartManager.chart.get_events_data().size() - 1
			selected_notes = [L]
			selected_note_nodes = [event_instance]
			min_lane = 0
			max_lane = ChartManager.strum_count - 1
			output = L
		
		# Preventing fake events
		current_visible_events_L = max(min(L, current_visible_events_L), 0)
		current_visible_events_R += 1
	else:
		if sorted:
			var L: int = sort_index
			
			if event_nodes.is_empty():
				event_nodes.append(event_instance)
			elif L < 0:
				event_nodes.insert(0, event_instance)
			elif L >= event_nodes.size():
				event_nodes.append(event_instance)
			else:
				event_nodes.insert(L, event_instance)
		else:
			event_nodes.append(event_instance)
	
	notes_layer.add_child(event_instance)
	event_instance.add_to_group(&"events")
	event_instance.area.connect(&"mouse_entered", self.update_event.bind(event_instance))
	event_instance.area.connect(&"mouse_exited", self.update_event.bind(null))
	return output

# Returns the indexes of the new notes
func place_notes(notes: Array) -> Array:
	var indices: Array = []
	for note in notes:
		place_note(note[0], note[1], note[2], note[3], true)
	
	# Surely there's a cleaner way to do this
	for note in notes:
		var i: int = find_note(note[1], note[0])
		if i != -1:
			indices.append(i)
	
	indices.sort()
	return indices

## Giving only 1 parameter removes the note at the given index
func remove_note(lane, time: float = -1):
	var i: int
	if time != -1:
		i = find_note(lane, time)
	else:
		i = lane
	
	if i <= -1:
		return
	
	if (i - current_visible_notes_L) < note_nodes.size() and (i - current_visible_notes_L) >= 0:
		note_nodes[i - current_visible_notes_L].queue_free()
		note_nodes.remove_at(i - current_visible_notes_L)
		current_visible_notes_R -= 1
	
	ChartManager.chart.chart_data["notes"].remove_at(i)

func remove_notes(notes: Array):
	var i: int = 0
	for note in notes:
		var _note = ChartManager.chart.get_notes_data()[note - i]
		remove_note(_note[1], _note[0])
		i += 1

## Returns the index of the given note in the notes list.
func find_note(lane: int, time: float) -> int:
	var L: int = bsearch_left_range(ChartManager.chart.get_notes_data(), time - 0.00001)
	var R: int = bsearch_right_range(ChartManager.chart.get_notes_data(), time + 0.00001)
	
	if (L == -1 or R == -1):
		return -1
	
	# Just so I don't have to make a new return case because I'm lazy
	if (L == R + 1):
		L -= 1
	
	for i in range(L, R + 1):
		var note: Array = ChartManager.chart.get_notes_data()[i]
		if note[1] == lane and is_equal_approx(note[0], time):
			return i
	
	return -1

func find_events_at(time: float) -> Array[int]:
	var L: int = bsearch_left_range(ChartManager.chart.get_events_data(), time - 0.00001)
	var R: int = bsearch_right_range(ChartManager.chart.get_events_data(), time + 0.00001)
	if L == -1 or R == -1:
		return []
	if L == (R + 1):
		L -= 1
	
	var ret: Array[int] = []
	
	for i in range(L, R + 1):
		var _event: Array = ChartManager.chart.get_events_data()[i]
		if is_equal_approx(_event[0], time):
			ret.append(i)
	return ret

func find_event(event: String, time: float) -> int:
	var L: int = bsearch_left_range(ChartManager.chart.get_events_data(), time - 0.00001)
	var R: int = bsearch_right_range(ChartManager.chart.get_events_data(), time + 0.00001)
	
	#print(find_events_at(time))
	
	if (L == -1 or R == -1):
		return -1
	
	# Just so I don't have to make a new return case because I'm lazy
	if (L == R + 1):
		L -= 1
	
	for i in range(L, R + 1):
		var _event: Array = ChartManager.chart.get_events_data()[i]
		if (_event[1] == event):
			if is_equal_approx(_event[0], time):
				return i
	
	return -1

func play_audios(time: float):
	vocals.stream = AudioStreamPolyphonic.new()
	# This is to prevent null references
	vocals.play()
	if not ChartManager.song:
		return
	vocals.stream.polyphony = ChartManager.song.vocals.size()
	
	var playback = vocals.get_stream_playback()
	vocal_tracks = []
	for stream in ChartManager.song.vocals:
		vocal_tracks.append(playback.play_stream(SoundManager.get_stream(stream),
		time + start_offset, 0.0, song_speed))
	
	time = clamp(time, 0, instrumental.stream.get_length() - 0.1)
	instrumental.play(time + start_offset)
	instrumental.pitch_scale = song_speed
	song_position = time + start_offset
	
	current_note = bsearch_left_range(ChartManager.chart.get_notes_data(), song_position)
	
	if ChartManager.chart.get_notes_data().size() > 0:
		if song_position > ChartManager.chart.get_notes_data()[ChartManager.chart.get_notes_data().size() - 1][0]:
			current_note = ChartManager.chart.get_notes_data().size() - 1

## This assumes that the tempo and meter dictionaries are sorted
func time_to_y_position(time: float) -> float:
	var tempo_data: Dictionary = ChartManager.chart.get_tempos_data()
	var _offset: float = 0# -ChartManager.chart.offset
	var y_offset: float = 0
	
	var i: int = 0
	var meter: Array = []
	
	var L: float = tempo_data.keys()[0]
	var R: float = tempo_data.keys()[0]
	
	var tempo: float = 60.0
	
	while R < time:
		if i + 1 >= tempo_data.size():
			R = time
		else:
			R = tempo_data.keys()[i + 1]
		
		if R > time:
			R = time
		
		tempo = tempo_data.get(L)
		meter = ChartManager.chart.get_meter_at(L)
		
		_offset += R - L
		y_offset += %Grid.get_real_position(Vector2(0, (R - L) / (60.0 / tempo) * meter[0])).y
		
		L = R
		i += 1
	
	return y_offset
	

func enable_can_chart_on_next_frame():
	get_tree().create_timer(0.0).timeout.connect(func(): can_chart = true)

func update_note_position(node: Node2D):
	if node is ChartNote:
		node.position = Vector2(%Grid.get_real_position(Vector2(1.5 + node.lane, 0)).x,
		time_to_y_position(node.time) + %Grid.grid_size.y * %Grid.zoom.y / 2)
		node.position += $"Grid Layer".offset
		node.grid_size = (%Grid.grid_size * %Grid.zoom)
		node.update()
	elif node is ChartEvent:
		node.position = Vector2(%Grid.get_real_position(Vector2(-0.5 + %Grid.columns, 0)).x,
		time_to_y_position(node.time) + %Grid.grid_size.y * %Grid.zoom.y / 2)
		node.position += $"Grid Layer".offset
		node.grid_size = (%Grid.grid_size * %Grid.zoom)
		node.update()
	else:
		printerr(node.get_class(), " isn't a valid node.")

## This assumes that the tempo and meter dictionaries are sorted
func grid_position_to_time(p: Vector2, factor_in_snap: bool = false) -> float:
	var time: float = song_position + start_offset
	var meter: Array = ChartManager.chart.get_meter_at(time)
	var L: float = ChartManager.chart.get_tempo_time_at(time)
	var yR: float = p.y * %Grid.grid_size.y * %Grid.zoom.y
	if factor_in_snap:
		yR *= meter[0] * meter[1] / chart_snap
	
	var seconds_per_beat: float = 60.0 / ChartManager.chart.get_tempos_data()[L]
	var output: float = yR / (%Grid.grid_size.y * %Grid.zoom.y * meter[0]) * seconds_per_beat
	
	return output

## Binary searches for both notes and events
func bsearch_left_range(value_set: Array, left_range: float) -> int:
	var length: int = value_set.size()
	if (length == 0):
		return -1
	
	var low: int = 0
	var high: int = length - 1
	var found: int = -1
	
	while (low <= high):
		var mid: int = (low + high) / 2
		
		if (value_set[mid][0] >= left_range):
			found = mid
			high = mid - 1
		else:
			low = mid + 1
	
	return found

func bsearch_right_range(value_set: Array, right_range: float) -> int:
	var length: int = value_set.size()
	if (length == 0):
		return -1
	
	var low: int = 0
	var high: int = length - 1
	var found: int = -1
	
	while (low <= high):
		var mid: int = (low + high) / 2
		
		if value_set[mid][0] > right_range:
			high = mid - 1
		else:
			low = mid + 1
			found = mid
	
	return found

func is_note_at(lane: int, time: float) -> bool:
	return find_note(lane, time) != -1

func toggle_audios(paused: bool = true):
	vocals.stream_paused = paused
	instrumental.stream_paused = paused
	
	if not paused:
		play_audios(song_position)
	
	lower_ui.toggle_play_button_state(not paused)
	

func move_bound_left(strum_id: int):
	var strum_data = ChartManager.strum_data[strum_id]
	strum_data["strums"][0] = clamp(strum_data["strums"][0] - 1, 0, ChartManager.strum_count - 1)
	
	for id in ChartManager.strum_data.size():
		if ChartManager.strum_data[id]["strums"][1] == strum_data["strums"][0]:
			ChartManager.strum_data[id]["strums"][1] = clamp(ChartManager.strum_data[id]["strums"][1] - 1, 0, ChartManager.strum_count - 1)
	
	update_grid()
	load_dividers()

func move_bound_right(strum_id: int):
	var strum_data = ChartManager.strum_data[strum_id]
	strum_data["strums"][1] = clamp(strum_data["strums"][1] + 1, 0, ChartManager.strum_count - 1)
	
	for id in ChartManager.strum_data.size():
		if ChartManager.strum_data[id]["strums"][0] ==  strum_data["strums"][1]:
			ChartManager.strum_data[id]["strums"][0] = clamp(ChartManager.strum_data[id]["strums"][0] + 1, 0, ChartManager.strum_count - 1)
	
	update_grid()
	load_dividers()

func find_strum_id(strum_name: String) -> int:
	for id in ChartManager.strum_data.size():
		var strum_data = ChartManager.strum_data[id]
		if strum_data["name"] == strum_name:
			return id
	return -1

func _on_song_slider_value_changed(value: float) -> void:
	song_position = value

func _on_song_slider_drag_started() -> void:
	toggle_audios(true)


func _on_skip_forward_pressed() -> void:
	song_position += 10
	toggle_audios(false)

func _on_skip_backward_pressed() -> void:
	song_position -= 10
	toggle_audios(false)
	

func _on_skip_to_beginning_pressed() -> void:
	song_position = start_offset
	toggle_audios(false)

func _on_skip_to_end_pressed() -> void:
	song_position = instrumental.stream.get_length() - 0.1
	toggle_audios(false)

func _on_instrumental_finished() -> void:
	toggle_audios(true)

func _on_conductor_new_beat(current_beat: int, measure_relative: int) -> void:
	if SettingsManager.get_value(SettingsManager.SEC_CHART, "conductor_beat"):
		if measure_relative == 0:
			SoundManager.conductor_beat.play()
		else:
			SoundManager.conductor_off_beat.play()
	
	if ChartManager.chart:
		load_section(song_position)
		update_waveforms(song_position)
	
	lower_ui.get_node("%Beat").text = str("Beat: ", current_beat + 1)


func _on_conductor_new_step(current_step: int, measure_relative: int) -> void:
	if SettingsManager.get_value(SettingsManager.SEC_CHART, "conductor_step"):
		SoundManager.conductor_step.play()
	
	lower_ui.get_node("%Step").text = str("Step: ", current_step + 1)


func _on_conductor_new_tempo(_tempo: float) -> void:
	lower_ui.get_node("%Tempo").text = str("Tempo: ", _tempo)
	update_grid()
	load_dividers()


func _input(event: InputEvent) -> void:
	if event is InputEventPanGesture:
		var can_interact_with_chart: bool = can_chart and not is_mouse_over_any_ui() and ChartManager.chart
		
		if can_interact_with_chart: #song scrubbing
			if not instrumental.stream_paused:
				toggle_audios(true)
			song_position += conductor.seconds_per_beat * event.delta.y
			song_position = snapped(song_position - conductor.offset, conductor.seconds_per_beat) + conductor.offset
			song_position = clamp(song_position, start_offset, instrumental.stream.get_length())
			song_slider.value = song_position

## Edit button item pressed
func edit_button_item_pressed(id):
	match id:
		0:  undo()
		1:  redo()
		3:  cut()
		4:  copy()
		5:  paste()
		6:  delete_stacked_notes()
		8:  do_flip()
		10: select_all()
		11: deselect_all()
		12: increase_length()
		13: decrease_length()
		_:  print("id: ", id)

## Audio button item pressed
func audio_button_item_pressed(id):
	match id:
		0: toggle_audios(instrumental.playing)
		4:
			SettingsManager.set_value(SettingsManager.SEC_GAMEPLAY, "song_speed",
			min(SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "song_speed") + 0.05, 2))
			SettingsManager.flush()
			song_speed = SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "song_speed")
		
		5:
			SettingsManager.set_value(SettingsManager.SEC_GAMEPLAY, "song_speed",
			max(SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "song_speed") - 0.05, 0.5))
			SettingsManager.flush()
			song_speed = SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "song_speed")
		
		7: #Toggle Beat Sound
			SettingsManager.set_value(SettingsManager.SEC_CHART, "conductor_beat",
			!SettingsManager.get_value(SettingsManager.SEC_CHART, "conductor_beat"))
			SettingsManager.flush()
			SoundManager.tool_mouse_click.play()
			%"Upper UI".get_node("%Audio Button").get_popup().set_item_checked(
				%"Upper UI".get_node("%Audio Button").get_popup().get_item_index(id),
				SettingsManager.get_value(SettingsManager.SEC_CHART, "conductor_beat"))
		
		8: #Toggle Step Sound
			SettingsManager.set_value(SettingsManager.SEC_CHART, "conductor_step",
			!SettingsManager.get_value(SettingsManager.SEC_CHART, "conductor_step"))
			SettingsManager.flush()
			SoundManager.tool_mouse_click.play()
			%"Upper UI".get_node("%Audio Button").get_popup().set_item_checked(
				%"Upper UI".get_node("%Audio Button").get_popup().get_item_index(id),
				SettingsManager.get_value(SettingsManager.SEC_CHART, "conductor_step"))
		11: #Toggle Vocal Waveforms
			vocal_waveforms = !vocal_waveforms
			SoundManager.tool_mouse_click.play()
			upper_ui.audio_button.get_popup().set_item_checked(
				upper_ui.audio_button.get_popup().get_item_index(id), vocal_waveforms)
			update_waveforms(song_position)
		
		12: #Toggle Inst Waveforms
			instrumental_waveforms = !instrumental_waveforms
			SoundManager.tool_mouse_click.play()
			upper_ui.audio_button.get_popup().set_item_checked(
				upper_ui.audio_button.get_popup().get_item_index(id), instrumental_waveforms)
			update_waveforms(song_position)
			
		10: #Toggle Hit Sound
			SettingsManager.set_value(SettingsManager.SEC_CHART, "hit_sounds",
			!SettingsManager.get_value(SettingsManager.SEC_CHART, "hit_sounds"))
			SettingsManager.flush()
			SoundManager.tool_mouse_click.play()
			%"Upper UI".get_node("%Audio Button").get_popup().set_item_checked(
				%"Upper UI".get_node("%Audio Button").get_popup().get_item_index(id),
				SettingsManager.get_value(SettingsManager.SEC_CHART, "hit_sounds"))
		
		_:
			print("id: ", id)


func update_ui_usable_state():
	var cant_use: bool = not ChartManager.song
	
	lower_ui.play_button.disabled = cant_use
	lower_ui.difficulty_button.disabled = cant_use
	lower_ui.skip_backward.disabled = cant_use
	lower_ui.skip_forward.disabled = cant_use
	lower_ui.skip_to_beginning.disabled = cant_use
	lower_ui.skip_to_end.disabled = cant_use
	
	upper_ui.edit_button.disabled = cant_use
	upper_ui.test_button.disabled = cant_use
	song_slider.editable = not cant_use
	
## View button item pressed
func view_button_item_pressed(id):
	match id:
		0:
			ChartManager.event_editor = true
			get_tree().change_scene_to_file(Constants.EVENT_EDITOR_SCENE)
		
		1:
			can_chart = false
			%"Upper UI".get_node("%Note Skin Window").popup()
			SoundManager.tool_open_window.play()
		
		3:
			%Grid.zoom = clamp(%Grid.zoom + Vector2.ONE * 0.1, Vector2.ONE * 0.5, Vector2.ONE * 1.5)
			update_grid()
			load_dividers()
			load_section(song_position)
		
		4:
			%Grid.zoom = clamp(%Grid.zoom - Vector2.ONE * 0.1, Vector2.ONE * 0.5, Vector2.ONE * 1.5)
			update_grid()
			load_dividers()
			load_section(song_position)
		
		_:
			print("id: ", id)

## Window button item pressed
func window_button_item_pressed(id):
	match id:
		0: upper_ui.window_button.get_popup().set_item_checked(id, toggle_window_visibility(upper_ui.history_window))
		1: upper_ui.window_button.get_popup().set_item_checked(id, toggle_window_visibility(upper_ui.metadata_window))
		2: upper_ui.window_button.get_popup().set_item_checked(id, toggle_window_visibility(upper_ui.note_type_window))
		3: upper_ui.window_button.get_popup().set_item_checked(id, toggle_window_visibility(upper_ui.audios_window))

func toggle_window_visibility(window: Window) -> bool:
	var ret = not window.visible
	if window.visible:
		window.hide()
		SoundManager.tool_close_window.play()
	else:
		window.popup()
		SoundManager.tool_open_window.play()
	return ret

## Edit button item pressed
func test_button_item_pressed(id):
	match id:
		0: test_current_song(false)
		1: test_current_song(true)
		2:
			SettingsManager.set_value(SettingsManager.SEC_CHART, "start_at_current_position",
			!SettingsManager.get_value(SettingsManager.SEC_CHART, "start_at_current_position"))
			SettingsManager.flush()
			%"Upper UI".get_node("%Test Button").get_popup().set_item_checked(
			%"Upper UI".get_node("%Test Button").get_popup().get_item_index(id), SettingsManager.get_value(SettingsManager.SEC_CHART,
			"start_at_current_position"))
			SoundManager.tool_mouse_click.play()
		
		_: print("id: ", id)

func test_current_song(minimal: bool):
	if not ChartManager.song:
		printerr("(Chart Editor) Cannot test chart as there is no Song")
		return
	if not ResourceLoader.exists(ChartManager.song.scene) and not minimal:
		printerr('(Chart Editor) Cannot test chart as (%s) could not be found' % ChartManager.song.scene)
		return
	
	var scene_to_load: String = "uid://c56g0k7u2k6wo" if minimal else ChartManager.song.scene
	
	GameManager.current_song = ChartManager.song
	GameManager.difficulty = ChartManager.difficulty
	GameManager.freeplay = true
	GameManager.play_mode = GameManager.PLAY_MODE.CHARTING
	Global.change_scene_to(scene_to_load)


func make_shortcut_quick(events: Array) -> Shortcut:
	var shortcut: Shortcut = Shortcut.new()
	shortcut.events = events
	return shortcut


func disable_charting():
	can_chart = false


func open_popup():
	can_chart = false
	SoundManager.tool_open_window.play()


func close_popup():
	enable_can_chart_on_next_frame()
	SoundManager.tool_close_window.play()


func undo():
	if undo_redo.has_undo():
		SoundManager.tool_undo.play()
		undo_redo.undo()
		auto_save()
	
	%"Upper UI".get_node("%Edit Button").get_popup().set_item_disabled(0, !undo_redo.has_undo())
	%"Upper UI".get_node("%Edit Button").get_popup().set_item_disabled(1, !undo_redo.has_redo())


func redo():
	if undo_redo.has_redo():
		SoundManager.tool_redo.play()
		undo_redo.redo()
		auto_save()
	
	%"Upper UI".get_node("%Edit Button").get_popup().set_item_disabled(0, !undo_redo.has_undo())
	%"Upper UI".get_node("%Edit Button").get_popup().set_item_disabled(1, !undo_redo.has_redo())


func auto_save():
	if SettingsManager.get_value(SettingsManager.SEC_CHART, "auto_save"):
		save()


func save():
	# Checks if it's a json
	if (ChartManager.chart.resource_path.is_empty()):
		var path: String = ChartManager.song.difficulties.get(ChartManager.difficulty).get("chart")
		
		if (path.get_extension() == "json"):
			ChartManager.chart.resource_path = str(
				path.get_base_dir(), "/", ChartManager.song.title, "-", ChartManager.difficulty, ".res"
				)
			
			ChartManager.song.difficulties[ChartManager.difficulty]["chart"] = ChartManager.chart.resource_path
			
			print("Chart is json, converting to resource at: ", ChartManager.chart.resource_path)
	
	ResourceSaver.save(ChartManager.song, ChartManager.song.resource_path)
	ResourceSaver.save(ChartManager.chart, ChartManager.chart.resource_path)
	backup_chart = ChartManager.chart


func move_selection(time_distance: float, lane_distance: float):
	var notes: Array = []
	for note in selected_note_nodes:
		notes.append([note.time + time_distance, note.lane + lane_distance, note.length, note.note_type])
		remove_note(note.lane, note.time)
	
	var temp = place_notes(notes)
	selected_notes = temp
	selected_note_nodes = []
	for i in selected_notes:
		selected_note_nodes.append(note_nodes[i - current_visible_notes_L])
	
	moving_notes = false
	SoundManager.tool_note_place.play()


func updated_strums():
	enable_can_chart_on_next_frame()
	update_grid()

func load_waveforms():
	get_tree().call_group(&"waveforms", &"queue_free")
	waveform_nodes.clear()
	
	if not ChartManager.song:
		return
	for id in ChartManager.strum_data.size():
		var track: int = ChartManager.strum_data[id]["track"]
		if track < ChartManager.song.vocals.size() and vocal_tracks.get(track):
			var waveform_data = WaveformDataParser.interpretSound(ChartManager.song.vocals[id])
			if waveform_data:
				@warning_ignore("confusable_local_declaration")
				var waveform: WaveformRenderer = WaveformRenderer.new(waveform_data, 0, Color.MEDIUM_PURPLE, Color.TRANSPARENT)
				
				waveform.visible = false
				$"Waveform Layer".add_child(waveform)
				waveform.current_orientation = WaveformRenderer.orientation.VERTICAL
				waveform.add_to_group(&"waveforms")
				
				waveform_nodes[track] = waveform
		else:
			printerr("(load_waveforms) Track ", track, " does not exist.")


	var waveform: WaveformRenderer = WaveformRenderer.new(WaveformDataParser.interpretSound(ChartManager.song.instrumental), 0, Color.LIME, Color.TRANSPARENT)
	
	waveform.visible = false
	$"Waveform Layer".add_child(waveform)
	waveform.current_orientation = WaveformRenderer.orientation.VERTICAL
	waveform.add_to_group(&"waveforms")
	
	waveform_nodes[-1] = waveform

func update_camera_song_position(instant: bool = false):
	if instant:
		camera_2d.position.y = 360 + time_to_y_position(song_position)
	else:
		camera_2d.position.y = Global.frame_independent_lerp(
			camera_2d.position.y, 360 + time_to_y_position(song_position), 20, get_process_delta_time())

func update_waveforms(time: float = 0):
	
	var time_range: float = conductor.numerator * conductor.get_seconds_per_beat() * 2
	
	if (waveform_nodes.is_empty() or waveform_dirty) and (instrumental_waveforms or vocal_waveforms):
		load_waveforms()
		waveform_dirty = false
		
	for id in waveform_nodes:
		var waveform = waveform_nodes.get(id)
		
		if not waveform:
			return
		
		
		if id == -1:
			waveform.visible = instrumental_waveforms
		else:
			waveform.visible = vocal_waveforms
		
		if not waveform.visible:
			continue
		
		var L: float = max(time, 0)
		var R: float = min(time + time_range, instrumental.stream.get_length())
		waveform.time = (L * 1000) / 7.8
		waveform.duration = (R - L) * 128
		#waveform.duration = (conductor.get_seconds_per_beat() * 1000) / 1.95
		
		waveform.width = time_to_y_position(R) - time_to_y_position(L)
		if id == -1:
			waveform.position = %Grid.get_real_position(Vector2(1, 0))
			waveform.height = %Grid.grid_size.x * (%Grid.columns - 2) * %Grid.zoom.x
		else:
			waveform.position = %Grid.get_real_position(Vector2(
				(ChartManager.strum_data[id]["strums"][1] - ChartManager.strum_data[id]["strums"][0]
				) / 2.0 + ChartManager.strum_data[id]["strums"][0],
				0))
			waveform.height = %Grid.grid_size.x * (
				ChartManager.strum_data[id]["strums"][1] - ChartManager.strum_data[id]["strums"][0]
				) * %Grid.zoom.x
		
		waveform.position.y += time_to_y_position(L)
		waveform.dirty = true


func _on_chart_snap_value_changed(value: float) -> void:
	current_snap = int(value)

func _on_difficulty_button_item_selected(index: int) -> void:
	var _difficulty = lower_ui.get_node("%Difficulty Button").get_popup().get_item_text(index)
	if ChartManager.song.difficulties.keys().has(_difficulty):
		ChartManager.chart = Chart.load(ChartManager.song.difficulties.get(_difficulty).get(SettingsManager.SEC_CHART))
		ChartManager.difficulty = _difficulty
		load_chart(ChartManager.chart)

func _on_history_window_close_requested() -> void:
	%"Upper UI".get_node("%Window Button").get_popup().set_item_checked(0, false)
	SoundManager.tool_close_window.play()

func _on_metadata_window_close_requested() -> void:
	%"Upper UI".get_node("%Window Button").get_popup().set_item_checked(1, false)
	SoundManager.tool_close_window.play()

func _on_metadata_window_updated_icon_texture(path: String) -> void:
	ChartManager.song.icons = load(path)
	auto_save()

func _on_metadata_window_updated_song_artist(text: String) -> void:
	ChartManager.song.artist = text
	auto_save()

func _on_metadata_window_updated_song_charter(text: String) -> void:
	ChartManager.song.charter = text
	auto_save()

func _on_metadata_window_updated_song_name(text: String) -> void:
	ChartManager.song.title = text
	auto_save()

func _on_metadata_window_updated_song_scene(path: String) -> void:
	ChartManager.song.scene = path
	auto_save()

func _on_metadata_window_updated_starting_tempo(tempo: float) -> void:
	ChartManager.song.tempo = tempo
	auto_save()

func _on_metadata_window_updated_scroll_speed(speed: float) -> void:
	ChartManager.chart.scroll_speed = speed
	auto_save()

func _on_metadata_window_selected_time_change(time: float) -> void:
	song_position = time
	start_offset = 0
	toggle_audios(true)

func _on_metadata_window_add_time_change() -> void:
	var time: float = song_position + start_offset
	ChartManager.chart.chart_data["tempos"][time] = conductor.tempo
	ChartManager.chart.chart_data["meters"][time] = [
		conductor.numerator, conductor.denominator
	]
	
	ChartManager.chart.chart_data["tempos"].sort()
	ChartManager.chart.chart_data["meters"].sort()
	%"Upper UI".get_node("%Metadata Window").update_stats()
	auto_save()

func _on_metadata_window_remove_time_change() -> void:
	auto_save()

func update_note(note):
	if note:
		hovered_note = find_note(note.lane, note.time)
	else:
		hovered_note = -1

func update_event(event):
	if event:
		hovered_event = find_event(event.event, event.time)
	else:
		hovered_event = -1

func _on_export_external_popup_file_selected(path: String) -> void:
	ResourceSaver.save(ChartManager.chart, path)
	%"Upper UI".get_node("%Export External Popup").hide()

func set_chart_from_chart(_chart: Chart):
	if !_chart:
		return
	ChartManager.chart.chart_data = backup_chart.chart_data
	ChartManager.chart.scroll_speed = backup_chart.scroll_speed
	ChartManager.chart.offset = backup_chart.offset


func _on_note_skin_window_file_selected(path: String) -> void:
	enable_can_chart_on_next_frame()
	if !FileAccess.file_exists(path):
		printerr("File does not exist is (%s) correct?" % path)
		return
	
	var skin = load(path)
	
	if skin is not NoteSkin:
		printerr("File is not a noteskin.")
		return
	
	note_skin = skin
	SoundManager.tool_open_window.play()

func cut() -> void:
	if selected_notes.size() > 0:
		var temp: Array = []
		for i in selected_notes:
			var note = ChartManager.chart.get_notes_data()[i]
			temp.append([note[0], note[1], note[2], note[3]])
		
		clipboard = temp
		
		add_action("Cut Note(s)", self.remove_notes.bind(selected_notes), self.place_notes.bind(temp))
		selected_notes = []
		SoundManager.tool_note_remove.play()


func copy() -> void:
	clipboard = []
	for note in selected_notes:
		clipboard.append(ChartManager.chart.get_notes_data()[note])
	
	SoundManager.tool_note_place.play()


func paste() -> void:
	if clipboard.is_empty():
		return
	
	var temp = place_notes(clipboard)
	selected_notes = temp
	selected_note_nodes = []
	for i in selected_notes:
		selected_note_nodes.append(note_nodes[i - current_visible_notes_L])
	
	SoundManager.tool_note_place.play()


func delete_stacked_notes() -> void:
	if ChartManager.chart.get_notes_data().size() > 1:
		var i: int = 0
		var deleted: bool = false
		selected_notes = []
		selected_note_nodes = []
		for index in range(ChartManager.chart.get_notes_data().size() - 1):
			var note_a = ChartManager.chart.get_notes_data()[index - i]
			var note_b = ChartManager.chart.get_notes_data()[index - i + 1]
			
			if (is_equal_approx(note_a[0], note_b[0]) and note_a[1] == note_b[1]):
				deleted = true
				remove_note(index - i)
				i += 1
			
			if deleted:
				SoundManager.tool_note_remove.play()


func do_flip():
	add_action("Flipped Notes", self.flip, self.flip)


func flip():
	if selected_notes.size() > 1:
		var _min_lane: int = ChartManager.chart.get_notes_data()[selected_notes[0]][1]
		var _max_lane: int = ChartManager.chart.get_notes_data()[selected_notes[0]][1]
		var temp: Array = []
		for i in selected_notes:
			var note = ChartManager.chart.get_notes_data()[i]
			_min_lane = min(_min_lane, note[1])
			_max_lane = max(_max_lane, note[1])
			temp.append(note)
		
		remove_notes(selected_notes)
		
		selected_notes = []
		selected_note_nodes = []
		var length: int = _max_lane - _min_lane
		var j: int = 0
		for note in temp:
			var lane: int = -(note[1] - _min_lane)
			lane += length
			lane += _min_lane
			temp[j][1] = lane
			
			place_note(note[0], lane, note[2], note[3], true, true)
			j += 1
		
		# I need a cleaner and less intensive way of doing this.
		for note in temp:
			var i: int = find_note(note[1], note[0])
			
			if !selected_notes.has(i):
				selected_notes.append(i)
				selected_note_nodes.append(note_nodes[i - current_visible_notes_L])
		
		selected_notes.sort()
		
		SoundManager.tool_note_place.play()

func increase_length():
	var delta: float = (conductor.numerator * conductor.denominator / chart_snap) * (1.0 / conductor.numerator)
	change_note_lengths(selected_notes,delta )

func decrease_length():
	var delta: float = (conductor.numerator * conductor.denominator / chart_snap) * (1.0 / conductor.numerator)
	change_note_lengths(selected_notes, -delta)


func change_note_lengths(notes: Array, delta: float):
	var action: String = "Changed Note Length(s)"
	undo_redo.create_action(action)
	for i in notes:
		var length: float = ChartManager.chart.get_notes_data()[i][2]
		undo_redo.add_do_method(self.change_length.bind(i, length + delta))
		undo_redo.add_do_property(note_nodes[i - current_visible_notes_L], "length", length + delta)
		undo_redo.add_do_method(%"Note Stretch".play)
		undo_redo.add_undo_method(self.change_length.bind(i, length))
		undo_redo.add_undo_property(note_nodes[i - current_visible_notes_L], "length", length)
	
	undo_redo.add_do_reference(%"Upper UI".get_node("%History Window").add_action(action))
	undo_redo.commit_action()


func change_length(i: int, length: float) -> void:
	ChartManager.chart.chart_data["notes"][i][2] = max(length, 0)


func select_area(L: int, R: int, lane_a, lane_b = null):
	selected_notes = range(L, R + 1)
	selected_notes = selected_notes.filter(func(i):
		var lane: int = ChartManager.chart.get_notes_data()[i][1]
		return (lane >= lane_a and lane <= lane_b))
	
	update_selected_notes()
	if selected_notes.size() > 0:
		SoundManager.tool_mouse_click.play()


func add_action(action: String, do_method: Callable, undo_method: Callable):
	undo_redo.create_action(action)
	undo_redo.add_do_method(do_method)
	undo_redo.add_do_reference(%"Upper UI".get_node("%History Window").add_action(action))
	undo_redo.add_undo_method(undo_method)
	undo_redo.commit_action()
	
	%"Upper UI".get_node("%Edit Button").get_popup().set_item_disabled(0, !undo_redo.has_undo())
	%"Upper UI".get_node("%Edit Button").get_popup().set_item_disabled(1, !undo_redo.has_redo())


func select_all():
	if ChartManager.chart.get_notes_data().is_empty():
		return
	
	selected_notes = range(ChartManager.chart.get_notes_data().size())
	selected_note_nodes = get_tree().get_nodes_in_group(&"notes")
	SoundManager.tool_mouse_click.play()


func deselect_all():
	if selected_notes.is_empty():
		return
	
	selected_notes = []
	selected_note_nodes = []
	SoundManager.tool_mouse_click.play()


func update_selected_notes() -> void:
	if selected_notes.is_empty():
		return
	
	if selected_notes.front() > current_visible_notes_R:
		return
	
	if selected_notes.back() < current_visible_notes_L:
		return
	
	selected_note_nodes = []
	for i in range(current_visible_notes_L, current_visible_notes_R):
		if selected_notes.has(i):
			selected_note_nodes.append(note_nodes[i - current_visible_notes_L])
		else:
			continue


func _on_conductor_new_numerator(_numerator: int) -> void:
	update_grid()
	load_dividers()

func _on_conductor_new_denominator(_denominator: int) -> void:
	update_grid()
	load_dividers()


func set_note_type(note_type):
	current_note_type = note_type

func _on_note_type_window_close_requested() -> void:
	%"Upper UI".get_node("%Window Button").get_popup().set_item_checked(2, false)
	SoundManager.tool_close_window.play()
