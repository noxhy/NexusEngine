extends Node2D

const MENU_OPTION_NODE = preload("res://scenes/instances/freeplay/capsule.tscn")

@export var can_click: bool = true
@export var difficulties: Array[String]

@onready var options: Array[Song]

var selected_album: int = 0
var selected_song: int = 0
var difficulty: String = "null"
var album_list: Array[Album]


# Called when the node enters the scene tree for the first time.
func _ready():
	
	difficulty = difficulties[0]
	$"Difficulty Selector".difficulties = difficulties
	Global.set_window_title("Freeplay Menu")
	# idk how to cast a regular array to a typed one it keeps giving me an error.
	var _album_list = Preload.character_data[GameHandeler.current_character]["albums"]
	for album in _album_list:
		album_list.append(album)
	Global.freeplay_album_option = wrap(Global.freeplay_album_option, 0, album_list.size())
	
	load_page(Global.freeplay_album_option)
	Global.freeplay_song_option = wrap(Global.freeplay_song_option, 0, options.size())
	
	update_selection(Global.freeplay_song_option)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

# Input Handler
func _input(event):
	
	if can_click:
		
		if event.is_action_pressed("ui_up"):
			update_selection( selected_song - 1 )
		elif event.is_action_pressed("ui_down"):
			update_selection( selected_song + 1 )
		elif event.is_action_pressed("ui_left"):
			
			if album_list.size() > 1:
				
				load_page(selected_album - 1)
				update_selection(
					selected_song % get_tree().get_nodes_in_group("instances").size()
					)
		elif event.is_action_pressed("ui_right"):
			
			if album_list.size() > 1:
				
				load_page(selected_album + 1)
				update_selection(
					selected_song % get_tree().get_nodes_in_group("instances").size()
					)
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
	
	get_tree().call_group("instances", "queue_free")
	selected_album = wrapi(i, 0, album_list.size())
	i = selected_album
	
	var album = album_list[i]
	
	var object_amount: int = -Global.freeplay_song_option
	options = album.song_list
	
	var index: int = 0
	for song_file in options:
		
		if !song_file.difficulties.has(difficulty):
			index += 1
			continue
		
		var menu_option_instance = MENU_OPTION_NODE.instantiate()
		
		menu_option_instance.text = song_file.title
		menu_option_instance.icon = song_file.icons.get_frame_texture("default", 0)
		menu_option_instance.position = Vector2(-270, -60)
		menu_option_instance.scale = Vector2(0.7, 0.7)
		menu_option_instance.index = index
		
		$UI.add_child(menu_option_instance)
		menu_option_instance.add_to_group("instances")
		object_amount += 1
		index += 1
	
	$"UI/Album Cover".texture = album_list[i].cover
	$"UI/Album Cover".scale.x = 262.0 / album_list[i].cover.get_width()
	$"UI/Album Cover".scale.y = $"UI/Album Cover".scale.x
	%"Album Name".text = album_list[i].name
	%"Album Song List".text = album_list[i].credits


func update_selection(i: int):
	
	var instances = get_tree().get_nodes_in_group("instances")
	selected_song = wrapi(
		i, 0, instances.size()
		)
	i = selected_song
	var index: int = 0
	
	if instances.size() == 0:
		return
	
	var song_file = options[instances[i].index]
	$"Audio/Menu Scroll".play()
	$Audio/Music.stream = song_file.instrumental
	$Audio/Music.volume_db = -60
	$Audio/Music.play()
	
	$Conductor.tempo = song_file.tempo
	
	var tween = create_tween()
	tween.set_parallel()
	
	for j in instances:
		
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var node_position = Vector2(-270 + (60 * sin(index - selected_song + 1)), (index - selected_song) * 110 - 60)
		tween.tween_property(j, "position", node_position, 0.25)
		
		if index == selected_song:
			
			if song_file.icons.has_animation("winning") and !song_file.locked:
				j.icon = song_file.icons.get_frame_texture("winning", 0)
			j.state = "selected"
		else:
			
			j.icon = options[j.index].icons.get_frame_texture("default", 0)
			j.state = "idle"
		
		if options[index].locked:
			j.icon = load("res://assets/sprites/menus/freeplay/lock_small.png")
		
		index += 1
	
	if !song_file.locked: 
		tween.tween_property($Audio/Music, "volume_db", 0, 1)
	else:
		tween.tween_property($Audio/Music, "volume_db", -60, 1)


# Called when an option was selected
func select_option(i: int):
	
	if can_click:
		
		var song_file = options[i]
		
		# Lock Check
		if song_file.locked: return
		
		can_click = false
		
		# I wish i could use null but I have "null" as the base case.
		if difficulty == "null":
			
			$"Audio/Menu Cancel".play()
			can_click = true
			return
		
		$"Audio/Menu Confirm".play()
		
		var tween = create_tween()
		tween.set_parallel()
		
		tween.tween_property( $Audio/Music, "volume_db", -60, 1 )
		
		var option_nodes = get_tree().get_nodes_in_group("instances")
		for j in option_nodes:
			
			if j != option_nodes[selected_song]:
				
				tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
				tween.tween_property(j, "position", j.position - Vector2(2000, 0), 0.5)
		
		Transitions.transition("down")
		
		await get_tree().create_timer(1).timeout
		
		Global.stop_song()
		
		play_song(song_file, difficulty)


@warning_ignore("shadowed_variable")
# Doesn't actually play the audio, just sends you to the scene
func play_song(song: Song, difficulty: String):
	
	var scene = song.scene
	if song.difficulties[difficulty].has("scene"): scene = song.difficulties[difficulty].scene
	
	GameHandeler.play_mode = GameHandeler.PLAY_MODE.FREEPLAY
	GameHandeler.difficulty = difficulty
	GameHandeler.freeplay = true
	Global.freeplay_album_option = selected_album
	Global.freeplay_song_option = selected_song
	Global.change_scene_to( scene )


@warning_ignore("unused_parameter")
func _on_conductor_new_beat(current_beat, measure_relative):
	
	if SettingsHandeler.get_setting("ui_bops"):
		
		Global.bop_tween( $Camera2D, "zoom", Vector2( 1, 1 ), Vector2( 1.005, 1.005 ), 0.2, Tween.TRANS_CUBIC )


func _on_difficulty_selector_selected_difficulty(difficulty: String) -> void:
	
	self.difficulty = difficulty
	load_page(selected_album)
	update_selection(selected_song)
	$"Audio/Menu Scroll".play()
