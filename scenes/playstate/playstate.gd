@icon( "res://assets/sprites/nodes/play_state.png" )
extends Node
class_name PlayState

const COMPENSATION = 1.0 / 30.0

signal create_note( time: float, lane: int, note_length: float, note_type: int, tempo: float )
signal new_event( time: float, event_name: String, event_parameters: Array )
signal combo_break()
signal setup_finished()

@onready var rating_node = preload( "res://scenes/instances/playstate/rating.tscn" )
@onready var combo_numbers_handeler_node = preload( "res://scenes/instances/playstate/combo_numbers_handeler.tscn" )
@onready var countdown_node = preload( "res://scenes/playstate/countdown.tscn" )


@export_group("Nodes")

@export var host: Node2D
@export var ui: CanvasLayer
@export var camera: PlayStateCamera
@export var conductor: Conductor
@export var music_host: Node

@export_group("Positions")

@export var rating_position: Marker2D
@export var combo_position: Marker2D

@export_group("Resources")

@export var chart: Chart
@export var note_skin: NoteSkin
@export var ui_skin: UISkin

@export_group("Values")

@export var combo_scale_multiplier = Vector2( 1, 1 )

@export_group("Scenes")

@export var death_scene = "res://scenes/playstate/death_screen.tscn"
var death_stats = {
	
	"death_screen" = death_scene,
	"player_scale" = Vector2( 1, 1 ),
	"player_position" = Vector2( 640, 360 ),
	"camera_zoom" = Vector2( 1, 1 ),
	
}

@export var pause_scene = "res://scenes/playstate/pause_menu.tscn"
@export var next_scene = "res://scenes/story mode/story_mode.tscn"

var strums: Array = []
var characters: Array = []

var bop_delay: int = 16

var song_started: bool = false
var song_start_offset: float = -4.0
var song_start_time: float = 0.0

var song_position: float = 0.0
var position_delta: float = 0.0
var position_lerp: float = 0.0
var sync_timer: float = 0.0

var accuracy: float
var timings_sum: float
var entries: float = 0
var misses: int = 0

var health: float = 50.0
var combo: int = 0

var self_delta: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	Global.song_scene = Global.new_scene
	
	music_host.get_node("Vocals").stream = load( chart.vocals )
	music_host.get_node("Instrumental").stream = load( chart.instrumental )
	music_host.get_node("Instrumental").connect( "finished", song_finished )
	
	var song_speed: float = SettingsHandeler.get_setting( "song_speed" )
	music_host.get_node("Vocals").pitch_scale = song_speed
	music_host.get_node("Instrumental").pitch_scale = song_speed
	
	music_host.get_node("Hit Sound").stream = note_skin.hit_sound
	
	host.ui_skin = ui_skin
	
	ui.set_credits( chart.song_title, chart.artist )
	play_song( 0.0 )
	
	# This delay is so variables initialize
	
	await host.ready # This is here cause shit will be null until the engine initializes it
	
	pause_scene = ui_skin.pause_scene
	
	strums = ui.strums
	
	# This is how to do botplay
	# strums[0].set_auto_play( true )
	# strums[0].set_press( false )
	
	if SettingsHandeler.get_setting( "downscroll" ): ui.downscroll_ui()
	if SettingsHandeler.get_setting( "streamer_mode" ): ui.streamer_ui()
	
	for strum in ui.strums:
		
		strum.set_scroll_speed( chart.scroll_speed * SettingsHandeler.get_setting( "scroll_speed_scale" ) )
		strum.connect( "note_hit", host.note_hit )
		strum.connect( "note_holding", host.note_holding )
		strum.connect( "note_miss", host.note_miss )
		strum.set_offset( chart.offset + SettingsHandeler.get_setting( "offset" ) )
		strum.set_skin( note_skin )
		
		if SettingsHandeler.get_setting( "downscroll" ): strum.set_scroll( -1 )
	
	emit_signal("setup_finished")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	accuracy = ( timings_sum / entries ) if entries != 0.0 else 0.0
	self_delta = delta
	
	health = clamp( health, 0.0, 100.0 )
	ui.target_health = health
	
	if health <= 0:
		
		death_stats.camera_zoom = camera.zoom
		Global.song_scene = get_tree().current_scene.scene_file_path
		Global.death_stats = death_stats
		get_tree().change_scene_to_file( death_scene )


func _process(delta):
	
	var window_title = chart.song_title
	
	var song_position = int( music_host.get_node("Instrumental").get_playback_position() )
	var song_end_position = int( music_host.get_node("Instrumental").stream.get_length() )
	
	window_title += " - " + Global.float_to_time( song_position )
	window_title += " / " + Global.float_to_time( song_end_position )
	
	Global.set_window_title( window_title )
	
	if Input.is_action_just_pressed( "ui_cancel" ) || Input.is_action_just_pressed( "ui_accept" ):
		
		var pause_scene_instance = load( pause_scene ).instantiate()
		
		pause_scene_instance.song_title = chart.song_title
		pause_scene_instance.credits = chart.artist
		pause_scene_instance.freeplay = Global.freeplay
		
		host.add_child( pause_scene_instance )
		get_tree().paused = true
	
	elif Input.is_action_just_pressed("kill"):
		
		health = 0
	
	
	if !song_started:
		
		song_start_offset += delta
		song_position = song_start_offset
		
		if song_start_offset >= song_start_time:
			
			music_host.get_node("Vocals").play( -chart.offset + song_start_time )
			music_host.get_node("Instrumental").play( -chart.offset + song_start_time )
			song_started = true
			
			ui.show_credits()
	else:
		
		song_position = music_host.get_node("Instrumental").get_playback_position() + \
				AudioServer.get_time_since_last_mix() - \
				AudioServer.get_output_latency()
	
	position_delta = abs( position_lerp - song_position )
	position_lerp += delta * music_host.get_node("Instrumental").pitch_scale
	
	if delta > COMPENSATION || sync_timer <= 0.0 || position_delta >= 0.01 * music_host.get_node("Instrumental").pitch_scale:
		
		if position_delta >= 0.025 * music_host.get_node("Instrumental").pitch_scale: position_lerp = song_position
		sync_timer = 0.5
	
	sync_timer -= delta
	conductor.tempo = get_tempo_at( clamp( song_position, 0, music_host.get_node("Instrumental").stream.get_length() ) )
	
	render_section( song_position, conductor.seconds_per_beat * 4 )
	
	for strum in strums:
		
		strum.set_tempo( conductor.tempo )
		strum.set_song_position( position_lerp )
		strum.set_song_speed( music_host.get_node("Instrumental").pitch_scale )
	
	var events = chart.get_events_data()
	
	for i in events:
		
		var time: float = i[0]
		var event_name: String = i[1]
		var event_parameters: Array = i[2]
		
		if (time < ( song_position - conductor.seconds_per_beat) ) || ( time > (song_position + conductor.seconds_per_beat) ):
			continue
		else:
			
			if (time < song_position):
				
				print( event_name, " ", str( event_parameters ) )
				
				basic_event( time, event_name, event_parameters )
				events.erase( i )
				break


#
# Util
#


##  Gets the tempo at a certain time in seconds
func get_tempo_at(time: float) -> float:
	
	var tempo_dict = chart.get_tempos_data()
	var keys = tempo_dict.keys()
	
	var tempo_output = 0.0
	
	for i in keys.size():
		var dict_time = keys[i]
		
		if time >= dict_time:
			tempo_output = tempo_dict.get(keys[i])
		else:
			continue
	
	return tempo_output


func play_song( time: float ):
	
	conductor.tempo = get_tempo_at( -chart.offset + time )
	conductor.seconds_per_beat = 60.0 / conductor.tempo
	conductor.offset = chart.offset + SettingsHandeler.get_setting( "offset" )
	var seconds_per_beat = ( 60.0 / conductor.tempo )
	
	song_started = false
	song_start_time = time - chart.offset
	song_start_offset = time - chart.offset - ( seconds_per_beat * 4 )
	
	if time >= seconds_per_beat * 4:
		
		music_host.get_node("Vocals").play( -chart.offset + song_start_offset )
		music_host.get_node("Instrumental").play( -chart.offset + song_start_offset )
	else:
		
		var countdown_instance = countdown_node.instantiate()
		
		countdown_instance.speed_scale = get_tempo_at( -chart.offset + time ) / 60.0
		
		ui.add_child( countdown_instance )
		
		countdown_instance.play( ui_skin.countdown_animation )
		countdown_instance.seek( time )
	
	for i in chart.chart_data.notes:
		
		var note_time: float = i[0]
		
		if note_time < song_start_time:
			chart.chart_data.notes.erase(i)
		else:
			continue
	
	for i in chart.chart_data.events:
		
		var note_time: float = i[0]
		
		if note_time < song_start_time:
			chart.chart_data.events.erase(i)
		else:
			continue


func render_section( song_position: float, distance: float ):
	
	
	for i in chart.chart_data.notes:
		
		var time: float = i[0]
		var lane: int = i[1]
		var note_length: float = i[2]
		var note_type: int = i[3]
		
		if ( time < ( song_position ) ) || ( time > (song_position + distance) ):
			continue
		
		else:
			
			emit_signal( "create_note", time, lane, note_length, note_type, get_tempo_at( time ) )
			
			for j in chart.chart_data.notes.count( i ):
				chart.chart_data.notes.erase( i )


func get_rating( time: float ) -> String:
	
	var rating: String
	
	var ratings = [
		[ time <= 0.018, "epic" ],
		[ time <= 0.043, "sick" ],
		[ time <= 0.076, "good" ],
		[ time <= 0.106, "bad" ],
		[ time <= 0.127, "shit" ],
		[ time <= 0.164, "miss" ],
	]
	
	for condition in ratings:
		
		if condition[0]:
			
			rating = condition[1]
			break
	
	return rating


func get_rank( accuracy: float ) -> String:
	
	var accuracies = [
		[ entries == 0, "?" ],
		[ accuracy >= 1, "★★★★★" ],
		[ accuracy >= 0.9999, "★★★★" ],
		[ accuracy >= 0.999, "★★★" ],
		[ accuracy >= 0.98, "★★" ],
		[ accuracy >= 0.97, "★" ],
		[ accuracy >= 0.95, "S" ],
		[ accuracy >= 0.90, "A" ],
		[ accuracy >= 0.80, "B" ],
		[ accuracy >= 0.70, "C" ],
		[ accuracy >= 0.60, "D" ],
		[ accuracy >= 0, "F (you fucking suck)" ],
	]
	
	for condition in accuracies: if condition[0]: return condition[1]
	return "?"


func basic_event( time: float, event_name: String, event_parameters: Array ):
	
	if event_name == "camera_position":
		
		var camera_position = host.camera_positions[ int( event_parameters[0] ) ].global_position
		camera_position += ui.offset
		if camera_position != null: camera.position = camera_position
	
	elif event_name == "camera_bop":
		
		var camera_bop = float( event_parameters[0] )
		var ui_bop = float( event_parameters[1] )
		
		camera.zoom += Vector2( camera_bop, camera_bop )
		ui.scale += Vector2( ui_bop, ui_bop )
	
	elif event_name == "camera_zoom":
		
		var new_zoom = Vector2( float( event_parameters[0] ), float( event_parameters[0] ) )
		var zoom_time = 0 if event_parameters[1] == "" else float( event_parameters[1] )
		
		var tween = create_tween()
		tween.set_trans( Tween.TRANS_CUBIC ).set_ease( Tween.EASE_OUT )
		tween.tween_property( camera, "target_zoom", new_zoom, zoom_time )
	
	elif event_name == "bop_delay":
		bop_delay = int( event_parameters[0] )
	
	elif event_name == "lerping":
		
		var lerping = bool( event_parameters[0] )
		ui.lerping = lerping
		camera.lerping = lerping
	
	elif event_name == "scroll_speed":
		
		var scroll_speed = float( event_parameters[0] )
		var tween_time = 0 if event_parameters[1] == "" else float( event_parameters[1] )
		
		for strum in strums:
			
			for lane in strum.strums.size() - 1:
				
				var tween = create_tween()
				tween.set_trans( Tween.TRANS_CUBIC ).set_ease( Tween.EASE_OUT )
				var scroll_speed_scale: float = SettingsHandeler.get_setting( "scroll_speed_scale" )
				tween.tween_method( strum.set_scroll_speed, strum.get_scroll_speed( lane ), scroll_speed * scroll_speed_scale, tween_time )
	
	elif event_name == "camera_shake":
		
		camera.shake( int( event_parameters[0] ), float( event_parameters[1] ) )
	
	emit_signal( "new_event", time, event_name, event_parameters )


func song_finished():
	
	Transitions.transition("down")
	
	await get_tree().create_timer(1).timeout
	
	if Global.freeplay:
		
		get_tree().change_scene_to_file( "res://scenes/freeplay/freeplay.tscn" )
	else:
		
		Global.change_scene_to( next_scene )


# Conductor Util


func new_beat(current_beat, measure_relative):
	
	ui.icon_bop( conductor.seconds_per_beat * 0.5 * ( 1 / music_host.get_node("Instrumental").pitch_scale ) )


func new_step(current_step, measure_relative):
	
	if current_step % bop_delay == 0:
		
		camera.zoom += Vector2(0.05, 0.05)
		
		if SettingsHandeler.get_setting( "ui_bops" ):
			ui.scale += Vector2(0.025, 0.025)


# Strum Util


func note_hit(time, lane, note_type, hit_time, strum_handeler):
	
	music_host.get_node("Vocals").volume_db = 0
	
	if !strum_handeler.enemy_slot:
		
		if SettingsHandeler.get_setting( "hit_sounds" ): music_host.get_node("Hit Sound").play()
		
		var rating = get_rating( abs( hit_time ) )
		var strum_node = strum_handeler.get_strum( lane )
		
		if rating == "epic":
			
			health += 2
			timings_sum += 1
			strum_handeler.create_splash( lane, strum_node.strum_name + " splash" )
		
		elif rating == "sick":
			
			health += 1
			timings_sum += 0.9825
			strum_handeler.create_splash( lane, strum_node.strum_name + " splash" )
		
		elif rating == "good":
			timings_sum += 0.65
		
		elif rating == "bad":
			
			health -= 0.5
			timings_sum += 0.25
		
		elif rating == "shit":
			
			health -= 1
			timings_sum += -1
		else:
			
			note_miss( time, lane, 0, note_type, hit_time, strum_handeler )
		
		entries += 1
		combo += 1
		
		accuracy = ( timings_sum / entries )
		if misses == 0: rating = "fc_" + rating
		
		show_combo( rating, combo )
		
		update_ui_stats()


func note_holding(time, lane, note_type, strum_handeler):
	
	music_host.get_node("Vocals").volume_db = 0
	
	if !strum_handeler.enemy_slot:
		
		health += self_delta * 5
		
		timings_sum += self_delta
		entries += self_delta
		
		accuracy = ( timings_sum / entries )
		
		update_ui_stats()


func note_miss(time, lane, length, note_type, hit_time, strum_handeler):
	
	
	if !strum_handeler.enemy_slot:
		
		if note_type == -1:
			
			health -= ( 1 + clamp( combo / 20.0, 0, 20 ) ) * ( length + 1 )
			music_host.get_node("Vocals").volume_db = -80
			update_ui_stats()
		
		elif note_type == 0:
			
			health -= ( 4 + clamp( combo / 20.0, 0, 20 ) ) * ( length + 1 )
			combo = 0
			misses += 1
			
			entries += 1 + length
			accuracy = ( timings_sum / entries )
			
			music_host.get_node("Vocals").volume_db = -80
			show_combo( "miss", combo )
			emit_signal("combo_break")
			update_ui_stats()


func update_ui_stats():
	
	ui.accuracy = accuracy
	ui.misses = misses
	ui.target_health = health
	ui.rank = "?" if entries == 0 else get_rank( accuracy )


# Visual Util


func show_combo( rating: String, combo: int ):
	
	var rating_instance = rating_node.instantiate()
	
	rating_instance.ui_skin = ui_skin
	rating_instance.rating = rating
	
	var combo_numbers_handeler_instance = combo_numbers_handeler_node.instantiate()
	
	combo_numbers_handeler_instance.ui_skin = ui_skin
	combo_numbers_handeler_instance.combo = combo
	if misses == 0: combo_numbers_handeler_instance.fc = true
	
	
	if SettingsHandeler.get_setting( "combo_ui" ):
		
		rating_instance.position = Vector2( -32, 88 )
		combo_numbers_handeler_instance.position = Vector2( 96, 152 )
		
		ui.add_child( rating_instance )
		ui.add_child( combo_numbers_handeler_instance )
	else:
		
		rating_instance.position = rating_position.global_position + ui.offset
		combo_numbers_handeler_instance.position = combo_position.global_position + ui.offset
		rating_instance.scale *= combo_scale_multiplier
		combo_numbers_handeler_instance.scale *= combo_scale_multiplier
		
		self.add_child( rating_instance )
		self.add_child( combo_numbers_handeler_instance )
