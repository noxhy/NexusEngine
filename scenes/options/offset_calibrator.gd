extends Node2D

var previous_offsets: Array[float]
var index: int = 0
var timing: float = 0.0
var entries_required: int = 5

var max_length: int = 832

# Called when the node enters the scene tree for the first time.
func _ready():
	
	Transitions.transition("down fade out")
	Global.set_window_title( "Calibrating Offset" )
	
	for i in entries_required: previous_offsets.append(0.0)
	$Audio/Music.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	$"UI/Offset Label".text = "Offset: " + str( SettingsHandeler.get_setting("offset") * 1000 ) + " ms"
	
	var keycode = SettingsHandeler.get_keybind( "ui_accept" )
	$UI/Instructions.text = "Press " + SettingsHandeler.get_keycode_string( keycode ) + " to calibrate your offset"
	$UI/Instructions.text += "\n(This may not be entirely accurate)"
	
	queue_redraw()


func _draw():
	
	var rect_base_position: Vector2i = $UI/Visualizer.global_position + $UI.offset
	
	var rect_size: int = 64
	var top: int = rect_base_position.y - (rect_size / 2)
	var bottom: int = rect_base_position.y + (rect_size / 2)
	
	var offset_position = SettingsHandeler.get_setting("offset") / $Conductor.seconds_per_beat
	
	var rect: Rect2 = Rect2( Vector2( rect_base_position.x - (max_length / 2), top ), Vector2( max_length, rect_size ) )
	draw_rect( rect, Color(0, 0, 0, 0.2549019753933), true )
	
	rect = Rect2( -2 + rect_base_position.x, top, 4, rect_size )
	draw_rect( rect, Color.WHITE, true )
	
	rect = Rect2( offset_position * ( max_length / 2 ) - 2 + rect_base_position.x, top, 4, rect_size )
	draw_rect( rect, Color(0.54509806632996, 0.61960786581039, 1), true )
	
	for i in previous_offsets:
		
		var base_position = i / $Conductor.seconds_per_beat
		rect = Rect2( base_position * ( max_length / 2 ) - 2 + rect_base_position.x, top, 4, rect_size )
		draw_rect( rect, Color.SLATE_GRAY, true )


# Input Handler
func _input(event):
	
	if event.is_action_pressed("ui_cancel"):
		
		
		Transitions.transition("down fade in")
		
		await get_tree().create_timer(1).timeout
		
		Global.change_scene_to("res://scenes/options/options.tscn")
	
	elif event.is_action_pressed("ui_accept"):
		
		$"Audio/Hit Sound".play()
		var song_position = snapped( $Audio/Music.get_playback_position(), 0.001 )
		timing = snapped( timing, 0.001 )
		var distance = snapped( song_position - timing, 0.001 )
		previous_offsets[ index % entries_required ] = abs( distance )
		
		index += 1
		
		if index >= entries_required:
			
			var sum = 0.0
			for i in previous_offsets: sum += i
			SettingsHandeler.set_setting( "offset", snapped( sum / previous_offsets.size(), 0.001 ) )
			SettingsHandeler.save_settings()



func _on_conductor_new_beat(current_beat, measure_relative):
	
	$UI/Speaker.frame = 0
	$UI/Speaker.play_animation("idle")
	
	timing = (current_beat + 1) * $Conductor.seconds_per_beat
	
	if SettingsHandeler.get_setting("ui_bops"):
		
		Global.bop_tween( $Camera2D, "zoom", Vector2( 1, 1 ), Vector2( 1.005, 1.005 ), 0.2, Tween.TRANS_CUBIC )
