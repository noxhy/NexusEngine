extends Node2D

@export var can_click: bool = true

@export var album_list: Array[Album]

@onready var menu_option_node = preload( "res://scenes/instances/menu_option.tscn" )
@onready var options: Array[Song]


var option_nodes = []
var selected_album: int = 0
var selected_song: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	
	Global.set_window_title( "Freeplay Menu" )
	Global.freeplay_album_option = wrap( Global.freeplay_album_option, 0, album_list.size() )
	
	load_page( Global.freeplay_album_option )
	Global.freeplay_song_option = wrap( Global.freeplay_song_option, 0, options.size() )
	
	update_selection( Global.freeplay_song_option )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if options[selected_song].chart != null:
		
		$Conductor.tempo = get_tempo_at( $Audio/Music.get_playback_position(), options[selected_song].chart )
		$Conductor.offset = options[selected_song].chart.offset + SettingsHandeler.get_setting( "offset" )


# Input Handler
func _input(event):
	
	if can_click:
		
		if event.is_action_pressed("ui_up"):
			
			update_selection( selected_song - 1 )
		elif event.is_action_pressed("ui_down"):
			
			update_selection( selected_song + 1 )
		elif event.is_action_pressed("ui_left"):
			
			if album_list.size() > 1:
				
				load_page( selected_album - 1 )
				update_selection( selected_song % option_nodes.size() )
		elif event.is_action_pressed("ui_right"):
			
			if album_list.size() > 1:
				
				load_page( selected_album + 1 )
				update_selection( selected_song % option_nodes.size() )
		elif event.is_action_pressed("ui_accept"):
			
			select_option(selected_song)
		elif event.is_action_pressed("ui_cancel"):
			
			Transitions.transition("down")
			can_click = false
			
			$"Audio/Menu Cancel".play()
			
			await get_tree().create_timer(1).timeout
			
			Global.change_scene_to("res://scenes/main menu/main_menu.tscn")


# Updates visually what happens when a new index is set for a selection


func load_page(i: int):
	
	
	for j in option_nodes.size():
		
		
		option_nodes[0].queue_free()
		option_nodes.remove_at(0)
	
	selected_album = wrapi( i, 0, album_list.size() )
	i = selected_album
	
	var album = album_list[ i ]
	
	var object_amount: int = -Global.freeplay_song_option
	options = album.song_list
	
	for song_file in options:
		
		song_file.chart.chart_data.erase( "notes" )
		song_file.chart.chart_data.erase( "events" )
		var menu_option_instance = menu_option_node.instantiate()
		
		menu_option_instance.option_name = song_file.chart.song_title
		menu_option_instance.icon = song_file.icons.get_frame_texture( "default", 0 )
		menu_option_instance.position = Vector2( -1000, object_amount * 175 )
		
		$UI.add_child( menu_option_instance )
		
		option_nodes.append( menu_option_instance )
		object_amount += 1
	
	$"UI/Album Cover".texture = album_list[i].cover
	$"UI/Album Cover".scale.x = 176.0 / album_list[i].cover.get_width()
	$"UI/Album Cover".scale.y = $"UI/Album Cover".scale.x
	$"UI/Album Name".text = album_list[i].name
	$"UI/Album Song List".text = album_list[i].credits
	
	$UI/Arrow.position = Vector2( -1000, 0 )
	var tween = create_tween()
	tween.tween_property( $UI/Arrow, "position", Vector2( -568, 0 ), 0.5 ).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func update_selection(i: int):
	
	selected_song = wrapi( i, 0, option_nodes.size() )
	i = selected_song
	var index = -selected_song
	
	var song_file = options[i]
	var chart = song_file.chart
	$"Audio/Menu Scroll".play()
	$Audio/Music.stream = load( chart.instrumental )
	$Audio/Music.volume_db = -80
	$Audio/Music.play()
	
	
	var tween = create_tween()
	tween.set_parallel()
	
	for j in option_nodes:
		
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var node_position = Vector2( -570 + 58 + ( 25 * index ), index * 175 )
		tween.tween_property( j, "position", node_position, 0.5 )
		
		j.modulate = Color( 0.5, 0.5, 0.5 )
		j.icon = options[ index + selected_song ].icons.get_frame_texture( "default", 0 )
		
		if options[ index + selected_song ].locked:
			j.icon = load( "res://assets/sprites/menus/freeplay/lock_small.png" )
		
		index += 1
	
	option_nodes[i].modulate = Color( 1, 1, 1 )
	tween.tween_property( $Background/Background, "modulate", song_file.display_color, 1 )
	
	if !song_file.locked: 
		
		tween.tween_property( $Audio/Music, "volume_db", 0, 1 )
	else:
		
		tween.tween_property( $Audio/Music, "volume_db", -80, 1 )
	
	if song_file.icons.has_animation( "winning" ) && !song_file.locked:
		option_nodes[i].icon = song_file.icons.get_frame_texture( "winning", 0 )


# Called when an option was selected
func select_option(i: int):
	
	if can_click:
		
		var song_file = options[i]
		
		# Lock Check
		if song_file.locked: return
		
		can_click = false
		$"Audio/Menu Confirm".play()
		
		$"Screen Flash".visible = true
		var tween = create_tween()
		tween.set_parallel()
		tween.tween_property( $"Screen Flash/ColorRect", "color", Color( 1, 1, 1, 0 ), 0.2 )
		
		tween.tween_property( $Audio/Music, "volume_db", -80, 1 )
		
		for j in option_nodes:
			
			if j != option_nodes[i]:
				
				tween.tween_property( j, "position", j.position - Vector2(2000, 0), 0.5 ).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		
		Transitions.transition("down")
		
		await get_tree().create_timer(1).timeout
		
		Global.stop_song()
		var scene = song_file.scene
		Global.freeplay = true
		Global.freeplay_album_option = selected_album
		Global.freeplay_song_option = i
		Global.change_scene_to( scene )


func _on_conductor_new_beat(current_beat, measure_relative):
	
	if SettingsHandeler.get_setting("ui_bops"):
		
		Global.bop_tween( $Camera2D, "zoom", Vector2( 1, 1 ), Vector2( 1.005, 1.005 ), 0.2, Tween.TRANS_CUBIC )


# Util


##  Gets the tempo at a certain time in seconds
func get_tempo_at(time: float, chart: Chart) -> float:
	
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
