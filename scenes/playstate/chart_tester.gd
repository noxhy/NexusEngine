extends Node2D

@onready var characters = []
@onready var camera_positions = [ $"World/Position 1", $"World/Position 2" ]
@onready var playstate_host = $"PlayState Host"

@onready var rating_node = preload( "res://scenes/instances/playstate/rating.tscn" )
@onready var combo_numbers_handeler_node = preload( "res://scenes/instances/playstate/combo_numbers_handeler.tscn" )
@onready var ui_skin: UISkin


# Called when the node enters the scene tree for the first time.
func _ready():
	
	Transitions.transition("down fade out")
	
	$UI.set_player_color( Color.GREEN )
	$UI.set_enemy_color( Color.RED )
	
	# strums[0].set_auto_play( true )
	# strums[0].set_press( false )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	for strum in playstate_host.strums:
		
		strum.set_tempo( $Conductor.tempo )
		strum.set_song_position( playstate_host.song_position )
		strum.set_song_speed( $Music/Instrumental.pitch_scale )


# Conductor Util


func _on_conductor_new_beat(current_beat, measure_relative):
	
	playstate_host.new_beat( current_beat, measure_relative )


func _on_conductor_new_step(current_step, measure_relative):
	
	playstate_host.new_step( current_step, measure_relative )


# Util


func _on_create_note(time, lane, note_length, note_type, tempo):
	
	if ( lane > 3 ):
		
		playstate_host.strums[0].create_note( time, lane % 4, note_length, note_type, tempo )
	else:
		
		playstate_host.strums[1].create_note( time, lane % 4, note_length, note_type, tempo )


func note_hit(time, lane, note_type, hit_time, strum_handeler):
	
	playstate_host.note_hit( time, lane, note_type, hit_time, strum_handeler )


func note_holding(time, lane, note_type, strum_handeler):
	
	playstate_host.note_holding( time, lane, note_type, strum_handeler )


func note_miss(time, lane, length, note_type, hit_time, strum_handeler):
	
	playstate_host.note_miss( time, lane, length, note_type, hit_time, strum_handeler )


func new_event(time, event_name, event_parameters):
	
	if event_name == "scroll_speed":
		
		var scroll_speed = float( event_parameters[0] )
		var tween_time = 0 if event_parameters[1] == "" else float( event_parameters[1] )
		
		for strum in playstate_host.strums:
			
			for lane in strum.strums.size() - 1:
				
				var tween = create_tween()
				tween.set_trans( Tween.TRANS_CUBIC ).set_ease( Tween.EASE_OUT )
				tween.tween_method( strum.set_scroll_speed, strum.get_scroll_speed( lane ), scroll_speed, tween_time )
