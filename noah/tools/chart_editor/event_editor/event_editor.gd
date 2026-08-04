extends ChartEditor

var TRACK_BUTTON = load("uid://dguo6hi3l0pxv")

var current_event_time: float
var current_event: String
var editing: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	%"Upper UI".get_node("%View Button").get_popup().set_item_disabled(1, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	start_offset = clampf(start_offset, 0, start_offset)
	
	var can_interact_with_chart: bool = can_chart and not is_mouse_over_any_ui() and ChartManager.chart
	
	if ChartManager.song:
		if %Instrumental.playing:
			song_position = %Instrumental.get_playback_position() - start_offset
			%"Song Slider".value = song_position
			
			for strum in ChartManager.strum_data.size():
				var track = ChartManager.strum_data[strum]["track"]
				if track < vocal_tracks.size():
					%Vocals.get_stream_playback().set_stream_volume(vocal_tracks[track], linear_to_db(1))
	
	var axis: int = int(Input.is_action_just_pressed("mouse_scroll_up")) - int(Input.is_action_just_pressed("mouse_scroll_down"))
	if axis:
		if can_interact_with_chart and not Input.is_action_pressed("control"): #song scrubbing
			if not instrumental.stream_paused:
				toggle_audios(true)
			song_position += conductor.seconds_per_beat * axis
			song_position = snapped(song_position - conductor.offset, conductor.seconds_per_beat) + conductor.offset
			song_position = clamp(song_position, start_offset, instrumental.stream.get_length())
			song_slider.value = song_position
		else: #snap scrubbing
			current_snap += axis
			chart_snap = SNAPS[current_snap % SNAPS.size()]
			lower_ui.chart_snap.value = chart_snap
	
	conductor.time = song_position
	
	if ChartManager.chart:
		var time: float = song_position + start_offset
		$Conductor.tempo = ChartManager.chart.get_tempo_at(song_position + start_offset)
		var meter = ChartManager.chart.get_meter_at(song_position + start_offset)
		$Conductor.numerator = meter[0]
		$Conductor.denominator = meter[1]
		$Conductor.offset = ChartManager.chart.get_tempo_time_at(time) + ChartManager.chart.offset
		$"Grid Layer/Parallax2D".scroll_offset.x = time_to_y_position($Conductor.offset - ChartManager.chart.offset)
		update_camera_song_position(instrumental.playing)
	
	
	var grid_offset: Vector2 = %Grid.position + $"Grid Layer".offset + $"Grid Layer/Parallax2D".scroll_offset
	var mouse_position: Vector2 = get_global_mouse_position() - grid_offset
	var grid_position: Vector2 = %Grid.get_grid_position(mouse_position)
	var snapped_position: Vector2i = Vector2i(
			%Grid.get_grid_position(mouse_position, %Grid.grid_size * Vector2(conductor.numerator * conductor.denominator / chart_snap, 1)).floor()
			)
	
	$"Grid Layer/Parallax2D".repeat_size.x = %Grid.get_size().x
	
	if Input.is_action_just_pressed(&"mouse_left"):
		if !Input.is_action_pressed(&"control"):
			if is_mouse_over_grid():
				if can_interact_with_chart:
					if (((snapped_position.y - 1) >= 0 and (snapped_position.y) < %Grid.rows)):
						var event: String = ChartManager.event_tracks[snapped_position.y - 1]
						var time: float = grid_position_to_time(snapped_position, true)
						time += ChartManager.chart.get_tempo_time_at(song_position + start_offset)
						
						if time <= %Instrumental.stream.get_length():
							if !is_event_at(event, time):
								if Constants.EVENT_DATA.has(event):
									current_event = event
									current_event_time = time
									editing = -1
									if Constants.EVENT_DATA.get(event).has("parameters"):
										%"Event Creator".popup()
									else:
										add_action("Placed Event", self.place_event.bind(time, event, [], true),
										self.remove_note.bind(event, time))
										%"Note Place".play()
										
							else:
								var i: int = find_event(event, time)
								if selected_notes.has(i):
									moving_notes = true
									start_time = time
								else:
									selected_notes = [i]
									selected_note_nodes = [event_nodes[i - current_visible_events_L]]
		else:
			if can_chart:
				bounding_box = true
				start_box = get_global_mouse_position()
	
	if Input.is_action_just_pressed(&"mouse_middle") and is_mouse_over_grid() and can_chart:
		if (((snapped_position.y - 1) >= 0 and (snapped_position.y - 1) < %Grid.rows)):
				if hovered_event != -1:
					var event: String = ChartManager.chart.chart_data["events"][hovered_event][1]
					var time: float = ChartManager.chart.chart_data["events"][hovered_event][0]
					
					if (Constants.EVENT_DATA.has(event)
					and Constants.EVENT_DATA.get(event).has("parameters")):
							current_event = event
							current_event_time = time
							editing = hovered_event
							%"Event Creator".popup()
	
	if Input.is_action_pressed(&"mouse_right") and not Input.is_action_pressed(&"control") and is_mouse_over_grid():
		if can_chart and hovered_event != -1:
			var i: int = hovered_event
			var event = ChartManager.chart.chart_data.events[i]
			var event_name: String = event[1]
			var parameters = event[2]
			
			add_action("Removed Event", self.remove_note.bind(i),
			self.place_event.bind(event[0], event_name, parameters, true))
			%"Note Remove".play()
			
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
			
			hovered_event = -1
			
			if SettingsManager.get_value(SettingsManager.SEC_CHART, "auto_save"):
				save()
	
	if Input.is_action_pressed(&"mouse_left") and !Input.is_action_pressed(&"control") and is_mouse_over_grid():
		if !%Instrumental.playing:
			if can_chart:
				## Song Position Slider
				if grid_position.y < 1 and grid_position.y >= 0:
					if Input.is_action_pressed(&"shift"):
						start_offset = grid_position_to_time(snapped_position, true) + conductor.offset - song_position
					else:
						start_offset = grid_position_to_time(grid_position) + conductor.offset - song_position
				
				if ((grid_position.y - 1) > 0 and (grid_position.y - 1) < %Grid.rows):
					if moving_notes:
						var cursor_time = grid_position_to_time(snapped_position, true)
						cursor_time += ChartManager.chart.get_tempo_time_at(song_position + start_offset)
						
						var time_distance = cursor_time - start_time
						changed_length = true
						
						if true:
							if changed_length:
								var j: int = 0
								for i in selected_notes:
									var node = selected_note_nodes[j]
									var time: float = node.time
									
									node.position.x = time_to_y_position((node.time + time_distance)
									) + $"Grid Layer".offset.x + (%Grid.grid_size.x * %Grid.zoom.x / 2)
									j += 1
								
								if SettingsManager.get_value(SettingsManager.SEC_CHART, "auto_save"):
									save()
								
								moved_time_distance = time_distance
	
	if Input.is_action_just_released(&"mouse_left"):
		if bounding_box:
			bounding_box = false
			
			var rect = Rect2(start_box, get_global_mouse_position() - start_box).abs()
			# Added leniency since notes are centered from the top
			var pos_1: Vector2 = %Grid.get_grid_position(rect.position - grid_offset) - Vector2(0, 1)
			var pos_2: Vector2 = %Grid.get_grid_position(rect.end - grid_offset) - Vector2(0, 1)
			
			var time_a: float = grid_position_to_time(pos_1, true)
			var time_b: float = grid_position_to_time(pos_2, true)
			var lane_a: int = int(pos_1.y)
			var lane_b: int = int(pos_2.y)
			
			var events: Array = []
			
			for i in range(max(lane_a, 0), min(lane_b + 1, ChartManager.event_tracks.size())):
				events.append(ChartManager.event_tracks[i])
			
			var L: int = bsearch_left_range(ChartManager.chart.get_events_data(), time_a)
			var R: int = bsearch_right_range(ChartManager.chart.get_events_data(), time_b)
			
			if (L == R + 1):
				L -= 1
			L = max(0, L)
			add_action("Selected Area", self.select_area.bind(L, R, events), self.deselect_all)
		
		if moving_notes:
			add_action("Moved Events(s)", self.move_selection.bind(moved_time_distance, 0),
			self.move_selection.bind(-moved_time_distance, 0))
	
	if Input.is_action_just_released(&"control"):
		bounding_box = false
	
	queue_redraw()


func update_camera_song_position(instant: bool = false):
	if instant:
		camera_2d.position.x = 640 + time_to_y_position(song_position)
	else:
		camera_2d.position.x = Global.frame_independent_lerp(
			camera_2d.position.x, 640 + time_to_y_position(song_position), 20, get_process_delta_time())

func is_mouse_over_grid() -> bool:
	var screen_mouse_pos = get_global_mouse_position() - Vector2(camera_2d.position.x, 0)
	return screen_mouse_pos.x > -512 and screen_mouse_pos.x < 640

func _draw() -> void:
	var rect: Rect2
	
	## Box when you're holding control
	if bounding_box:
		rect = Rect2(start_box, get_global_mouse_position() - start_box).abs()
		draw_rect(rect, box_color)
	
	if ChartManager.chart:
		## The offset the grid has from the normal canvas layer
		var grid_offset: Vector2 = %Grid.position + $"Grid Layer".offset + $"Grid Layer/Parallax2D".scroll_offset
		var mouse_position: Vector2 = get_global_mouse_position() - grid_offset
		var grid_position: Vector2i = Vector2i(%Grid.get_grid_position(mouse_position))
		var snapped_position: Vector2i = Vector2i(
			%Grid.get_grid_position(mouse_position, %Grid.grid_size * Vector2(conductor.numerator * conductor.denominator / chart_snap, 1))
			)
		
		## Song Start Offset Marker
		rect = Rect2(grid_offset - $"Grid Layer/Parallax2D".scroll_offset +
		+ Vector2(time_to_y_position(song_position - ChartManager.chart.offset + start_offset) - 2, %Grid.get_real_position(Vector2(0, 0)).y), \
		%Grid.get_real_position(Vector2(0, %Grid.rows)) - %Grid.get_real_position(Vector2(0, 0)) + Vector2(4, 0))
		draw_rect(rect, current_time_color)
		
		# The box at the start of the marker
		rect = Rect2(grid_offset - $"Grid Layer/Parallax2D".scroll_offset
		+ Vector2(time_to_y_position(song_position - ChartManager.chart.offset + start_offset) - 4, %Grid.get_real_position(Vector2(0, 0)).y), \
		%Grid.get_real_position(Vector2(0, 1)) - %Grid.get_real_position(Vector2(0, 0)) + Vector2(8, 0))
		draw_rect(rect, current_time_color)
		
		## Hover Box
		if (grid_position.y >= 1 and grid_position.y < %Grid.rows) and not is_mouse_over_any_ui():
			rect = Rect2(%Grid.get_real_position(snapped_position, %Grid.grid_size * Vector2(conductor.numerator * conductor.denominator / chart_snap, 1)) + grid_offset, \
			%Grid.grid_size * %Grid.zoom * Vector2(conductor.numerator * conductor.denominator / chart_snap, 1))
			draw_rect(rect, hover_color)
		
		## Event Highlighting
		for i in selected_notes.size():
			var note = selected_note_nodes[i]
			if note:
				var length: float = 1.0 / $Conductor.numerator
				length *= %Grid.grid_size.x * %Grid.zoom.x
				length *= $Conductor.numerator
				rect = Rect2(note.global_position - (%Grid.grid_size / 2 * %Grid.zoom),
				Vector2(%Grid.grid_size.x * %Grid.zoom.x, length))
				draw_rect(rect, selected_color)

## View button item pressed
func view_button_item_pressed(id):
	match id:
		0:
			ChartManager.event_editor = false
			get_tree().change_scene_to_file(Constants.CHART_EDITOR_SCENE)
		
		1:
			can_chart = false
			%"Note Skin Window".popup()
			%"Open Window".play()
		
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


## Loads all the notes and waveforms for the next two waveforms.
func load_section(time: float):
	if ChartManager.chart.get_events_data().is_empty():
		return
	
	var _range: float = $Conductor.seconds_per_beat * $Conductor.numerator * 2 / %Grid.zoom.y
	var L: int = bsearch_left_range(ChartManager.chart.get_events_data(), time - _range)
	var R: int = bsearch_right_range(ChartManager.chart.get_events_data(), time + _range)
	
	if selected_notes.size() > 0:
		L = min(selected_notes[0], L)
		R = max(R, selected_notes[selected_notes.size() - 1])
	
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


func update_note_position(node: Node2D):
	if node is ChartEvent:
		node.position = Vector2(time_to_y_position(node.time) + %Grid.grid_size.x * %Grid.zoom.x / 2,
		%Grid.get_real_position(Vector2(0, 1.5 + ChartManager.event_tracks.find(node.event))).y)
		node.position += $"Grid Layer".offset
		node.grid_size = (%Grid.grid_size * %Grid.zoom)
		node.update()
	else:
		printerr(node.get_class(), " isn't a valid node.")


func load_dividers():
	get_tree().call_group(&"dividers", &"queue_free")
	for i in range($Conductor.numerator):
		var rect = ColorRect.new()
		var size: float = 4 if i == 0 else 2
		
		rect.color = divider_color
		rect.size = Vector2(size, %Grid.get_size().y)
		rect.position = %Grid.position
		rect.position.y -= %Grid.get_size().y / 2
		rect.position.x += (%Grid.grid_size.x * %Grid.zoom.x) * $Conductor.numerator * i
		rect.position.x -= rect.size.x / 2
		
		$"Grid Layer/Parallax2D".add_child(rect)
		rect.add_to_group(&"dividers")
	
	for i in [0, 1, %Grid.rows]:
		var rect = ColorRect.new()
		var size: float = 2
		
		rect.color = divider_color
		rect.size = Vector2(%Grid.get_size().x, size)
		rect.position = %Grid.position
		rect.position.y -= %Grid.get_size().y / 2
		rect.position.y += (%Grid.grid_size.y * %Grid.zoom.y)* i
		
		$"Grid Layer/Parallax2D".add_child(rect)
		rect.add_to_group(&"dividers")
	
	var times: Array = [%Instrumental.stream.get_length()]
	times.append_array(ChartManager.chart.get_tempos_data().keys())
	times.erase(0.0)
	for i in times:
		var rect = ColorRect.new()
		var size: float = 2
		
		rect.size = Vector2(size, %Grid.get_size().y)
		rect.position = %Grid.position
		rect.position.y -= %Grid.get_size().y / 2
		rect.position.x = time_to_y_position(i)
		rect.position.x -= rect.size.x / 2
		rect.position += %Grid.position + $"Grid Layer".offset
		rect.color = time_change_color
		
		self.add_child(rect)
		rect.add_to_group(&"dividers")

func load_chart(file: Chart, ghost: bool = false):
	super(file, ghost)
	ChartManager.event_tracks = []
	for event in file.get_events_data():
		if !ChartManager.event_tracks.has(event[1]):
			ChartManager.event_tracks.append(event[1])
	update_grid()
	_on_event_tracks_ready()

func update_grid():
	%Grid.columns = conductor.numerator * conductor.denominator
	%Grid.rows = 1 + ChartManager.event_tracks.size()
	
	$"UI/Event Tracks".position.y = -%Grid.get_size().y / 2 - 4
	$"UI/Event Tracks".size.y = 0
	#$"UI/Event Tracks".custom_minimum_size.y = %Grid.get_size().y + (ChartManager.event_tracks.size() * 1)
	
	get_tree().call_group(&"tracks",  &"queue_free")
	for track in ChartManager.event_tracks:
		var track_instance = TRACK_BUTTON.instantiate()
		
		track_instance.event = track
		
		%"Event Tracks".add_child(track_instance)
		
		track_instance.add_to_group(&"tracks")
		track_instance.connect(&"removed", self.remove_track.bind(track_instance))
	
	await Engine.get_main_loop().process_frame
	$"UI/Event Tracks".size.y = %Grid.get_size().y + (ChartManager.event_tracks.size() * 1)


func remove_track(node):
	var event: String = node.event
	node.queue_free()
	
	ChartManager.event_tracks.erase(event)
	ChartManager.chart.chart_data["events"] = ChartManager.chart.chart_data["events"].filter(
		func(_event): return _event[1] != event
	)
	
	_on_event_tracks_ready()
	get_tree().call_group(&"events", &"queue_free")
	event_nodes = []
	selected_notes = []
	selected_note_nodes = []
	current_visible_events_L = -1
	current_visible_events_R = -1
	load_section(song_position)
	%"Mouse Click".play()


func _on_event_tracks_ready() -> void:
	if ChartManager.chart:
		await Engine.get_main_loop().process_frame
		update_grid()
		load_dividers()

## This assumes that the tempo and meter dictionaries are sorted
func time_to_y_position(time: float) -> float:
	var tempo_data: Dictionary = ChartManager.chart.get_tempos_data()
	var _offset: float = -ChartManager.chart.offset
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
		y_offset += %Grid.get_real_position(Vector2((R - L) / (60.0 / tempo) * meter[0], 0)).x
		
		L = R
		i += 1
	
	return y_offset

## This assumes that the tempo and meter dictionaries are sorted
func grid_position_to_time(p: Vector2, factor_in_snap: bool = false) -> float:
	var time: float = song_position + start_offset
	var meter: Array = ChartManager.chart.get_meter_at(time)
	var L: float = ChartManager.chart.get_tempo_time_at(time)
	var yR: float = p.x * %Grid.grid_size.x * %Grid.zoom.x
	if factor_in_snap:
		yR *= meter[0] * meter[1] / chart_snap
	
	var seconds_per_beat: float = 60.0 / ChartManager.chart.get_tempos_data()[L]
	var output: float = yR / (%Grid.grid_size.x * %Grid.zoom.x * meter[0]) * seconds_per_beat
	
	return output


func is_event_at(_name: String, time: float) -> bool:
	return (find_event(_name, time) != -1)

## Returns the index of the given event in the events list.
func find_event(_name: String, time: float) -> int:
	var L: int = bsearch_left_range(ChartManager.chart.get_events_data(), time - 0.00001)
	var R: int = bsearch_right_range(ChartManager.chart.get_events_data(), time + 0.00001)
	
	if (L == -1 or R == -1):
		return -1
	
	# Just so I don't have to make a new return case because I'm lazy
	if (L == R + 1):
		L -= 1
	
	for i in range(L, R + 1):
		var event: Array = ChartManager.chart.get_events_data()[i]
		if (event[1] == _name):
			if is_equal_approx(event[0], time):
				return i
	
	return -1

## Giving only 1 parameter removes the note at the given index
func remove_note(_name, time: float = -1):
	var i: int
	if time != -1:
		i = find_event(_name, time)
	else:
		i = _name
	
	if i <= -1:
		return
	
	if (i - current_visible_events_L) < event_nodes.size() and (i - current_visible_events_L) >= 0:
		event_nodes[i - current_visible_events_L].queue_free()
		event_nodes.remove_at(i - current_visible_events_L)
		current_visible_events_R -= 1
	
	#if selected_notes.size() > 0:
		#for j in range(selected_notes.size()):
			#var note: int = selected_notes[j]
			#if note > i:
				#selected_notes[j] -= 1
	
	ChartManager.chart.chart_data["events"].remove_at(i)

## In the event editor, lane_a is a list of event names
func select_area(L: int, R: int, lane_a, lane_b = null):
	selected_notes = range(L, R + 1)
	selected_note_nodes = []
	
	var _i: int = 0
	for i in range(selected_notes.size()):
		var event: String = ChartManager.chart.get_events_data()[selected_notes[_i]][1]
		if !lane_a.has(event):
			selected_notes.remove_at(_i)
			_i -= 1
		
		_i += 1
	
	for i in selected_notes:
		selected_note_nodes.append(event_nodes[i - current_visible_events_L])
	
	if selected_notes.size() > 0:
		%"Note Place".play()


func move_selection(time_distance: float, lane_distance: float):
	var events: Array = []
	for event in selected_note_nodes:
		events.append([event.time + time_distance, event.event, event.parameters])
		remove_note(event.event, event.time)
	
	var temp = place_notes(events)
	selected_notes = temp
	selected_note_nodes = []
	for i in selected_notes:
		selected_note_nodes.append(event_nodes[i - current_visible_events_L])
	
	moving_notes = false
	%"Note Place".play()

# Returns the indexes of the new notes
func place_notes(events: Array) -> Array:
	var indices: Array = []
	for event in events:
		place_event(event[0], event[1], event[2], true)
	
	# Surely there's a cleaner way to do this
	for event in events:
		var i: int = find_event(event[1], event[0])
		if i != -1:
			indices.append(i)
	
	indices.sort()
	return indices


func remove_notes(events: Array):
	var i: int = 0
	for event in events:
		var _event = ChartManager.chart.get_events_data()[event - i]
		remove_note(_event[1], _event[0])
		i += 1


func cut() -> void:
	if selected_notes.size() > 0:
		var temp: Array = []
		for i in selected_notes:
			var event = ChartManager.chart.get_events_data()[i]
			temp.append([event[0], event[1], event[2]])
		
		add_action("Cut Note(s)", self.remove_notes.bind(selected_notes), self.place_notes.bind(temp))
		selected_notes = []
		%"Note Remove".play()


func copy() -> void:
	clipboard = []
	for note in selected_notes:
		clipboard.append(ChartManager.chart.get_events_data()[note])
	%"Note Place".play()


func paste() -> void:
	if clipboard.is_empty():
		return
	
	var temp = place_notes(clipboard)
	selected_notes = temp
	selected_note_nodes = []
	for i in selected_notes:
		selected_note_nodes.append(event_nodes[i - current_visible_events_L])
	%"Note Place".play()


func delete_stacked_notes() -> void:
	if ChartManager.chart.get_events_data().size() > 1:
		var i: int = 0
		var deleted: bool = false
		selected_notes = []
		selected_note_nodes = []
		for index in range(ChartManager.chart.get_events_data().size() - 1):
			var note_a = ChartManager.chart.get_events_data()[index - i]
			var note_b = ChartManager.chart.get_events_data()[index - i + 1]
			
			if (is_equal_approx(note_a[0], note_b[0]) and note_a[1] == note_b[1]):
				deleted = true
				remove_note(index - i)
				i += 1
			
			if deleted:
				%"Note Remove".play()


func select_all():
	selected_notes = range(current_visible_events_L, current_visible_events_R + 1)
	selected_note_nodes = get_tree().get_nodes_in_group(&"events")
	if selected_notes.size() > 0:
		%"Note Place".play()


func _on_event_parameters_about_to_popup() -> void:
	can_chart = false
	for node in %"Event Parameters".get_children():
		node.queue_free()
	
	var parameters: Array = []
	
	if hovered_event != -1:
		parameters = ChartManager.chart.chart_data["events"][hovered_event][2]
		%"Place Event".text = "Edit Event"
	else:
		%"Place Event".text = "Place Event"
	
	%"Event Name".text = current_event.capitalize()
	var parameter_names: Array = Constants.EVENT_DATA[current_event]["parameters"]
	
	var i: int = 0
	for _name in parameter_names:
		var line_edit: LineEdit = LineEdit.new()
		
		line_edit.placeholder_text = _name
		if (i < parameters.size()):
			line_edit.text = str(parameters[i])
		
		%"Event Parameters".add_child(line_edit)
		i += 1
	
	%"Open Window".play()


func _on_place_event_pressed() -> void:
	var parameters: Array = []
	for node in %"Event Parameters".get_children():
		parameters.append(node.text)
	
	if editing == -1:
		add_action("Placed Event", self.place_event.bind(current_event_time, current_event, parameters, true),
		self.remove_note.bind(current_event, current_event_time))
		%"Note Place".play()
		%"Event Creator".hide()
	else:
		var action: String = "Edit Event"
		undo_redo.create_action(action)
		var temp: Array = event_nodes[editing - current_visible_events_L].parameters
		undo_redo.add_do_property(event_nodes[editing - current_visible_events_L],
		"parameters", parameters)
		undo_redo.add_do_method(self.change_parameters.bind(editing, parameters))
		undo_redo.add_undo_property(event_nodes[editing - current_visible_events_L],
		"parameters", temp)
		undo_redo.add_undo_method(self.change_parameters.bind(editing, temp))
		undo_redo.add_do_reference(%"Upper UI".get_node("%History Window").add_action(action))
		undo_redo.commit_action()
		%"Note Place".play()
		%"Event Creator".hide()
	
	auto_save()


func change_parameters(i: int, parameters: Array) -> void:
	ChartManager.chart.chart_data["events"][i][2] = parameters


func _on_add_track_pressed() -> void:
	%"Add Track Window".popup()
	%"Mouse Click".play()


func _on_window_about_to_popup() -> void:
	can_chart = false
	%"Event Option".clear()
	var events: Array = Constants.EVENT_DATA.keys()
	events = events.filter(func(_name): return !ChartManager.event_tracks.has(_name))
	
	for event in events:
		%"Event Option".add_item(event)
		var icon: String = Constants.EVENT_DATA.get(event, {}).get("texture", "")
		if ResourceLoader.exists(icon):
			%"Event Option".set_item_icon(%"Event Option".item_count - 1, load(icon))
			%"Event Option".get_popup().set_item_icon_max_width(%"Event Option".item_count - 1, 32)


func _on_add_event_track_pressed() -> void:
	if %"Event Option".selected != -1:
		var event: String = %"Event Option".get_item_text(%"Event Option".get_selected_id())
		ChartManager.event_tracks.append(event)
		
		update_grid()
		load_dividers()
	
	%"Add Track Window".hide()
	close_popup()
	load_section(song_position)


func _on_add_track_window_close_requested() -> void:
	%"Add Track Window".hide()


func _on_export_external_popup_canceled() -> void:
	pass # Replace with function body.


func _on_note_skin_window_canceled() -> void:
	pass # Replace with function body.


func _on_note_type_window_selected_note_type(type: Variant) -> void:
	pass # Replace with function body.


func load_waveforms():
	return


func update_waveforms(time: float = 0):
	return
