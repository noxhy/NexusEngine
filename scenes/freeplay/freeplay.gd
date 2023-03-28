extends Node2D

@export var can_click: bool = true

@onready var menu_option_node = preload( "res://scenes/instances/menu_option.tscn" )


# To add a new album, add an dictionary with this format:
# < id >:
# name: String = < album name >
# cover: Image = < album cover >
# credits: String = < album credits>
@onready var albums: Dictionary = {
	
	"fnf": {
		"name": "Friday Night Funkin\'",
		"cover": preload( "res://assets/sprites/menus/freeplay/album covers/phantomarcade_friday-night-funkin-cd-cover-vol-1.png" ),
		"credits": "Kawai Sprite",
	},
	"test": {
		"name": "Test Album",
		"cover": preload( "res://assets/sprites/menus/loading_screen.png" ),
		"credits": "Me\nMyself\nI",
	}
	
}


# To add a new song, add an dictionary with this format:
# < id >:
# icon_node: Node2D = < Node2D to grab color and icons from >
# scene = < scene >
# chart: Chart = < chart >
# album: String = < album name >
# locked: bool = < locked songs show a lock icon and not play music >
@onready var options: Dictionary = {
	
	"deathmatch": {
		"icon_node": $"Characters/Daddy Dearest",
		"scene": "res://scenes/playstate/songs/deathmatch/deathmatch.tscn",
		"chart": "res://assets/charts/Hotline Deathmatch - hard.tres",
		"album": "fnf",
		"locked": false,
	},
	"prometheus": {
		"icon_node": $Characters/Darnell,
		"scene": "res://scenes/playstate/songs/prometheus/prometheus.tscn",
		"chart": "res://assets/charts/Prometheus - hard.tres",
		"album": "fnf",
		"locked": false,
	},
	"endless": {
		"icon_node": $Characters/Senpai,
		"scene": "res://scenes/playstate/songs/endless/endless.tscn",
		"chart": "res://assets/charts/Endless D-Side - hard.tres",
		"album": "fnf",
		"locked": false,
	},
	"thorns": {
		"icon_node": $Characters/Spirit,
		"scene": "res://scenes/playstate/songs/thorns/thorns.tscn",
		"chart": "res://assets/charts/Thorns D-Side (Fanmade) - hard.tres",
		"album": "fnf",
		"locked": false,
	},
}


var option_nodes = []
var selected: int = 0
var current_chart: Chart = null


# Called when the node enters the scene tree for the first time.
func _ready():
	
	Transitions.transition("down fade out")
	Global.set_window_title( "Freeplay Menu" )
	Global.freeplay_option = wrap( Global.freeplay_option, 0, options.keys().size() )
	
	var object_amount: int = -Global.freeplay_option
	
	for i in options:
		
		var menu_option_instance = menu_option_node.instantiate()
		var chart = load(options.get(i).chart)
		
		menu_option_instance.option_name = chart.song_title
		menu_option_instance.icon = options.get(i).icon_node.icons.get_frame_texture( "default", 0 )
		menu_option_instance.position = Vector2( -1000, object_amount * 175 )
		
		$UI.add_child( menu_option_instance )
		
		option_nodes.append( menu_option_instance )
		object_amount += 1
	
	update_selection( Global.freeplay_option )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if current_chart != null:
		
		$Conductor.tempo = get_tempo_at( $Audio/Music.get_playback_position(), current_chart )
		$Conductor.offset = current_chart.offset + SettingsHandeler.get_setting( "offset" )


# Input Handler
func _input(event):
	
	if can_click:
		
		if event.is_action_pressed("ui_up"):
			
			update_selection( selected - 1 )
		elif event.is_action_pressed("ui_down"):
			
			update_selection( selected + 1 )
		elif event.is_action_pressed("ui_accept"):
			
			select_option(selected)
		elif event.is_action_pressed("ui_cancel"):
			
			Transitions.transition("down fade in")
			can_click = false
			
			await get_tree().create_timer(1).timeout
			
			Global.change_scene_to("res://scenes/main menu/main_menu.tscn")


# Updates visually what happens when a new index is set for a selection
func update_selection(i: int):
	
	selected = wrapi( i, 0, option_nodes.size() )
	i = selected
	var index = -selected
	var chart = load( options.get( options.keys()[i] ).chart )
	current_chart = chart
	$"Audio/Menu Scroll".play()
	$Audio/Music.stream = load( chart.instrumental )
	$Audio/Music.volume_db = -80
	$Audio/Music.play()
	
	var tween = create_tween()
	tween.set_parallel()
	
	var album = albums.get( options.get( options.keys()[i] ).album )
	
	$"UI/Album Name".text = album.name
	$"UI/Album Song List".text = album.credits
	
	if $"UI/Album Cover".texture != album.cover:
		
		$"UI/Album Cover".texture = album.cover
		$"UI/Album Cover".scale.x = 320.0 / $"UI/Album Cover".texture.get_width()
		$"UI/Album Cover".scale.y = $"UI/Album Cover".scale.x
		
		$"UI/Album Cover".position = Vector2( -448, -1000 )
		$"UI/Album Name".position = Vector2( -624, -1000 )
		$"UI/Album Song List".position = Vector2( -608, -1000 )
		
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property( $"UI/Album Cover", "position", Vector2( -448, -168 ), 0.5 )
		tween.tween_property( $"UI/Album Name", "position", Vector2( -624, 8 ), 0.5 )
		tween.tween_property( $"UI/Album Song List", "position", Vector2( -608, 64 ), 0.5 )
	
	for j in option_nodes:
		
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var node_position = Vector2( -192 + 58 + ( 25 * index ), index * 175 )
		tween.tween_property( j, "position", node_position, 0.5 )
		
		j.modulate = Color( 0.5, 0.5, 0.5 )
		j.icon = options.get( options.keys()[ index + selected ] ).icon_node.icons.get_frame_texture( "default", 0 )
		
		if options.get( options.keys()[ index + selected ] ).locked:
			j.icon = load( "res://assets/sprites/menus/freeplay/lock_small.png" )
		
		index += 1
	
	option_nodes[i].modulate = Color( 1, 1, 1 )
	tween.tween_property( $Background/Background, "modulate", options.get( options.keys()[i] ).icon_node.color, 1 )
	
	if !options.get( options.keys()[ i ] ).locked: 
		
		tween.tween_property( $Audio/Music, "volume_db", 0, 1 )
	else:
		
		tween.tween_property( $Audio/Music, "volume_db", -80, 1 )
	
	if options.get( options.keys()[ i ] ).icon_node.icons.has_animation( "winning" ) && !options.get( options.keys()[ i ] ).locked:
		option_nodes[i].icon = options.get( options.keys()[ i ] ).icon_node.icons.get_frame_texture( "winning", 0 )


# Called when an option was selected
func select_option(i: int):
	
	if can_click:
		
		# Lock Check
		if options.get( options.keys()[ i ] ).locked: return
		
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
		
		await get_tree().create_timer(1).timeout
		
		Global.stop_song()
		Transitions.transition("down fade in")
		var scene = options.get( options.keys()[i] ).scene
		Global.freeplay = true
		Global.freeplay_option = i
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
