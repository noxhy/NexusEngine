extends Node2D

const label_font: Font = preload("res://assets/fonts/Bold Normal Text.ttf")
const note_preload = preload("res://scenes/instances/playstate/note/note.tscn")
const note_skin = preload("res://assets/sprites/playstate/developer/developer_note_skin.tres")

@export var song_data: Song = null

@export_group("Colors")
@export var hover_color = Color(1, 1, 1, 0.5)
@export var divider_color = Color(1, 1, 1, 0.5)
@export var current_time_color = Color(1, 0, 0, 1)

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	song_speed = 1.0
	update_grid()
	if ChartHandeler.song != null: load_song(ChartHandeler.song, ChartHandeler.difficulty)
	else: load_song(load("res://assets/songs/playable songs/fresh/fresh_erect.tres"), "nightmare")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if start_offset < 0: start_offset = 0
	
	if song_data != null:
		
		if %Instrumental.playing:
			
			song_position = %Instrumental.get_playback_position() - start_offset
			%"Song Slider".value = song_position
		else:
			
			if Input.is_action_just_pressed("mouse_scroll_up"):
				
				song_position -= $Conductor.seconds_per_beat
				song_position = snapped(song_position, $Conductor.seconds_per_beat)
				song_position = clamp(song_position, start_offset, %Instrumental.stream.get_length())
			
			if Input.is_action_just_pressed("mouse_scroll_down"):
				
				song_position += $Conductor.seconds_per_beat
				song_position = clamp(song_position, start_offset, %Instrumental.stream.get_length())
	
	if chart != null:
		
		current_tempo = chart.get_tempo_at(song_position + start_offset)
		$Conductor.tempo = current_tempo
		var meter = chart.get_meter_at(song_position + start_offset)
		current_beats_per_measure = meter[0]
		current_steps_per_measure = meter[1]
		$Camera2D.position.y = 360 + time_to_y_position(song_position)
	
	%"Current Time Label".text = float_to_time(song_position) + "+" + float_to_time(start_offset)
	# %"Time Left Label".text = "-" + float_to_time(%Instrumental.stream.get_length() - song_position)
	
	if Input.is_action_just_pressed("ui_accept"): _on_play_button_toggled(!%Instrumental.stream_paused)
	
	var measure_height = %Grid/TextureRect.size.y * %Grid/TextureRect.scale.y
	$"Grid Layer/ParallaxLayer".motion_mirroring.y = measure_height
	
	var grid_offset: Vector2 = %Grid.position + $"Grid Layer".offset
	var mouse_position: Vector2 = get_global_mouse_position() - grid_offset
	var grid_position: Vector2 = %Grid.get_grid_position(mouse_position)
	
	var screen_mouse_position = get_global_mouse_position() - Vector2(0, $Camera2D.position.y - 360)
	
	if Input.is_action_pressed("mouse_left"):
		
		if !Input.is_action_pressed("control"):
			
			if screen_mouse_position.y > 64 && screen_mouse_position.y < 640:
				
				if !%Instrumental.playing:
					
					## Song Position Slider
					if int(grid_position.x) == (%Grid.columns - 1):
						
						%"Time Left Label".text = str(grid_position)
						start_offset = grid_position_to_time(grid_position) - song_position
	
	if Input.is_action_just_pressed("mouse_left"):
		
		if !Input.is_action_pressed("control"):
			
			if screen_mouse_position.y > 64 && screen_mouse_position.y < 640:
				
				print(grid_position_to_time((grid_position)))
	
	if Input.is_action_pressed("ui_text_delete"):
		
		GameHandeler.play_mode = GameHandeler.PLAY_MODE.CHARTING
		GameHandeler.difficulty = current_difficulty
		Global.change_scene_to("res://scenes/playstate/chart_tester.tscn")
	
	queue_redraw()


func _draw() -> void:
	
	if chart != null:
		
		# The offset the grid has from the normal canvas layer
		var grid_offset: Vector2 = %Grid.position + $"Grid Layer".offset
		var mouse_position: Vector2 = get_global_mouse_position() - grid_offset
		var grid_position: Vector2i = Vector2i(%Grid.get_grid_position(mouse_position))
		
		var measure_height = %Grid/TextureRect.size.y * %Grid/TextureRect.scale.y
		
		## Song Start Offset Marker
		var time_to_y: Vector2
		var rect: Rect2 = Rect2(grid_offset + %Grid.get_real_position(Vector2(1, 0)) + Vector2(0, time_to_y_position(song_position + start_offset) - 2), \
		%Grid.get_real_position(Vector2(%Grid.columns, 0)) - %Grid.get_real_position(Vector2(1, 0)) + Vector2(0, 4))
		draw_rect(rect, current_time_color)
		# The box at the end of the marker
		rect = Rect2(grid_offset + %Grid.get_real_position(Vector2(%Grid.columns - 1, 0)) + Vector2(0, time_to_y_position(song_position + start_offset) - 4), \
		%Grid.get_real_position(Vector2(1, 0)) - %Grid.get_real_position(Vector2(0, 0)) + Vector2(0, 8))
		draw_rect(rect, current_time_color)
		
		## Hover Box
		if (grid_position.x >= 0 && grid_position.x < %Grid.columns):
			
			rect = Rect2(%Grid.get_real_position(grid_position) + grid_offset, %Grid.grid_size * %Grid.zoom)
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
				
				draw_string(label_font, \
				grid_offset + %Grid.get_real_position(Vector2(%Grid.columns - 1, 0)) + Vector2(0, time_to_y.y + 16), \
				str($Conductor.get_beat_at(time_at_row) + 1), HORIZONTAL_ALIGNMENT_RIGHT, %Grid.grid_size.x * %Grid.zoom.x, 16)
		
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
			
			var end_strum = ChartHandeler.strum_data.get(strum_name).strums[ChartHandeler.strum_data.get(strum_name).strums.size() - 1]
			
			## Measure Divider
			rect = Rect2(grid_offset + %Grid.get_real_position(Vector2(end_strum + 2, time_to_y.y)) - Vector2(1, 2), \
			%Grid.get_real_position(Vector2(0, %Grid.rows * 2)) - %Grid.get_real_position(Vector2(0, 0)) + Vector2(2, 2))
			draw_rect(rect, divider_color)


func update_grid():
	
	%Grid.columns = 2 + ChartHandeler.strum_count
	%Grid.rows = current_steps_per_measure


func load_song(song: Song, difficulty: String = "null"):
	
	ChartHandeler.song = song
	song_data = song
	if difficulty == "null": difficulty = song_data.difficulties.keys()[0]
	current_difficulty = difficulty
	var difficulty_data: Dictionary = song.difficulties.get(difficulty)
	chart = load(difficulty_data.chart)
	scene = song.scene if !difficulty_data.has("scene") else difficulty_data.scene
	ChartHandeler.difficulty = difficulty
	play_audios(0.0)
	
	%"Song Slider".max_value = %Instrumental.stream.get_length()
	%"Song Slider".value = 0.0
	current_tempo = chart.get_tempo_at(0.0)
	var meter = chart.get_meter_at(0.0)
	current_beats_per_measure = meter[0]
	current_steps_per_measure = meter[1]
	$Conductor.offset = chart.offset
	
	load_chart(chart)


func load_chart(file: Chart):
	
	var directions = ["left", "down", "up", "right"]
	
	for note in file.get_notes_data():
		
		var note_instance = note_preload.instantiate()
		
		note_instance.chart_note = true
		note_instance.tempo = file.get_tempo_at(note[0])
		var meter = file.get_meter_at(note[0])
		note_instance.seconds_per_beat = 60.0 / note_instance.tempo
		
		note_instance.time = note[0]
		note_instance.length = note[2]
		note_instance.note_type = note[3]
		note_instance.position = Vector2(%Grid.get_real_position(Vector2(1.5 + note[1], 0)).x, time_to_y_position(note[0]) + %Grid.grid_size.y * %Grid.zoom.y / 2)
		note_instance.grid_size = (%Grid.grid_size * %Grid.zoom)
		# note_instance.scale = %Grid.grid_size * (%Grid.rows / meter[1]) / Vector2(64, 64)
		# I am treating scroll speed as a multiplier that would've acted like the grid size for
		# sizing purposes
		note_instance.scroll_speed = (meter[1] * 1.0 / meter[0])
		note_instance.direction = directions[int(note[1]) % 4]
		note_instance.animation = directions[int(note[1]) % 4]
		
		note_instance.note_skin = note_skin
		note_list.append(note_instance)
		
		$"Notes Layer".add_child(note_instance)
		# note_instance.scale *= %Grid.grid_size * %Grid.zoom / Vector2(64, 64)
		# if note_instance.length > 0: note_instance.grid_size /= note_instance.scale


func play_audios( time: float ):
	
	%Instrumental.stream = song_data.instrumental
	%Vocals.stream = AudioStreamPolyphonic.new()
	# This is to prevent null references
	%Vocals.play()
	%Vocals.stream.polyphony = song_data.vocals.size()
	
	var playback = %Vocals.get_stream_playback()
	vocal_tracks = []
	for stream in song_data.vocals: vocal_tracks.append( \
	playback.play_stream(stream, time - chart.offset + start_offset, 0.0, song_speed) )
	
	time = clamp(time, 0, %Instrumental.stream.get_length() - 0.1)
	%Instrumental.play(time - chart.offset + start_offset)
	%Instrumental.pitch_scale = song_speed
	song_position = time - chart.offset + start_offset

## Converts a float of seconds into a time format of MM:SS.mmm
func float_to_time(time: float) -> String:
	
	var minutes = int( time / 60 )
	var seconds = int( time ) % 60
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


func grid_position_to_time(p: Vector2) -> float:
	
	var tempo_data: Dictionary = chart.get_tempos_data()
	var meter_data: Dictionary = chart.get_meters_data()
	var y_offset: float = 0
	
	var output: float = chart.offset
	var i: int = 0
	var meter: Array = []
	var L: float = tempo_data.keys()[0]
	var R: float = 0.0
	var yL: float = 0.0
	var yR: float = 0.0
	var seconds_per_beat: float = 0.0
	
	for time in tempo_data:
		
		if i + 1 >= tempo_data.keys().size(): R = %Instrumental.stream.get_length()
		else: R = tempo_data.keys()[i + 1]
		
		meter = chart.get_meter_at(L)
		var tempo = tempo_data.get(L)
		seconds_per_beat = 60.0 / tempo
		yR = yL + time_to_y_position(R - L)
		
		if (p.y >= yL && p.y < yR):
			
			yR = p.y
			return output + (yR - yL) * (seconds_per_beat / (meter[1] / meter[0]))
		else: yL = yR
		output += (yR - yL) * (seconds_per_beat / (meter[1] / meter[0]))
		
		L = R
		i += 1
	
	return output

## Binary Searches of notes and events
func bsearch_left_range( value_set: Array, length: int, left_range: float ) -> int:
	
	if ( length == 0 ): return -1
	if ( value_set[ length - 1 ][0] < left_range ): return -1
	
	var low: int = 0
	var high: int = length - 1
	
	while ( low <= high ):
		
		@warning_ignore("integer_division")
		var mid: int = low + ( ( high - low ) / 2 )
		
		if ( value_set[mid][0] >= left_range ): high = mid - 1
		else: low = mid + 1
	
	return high + 1


func bsearch_right_range( value_set: Array, length: int, right_range: float ) -> int:
	
	if ( length == 0 ): return -1
	if ( value_set[0][0] > right_range ): return -1
	
	var low: int = 0
	var high: int = length - 1
	
	while ( low <= high ):
		
		@warning_ignore("integer_division")
		var mid: int = low + ( ( high - low ) / 2 )
		
		if ( value_set[mid][0] > right_range ): high = mid - 1
		else: low = mid + 1
	
	return low - 1


func _on_play_button_toggled(toggled_on: bool) -> void:
	
	%Vocals.stream_paused = !toggled_on
	%Instrumental.stream_paused = !toggled_on
	
	if toggled_on:
		
		%"Play Button".icon = load("res://assets/sprites/menus/chart editor/pause_button.png")
		if song_position != %Instrumental.get_playback_position(): play_audios(song_position)
	
	else: %"Play Button".icon = load("res://assets/sprites/menus/chart editor/play_button.png")


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
