extends Node2D

@onready var characters = [ %Player, %Enemy, %Metronome ]
@onready var camera_positions = [ $"World/Position 1", $"World/Position 2" ]
@onready var playstate_host = $"PlayState Host"

@onready var rating_node = preload( "res://scenes/instances/playstate/rating.tscn" )
@onready var combo_numbers_handeler_node = preload( "res://scenes/instances/playstate/combo_numbers_handeler.tscn" )
@onready var ui_skin: UISkin

@export var wavy_arrows: bool = false
@export var flipping_arrows: bool = false

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
	var sprite_frames = %Enemy.get_node("AnimatedSprite2D").sprite_frames
	var animation = %Enemy.get_node("AnimatedSprite2D").animation
	var frame = %Enemy.get_node("AnimatedSprite2D").frame
	
	$Characters/Enemy/GPUParticles2D.texture = sprite_frames.get_frame_texture( animation, frame )
	
	var song_position = $Music/Instrumental.get_playback_position()
	
	var index = 0
	
	if wavy_arrows:
		
		for strum in playstate_host.strums:
			
			for lane in strum.strums:
				
				var node = strum.get_node( lane )
				node.position.y = sin( ( song_position / ( $Conductor.seconds_per_beat * 0.5 ) ) + index ) * 10
				node.position.x = cos( ( song_position / ( $Conductor.seconds_per_beat * 0.25 ) ) + index ) * 10 + ( -192 + ( 128 * index ) )
				index += 1
			
			index = 0
	
	if flipping_arrows:
		
		for strum in playstate_host.strums:
			
			var multi = -1 if SettingsHandeler.get_setting("downscroll") else 1
			strum.position.y = cos( ( song_position / ( $Conductor.seconds_per_beat * 1 ) ) ) * 256 * multi
			
			strum.scale.x = sin( ( song_position / ( $Conductor.seconds_per_beat * 1 ) ) ) * -0.2 * multi + 0.9
			strum.scale.y = sin( ( song_position / ( $Conductor.seconds_per_beat * 1 ) ) ) * -0.2 * multi + 0.9
			
			for lane in strum.strums:
				
				var node = strum.get_node( lane )
				node.scroll = cos( ( song_position / ( $Conductor.seconds_per_beat * 1 ) ) ) * -1 * multi


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
	
	if current_step % playstate_host.bop_delay == 0:
		
		if SettingsHandeler.get_setting( "ui_bops" ):
			playstate_host.ui.scale += Vector2(0.025, 0.025)


# Util


func _on_create_note(time, lane, note_length, note_type, tempo):
	
	if ( lane > 3 ):
		
		playstate_host.strums[0].create_note( time, lane % 4, note_length, note_type, tempo )
	else:
		
		playstate_host.strums[1].create_note( time, lane % 4, note_length, note_type, tempo )


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
	
	if event_name == "clean":
		
		var index = 0
		
		for strum in playstate_host.strums:
			
			strum.scale = Vector2(0.9, 0.9)
			var multi = -1 if SettingsHandeler.get_setting("downscroll") else 1
			strum.set_scroll( multi )
			
			for lane in strum.strums:
				
				var node = strum.get_node( lane )
				node.position.y = 0
				node.position.x = -192 + ( 128 * index )
				index += 1
			
			index = 0
	
	elif event_name == "wavy_arrows":
		
		wavy_arrows = bool( int( event_parameters[0] ) )
		_on_new_event( time, "clean", [] )
	
	
	elif event_name == "flipping_arrows":
		
		flipping_arrows = bool( int( event_parameters[0] ) )
		
		for strum in playstate_host.strums:
			
			var multi = -1 if SettingsHandeler.get_setting("downscroll") else 1
			strum.position.y = -256 * multi
		
		_on_new_event( time, "clean", [] )


func _on_combo_break():
	
	characters[2].play_animation( "cry" )
