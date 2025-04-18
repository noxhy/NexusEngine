extends Node2D

@onready var characters = []
@onready var camera_positions = [$"World/Position 1", $"World/Position 2", $"World/Position 3"]
@onready var playstate_host = $"PlayState Host"

@onready var rating_node = preload( "res://scenes/instances/playstate/rating.tscn" )
@onready var combo_numbers_handeler_node = preload( "res://scenes/instances/playstate/combo_numbers_handeler.tscn" )
@onready var ui_skin: UISkin


# Called when the node enters the scene tree for the first time.
func _ready():
	
	$UI.set_player_color(Color.GREEN)
	$UI.set_enemy_color(Color.RED)
	
	playstate_host.song_data = ChartHandeler.song
	playstate_host.chart = load(playstate_host.song_data.difficulties[GameHandeler.difficulty].chart)
	
	%Background.modulate = Color(randf(), randf(), randf())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	for strum in playstate_host.strums:
		
		strum.set_tempo( $Conductor.tempo )
		strum.set_song_position( playstate_host.song_position )
		strum.set_song_speed( $Music/Instrumental.pitch_scale )
	
	$"UI/Chart Stats".text = "Song: " + str(playstate_host.song_data.title)
	$"UI/Chart Stats".text += "\n" + "Artist: " + str(playstate_host.song_data.artist)
	$"UI/Chart Stats".text += "\n" + "Difficulty: " + str(GameHandeler.difficulty)
	$"UI/Chart Stats".text += "\n" + "Tempo: " + str($Conductor.tempo)
	$"UI/Chart Stats".text += "\n" + "Scroll Speed: " + str(playstate_host.ui.strums[0].get_node(playstate_host.ui.strums[0].strums[0]).scroll_speed)
	$"UI/Chart Stats".text += "\n" + str(GameHandeler.tallies).replace("{", "").replace("}", "").replace(",", "\n")

# Conductor Util


func _on_conductor_new_beat(current_beat, measure_relative):
	
	playstate_host.new_beat( current_beat, measure_relative )


func _on_conductor_new_step(current_step, measure_relative):
	
	playstate_host.new_step( current_step, measure_relative )


# Util


func _on_create_note(time, lane, note_length, note_type, tempo):
	
	if lane > 3: playstate_host.strums[1].create_note(time, lane % 4, note_length, note_type, tempo)
	else: playstate_host.strums[0].create_note( time, lane % 4, note_length, note_type, tempo)


func note_hit(time, lane, note_type, hit_time, strum_handeler):
	
	playstate_host.note_hit( time, lane, note_type, hit_time, strum_handeler )


func note_holding(time, lane, note_type, strum_handeler):
	
	playstate_host.note_holding( time, lane, note_type, strum_handeler )


func note_miss(time, lane, length, note_type, hit_time, strum_handeler):
	
	if !strum_handeler.enemy_slot: if note_type == -1: %"Anti-Spam Sound".play()
	playstate_host.note_miss( time, lane, length, note_type, hit_time, strum_handeler )


func new_event(time, event_name, event_parameters):
	pass


func _on_combo_break(): %"Miss Sound".play()
