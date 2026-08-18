extends Node2D

var previous_offsets: Array[float]
var index: int = 0

var entries_required: int = 4

var next_hit: float = 0.0
var song_position: float = 0.0
var output_latency: float = AudioServer.get_output_latency()
var can_hit: bool = true

var max_range: float = 1
var max_length: float = 850

@onready var stream_player = $Audio/Base
@onready var conductor = $Conductor

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.set_window_title("Calibrating Offset")
	
	for i in entries_required:
		previous_offsets.append(0.0)
	
	$UI/Instructions.text = str("Press ", Global.get_bind_string(&"menu_accept"), " to calibrate your offset")
	$UI/Instructions.text += "\n(This may not be entirely accurate)"
	
	conductor.tempo = stream_player.stream.get_bpm()
	max_range = conductor.seconds_per_beat
	
	stream_player.play()
	$Audio/Drums.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$"UI/Offset Label".text = str("Offset: ", str(
		floori(SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "offset") * 1000)),
		" ms")
	
	song_position = stream_player.get_playback_position() + \
				AudioServer.get_time_since_last_mix() - output_latency
	
	var distance: float = song_position - next_hit
	if distance > GameManager.SHIT_RATING_WINDOW:
		can_hit = true
		update_next_hit()
	
	queue_redraw()


func _draw():
	var rect_base_position: Vector2i = $UI/Visualizer.global_position + $UI.offset
	
	var rect_size: int = 64
	var top: int = rect_base_position.y - (rect_size / 2)
	
	var offset_position: float = SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "offset") / max_range
	
	var rect: Rect2 = Rect2(Vector2(rect_base_position.x - (max_length / 2), top), Vector2(max_length, rect_size))
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.25), true)
	
	rect = Rect2(-2 + rect_base_position.x, top, 4, rect_size)
	draw_rect(rect, Color.WHITE, true)
	
	rect = Rect2(offset_position * (max_length / 2) - 2 + rect_base_position.x, top, 4, rect_size)
	draw_rect(rect, Color(0.54509806632996, 0.61960786581039, 1), true)
	
	var distance: float = (song_position - next_hit) / max_range
	rect = Rect2(distance * (max_length / 2) - 2 + rect_base_position.x, top, 4, rect_size)
	draw_rect(rect, Color.RED, true)
	
	for i in previous_offsets:
		rect = Rect2((i / max_range) * (max_length / 2) - 2 + rect_base_position.x, top, 4, rect_size)
		draw_rect(rect, Color.SLATE_GRAY, true)


# Input Manager
func _input(event):
	if event.is_action_pressed(&"menu_cancel"):
		SoundManager.cancel.play()
		Global.change_scene_to(Constants.OPTIONS_MENU_SCENE, "down")
	elif event.is_action_pressed(&"menu_accept"):
		if can_hit:
			$"Audio/Hit Sound".play()
			var distance: float = song_position - next_hit
			if next_hit == 0 and distance > GameManager.SHIT_RATING_WINDOW:
				distance -= stream_player.stream.get_length()
			
			print("Hit: ", next_hit, " at ", song_position, " rel: ", distance)
			
			previous_offsets[index % entries_required] = distance
			can_hit = false
			
			index += 1
			if index >= entries_required:
				var sum: float = 0.0
				for i in previous_offsets:
					sum += i
				
				SettingsManager.set_value(
					SettingsManager.SEC_GAMEPLAY, "offset", snapped(sum / previous_offsets.size(), 0.001)
					)


func _on_conductor_new_beat(current_beat, measure_relative):
	if SettingsManager.get_value(SettingsManager.SEC_PREFERENCES, "ui_bops"):
		Global.bop_tween($Camera2D, "zoom", Vector2(1, 1), Vector2(1.005, 1.005), 0.2, Tween.TRANS_CUBIC)


func get_length_in_beats() -> int:
	var length: float = stream_player.stream.get_length()
	return int(length / conductor.seconds_per_beat)


func update_next_hit():
	var next_beat: int = wrapi(conductor.current_beat + 1, 0, get_length_in_beats() + 1)
	next_hit = next_beat * conductor.seconds_per_beat
