extends Node2D

const MENU_OPTION_NODE = preload("res://scenes/instances/freeplay/capsule.tscn")

@export var can_click: bool = true
@export var difficulties: Array[String]

@onready var options: Array

var difficulty: String = "null"
var album: Album
var difficulty_songs: Dictionary

var current_grade: int
var current_highscore: int

var dj: FreeplayCharacter

# Called when the node enters the scene tree for the first time.
func _ready():
	
	difficulty = difficulties[0] 
	$"Difficulty Selector".difficulties = difficulties
	album = Preload.character_data[GameHandeler.current_character]["album"]
	
	@warning_ignore("shadowed_variable")
	for difficulty in difficulties:
		difficulty_songs[difficulty] = []
	
	for song in album.song_list:
		
		@warning_ignore("shadowed_variable")
		for difficulty in song.difficulties:
			difficulty_songs[difficulty].append(song)
	
	Global.set_window_title("Freeplay Menu")
	
	var dj_scene = Preload.character_data[GameHandeler.current_character]["resource"].dj
	
	dj = dj_scene.instantiate()
	
	dj.position = Vector2(-32, 320)
	
	$Background/CardGlow.add_child(dj)
	dj.add_to_group("djs")
	dj.animated_symbol.connect("looped", self.dj_animation_looped)
	dj.animation = "intro"
	
	load_page()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	if can_click:
		
		if Input.is_action_just_pressed("ui_up"):
			update_selection(Global.freeplay_song_option - 1)
		
		elif Input.is_action_just_pressed("ui_down"):
			update_selection(Global.freeplay_song_option + 1)
		
		elif Input.is_action_just_pressed("ui_accept"):
			select_option(Global.freeplay_song_option)
		
		elif Input.is_action_just_pressed("ui_cancel"):
			
			Transitions.transition("down")
			can_click = false
			
			$"Audio/Menu Cancel".play()
			
			await get_tree().create_timer(1).timeout
			
			Global.change_scene_to("res://scenes/main menu/main_menu.tscn")


# Updates visually what happens when a new index is set for a selection


func load_page():
	
	get_tree().call_group("instances", "queue_free")
	
	options = difficulty_songs[difficulty]
	
	var index: int = 0
	for song_file in options:
		
		var menu_option_instance = MENU_OPTION_NODE.instantiate()
		
		menu_option_instance.text = song_file.title
		menu_option_instance.icon = song_file.icons.get_frame_texture("default", 0)
		menu_option_instance.position = Vector2(-270, -60)
		menu_option_instance.scale = Vector2(0.75, 0.75)
		menu_option_instance.index = index
		
		$UI.add_child(menu_option_instance)
		menu_option_instance.add_to_group("instances")
		index += 1
	
	$"UI/Album Cover".texture = album.cover
	$"UI/Album Cover".scale.x = 262.0 / album.cover.get_width()
	$"UI/Album Cover".scale.y = $"UI/Album Cover".scale.x
	%"Album Name".text = album.name
	%"Album Song List".text = album.credits


func update_selection(i: int):
	
	var instances = get_tree().get_nodes_in_group("instances")
	
	Global.freeplay_song_option = wrapi(
		i, 0, instances.size()
		)
	i = Global.freeplay_song_option
	var index: int = 0
	
	$Audio/Music.volume_db = -60
	if options.size() == 0:
		return
	
	var song_file = options[instances[i].index]
	$"Audio/Menu Scroll".play()
	$Audio/Music.stream = song_file.instrumental
	$Audio/Music.volume_db = -60
	$Audio/Music.play()
	
	$"Difficulty Selector".available_difficulties = song_file.difficulties.keys()
	
	$Conductor.tempo = song_file.tempo
	
	var tween = create_tween()
	tween.set_parallel()
	
	for j in instances:
		
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var node_position = Vector2(-270 + (60 * sin(index - i + 1)), (index - i) * 115 - 60)
		tween.tween_property(j, "position", node_position, 0.25)
		
		if index == i:
			
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
		tween.tween_property($Audio/Music, "volume_db", 0.0, 1)
	
	
	var grade = SaveHandeler.get_grade(song_file.title, difficulty)
	if grade == -1: grade = 0
	tween.tween_method(
		self.update_grade, current_grade, grade * 100, 0.3
		).set_trans(Tween.TRANS_QUART)
	
	var highscore = SaveHandeler.get_highscore(song_file.title, difficulty)
	highscore = max(0, highscore)
	$"UI/Score Display".number = highscore


# Called when an option was selected
func select_option(i: int):
	
	if can_click:
		
		var song_file = options[get_tree().get_nodes_in_group("instances")[i].index]
		
		# Lock Check
		if song_file.locked: return
		
		can_click = false
		$"Difficulty Selector".set_process(false)
		$"Audio/Menu Confirm".play()
		
		var tween = create_tween()
		tween.set_parallel()
		
		tween.tween_property( $Audio/Music, "volume_db", -60, 1 )
		
		var option_nodes = get_tree().get_nodes_in_group("instances")
		for j in option_nodes:
			
			if j != option_nodes[i]:
				
				tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
				tween.tween_property(j, "position", j.position - Vector2(2000, 0), 0.5)
		
		dj.animation = "confirm"
		Global.freeplay_song_option = i
		Transitions.transition("down")
		
		await get_tree().create_timer(1).timeout
		
		Global.stop_song()
		
		play_song(song_file, difficulty)


@warning_ignore("shadowed_variable")
# Doesn't actually play the audio, just sends you to the scene
func play_song(song: Song, difficulty: String):
	
	var scene = song.scene
	if song.difficulties[difficulty].has("scene"):
		scene = song.difficulties[difficulty].scene
	
	GameHandeler.play_mode = GameHandeler.PLAY_MODE.FREEPLAY
	GameHandeler.difficulty = difficulty
	GameHandeler.freeplay = true
	Global.change_scene_to(scene)


@warning_ignore("unused_parameter")
func _on_conductor_new_beat(current_beat, measure_relative):
	
	if SettingsHandeler.get_setting("ui_bops"):
		Global.bop_tween($Camera2D, "zoom", Vector2(1, 1), Vector2(1.005, 1.005), 0.2, Tween.TRANS_CUBIC)


@warning_ignore("shadowed_variable")
func _on_difficulty_selector_selected_difficulty(difficulty: String) -> void:
	
	self.difficulty = difficulty
	load_page()
	update_selection(Global.freeplay_song_option)
	$"Audio/Menu Scroll".play()


func update_grade(grade: int):
	
	$Above/ClearBox/Label.text = str(int(grade))
	current_grade = grade


func dj_animation_looped():
	
	if dj.animation == "intro":
		dj.animation = "idle"
