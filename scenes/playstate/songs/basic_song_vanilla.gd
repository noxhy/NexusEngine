extends Node2D

@onready var characters = [ %Player, %Enemy, %Metronome ]
@onready var camera_positions = [ $"World/Position 1", $"World/Position 2" ]
@onready var playstate_host = $"PlayState Host"

@onready var rating_node = preload( "res://scenes/instances/playstate/rating.tscn" )
@onready var combo_numbers_handeler_node = preload( "res://scenes/instances/playstate/combo_numbers_handeler.tscn" )
@onready var ui_skin: UISkin

# Called when the node enters the scene tree for the first time.
func _ready():
	
	Transitions.transition("down fade out")
	
	playstate_host.ui.set_player_icons( %Player.icons )
	playstate_host.ui.set_player_color( %Player.color )
	
	playstate_host.ui.set_enemy_icons( %Enemy.icons )
	playstate_host.ui.set_enemy_color( %Enemy.color )
	
	playstate_host.death_stats.player_position = characters[0].position
	playstate_host.death_stats.player_scale = characters[0].scale
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	%Stage.tempo = playstate_host.conductor.tempo


# Conductor Util


func _on_conductor_new_beat(current_beat, measure_relative):
	
	if measure_relative % 2 == 0:
		
		characters[0].play_animation( "idle" )
		characters[1].play_animation( "idle" )
		characters[2].can_idle = true
		characters[2].play_animation( "idle", playstate_host.conductor.seconds_per_beat * 2 )
	
	playstate_host.new_beat( current_beat, measure_relative )
	
	%Stage.bop( measure_relative % 2 == 0 )


func _on_conductor_new_step(current_step, measure_relative):
	
	playstate_host.new_step( current_step, measure_relative )


# Util


func _on_create_note(time, lane, note_length, note_type, tempo):
	
	if ( lane > 3 ):
		
		playstate_host.strums[1].create_note( time, lane % 4, note_length, note_type, tempo )
	else:
		
		playstate_host.strums[0].create_note( time, lane % 4, note_length, note_type, tempo )


func note_hit(time, lane, note_type, hit_time, strum_handeler):
	
	var animations = ["left", "down", "up", "right"]
	
	if !strum_handeler.enemy_slot:
		characters[0].play_animation( animations[ lane ] )
	else:
		characters[1].play_animation( animations[ lane ] )
	
	playstate_host.note_hit( time, lane, note_type, hit_time, strum_handeler )


func note_holding(time, lane, note_type, strum_handeler):
	
	var animations = ["left", "down", "up", "right"]
	
	if !strum_handeler.enemy_slot:
		characters[0].play_animation( animations[ lane ] )
	else:
		characters[1].play_animation( animations[ lane ] )
	
	playstate_host.note_holding( time, lane, note_type, strum_handeler )


func note_miss(time, lane, length, note_type, hit_time, strum_handeler):
	
	var animations = ["left", "down", "up", "right"]
	
	if !strum_handeler.enemy_slot:
		characters[0].play_animation( "miss_" + animations[ lane ] )
	else:
		characters[1].play_animation( "miss_" + animations[ lane ] )
	
	playstate_host.note_miss( time, lane, length, note_type, hit_time, strum_handeler )


func _on_new_event(time, event_name, event_parameters):
	pass


func _on_combo_break():
	
	characters[2].play_animation( "cry" )
