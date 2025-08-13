extends Node2D

@export var debug_visible = true

var loading_screen = preload("res://scenes/global/loading_screen.tscn")
var new_scene: String = "res://test/test_scene.tscn"
var debug_info: String = ""
var fullscreen = false

var freeplay_difficulty: int = 0
var freeplay_song_option: int = 0

var death_stats: Dictionary = {}

var song_scene = "res://test/test_scene.tscn"

var max_memory: float = 0.0
var transitioning: bool = false


func _ready():
	SettingsHandeler.load_settings()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# Peformance Test
	
	$"UI/Performance Label".visible = SettingsHandeler.get_setting("show_performance")
	if SettingsHandeler.get_setting("show_performance"):
		
		$"UI/Performance Label".text = "FPS: " + str(Engine.get_frames_per_second())
		$"UI/Performance Label".text += "\nDelta: " + str(snappedf(delta, 0.001))
		var memory = snapped(OS.get_static_memory_usage() / 1024.0 / 1024.0, 0.01)
		max_memory = max(max_memory, memory)
		$"UI/Performance Label".text += "\nMEM: " + str(memory) + " MB"
		$"UI/Performance Label".text += " / " + str(max_memory) + " MB"
	
	
	# Debug Messages
	
	
	$"UI/Debug Label".visible = debug_visible
	if debug_visible:
		
		$"UI/Debug Label".text = debug_info
	
	
	if Input.is_action_just_pressed("fullscreen"):
		
		fullscreen = !fullscreen
		
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	elif Input.is_action_just_pressed("ui_plus"):
		
		var master_volume = SettingsHandeler.get_setting("master_volume")
		SettingsHandeler.set_setting("master_volume", clamp(master_volume + 6, -60, 0))
		SettingsHandeler.save_settings()
		show_volume()
		$"UI/Voume Node/Hide Timer".start(1.5)
	
	elif Input.is_action_just_pressed("ui_minus"):
		
		var master_volume = SettingsHandeler.get_setting("master_volume")
		SettingsHandeler.set_setting("master_volume", clamp(master_volume - 6, -60, 0))
		SettingsHandeler.save_settings()
		show_volume()
		$"UI/Voume Node/Hide Timer".start(1.5)
	
	elif Input.is_action_just_pressed("mute"):
		
		AudioServer.set_bus_mute(0, !AudioServer.is_bus_mute(0))
		show_volume()
		$"UI/Voume Node/Hide Timer".start(1)
	
	elif Input.is_action_just_pressed("reload"): get_tree().reload_current_scene()
	
	AudioServer.set_bus_volume_db(0, SettingsHandeler.get_setting("master_volume"))
	AudioServer.set_bus_volume_db(1, SettingsHandeler.get_setting("music_volume"))
	AudioServer.set_bus_volume_db(2, SettingsHandeler.get_setting("sfx_volume"))


# Scene Changing


func change_scene_to(path: String):
	
	transitioning = true
	get_tree().change_scene_to_packed(loading_screen)
	new_scene = path


# Global Song


func play_song(path: String, song_position: float = 0.0):
	
	$Music/Music.stream = load(path)
	$Music/Music.play(song_position)

func stop_song():
	
	$Music/Music.stop()

func set_song_volume(volume: float = 0.0):
	
	$Music/Music.volume_db = volume

func get_song_volume() -> float: return $Music/Music.volume_db

func song_playing() -> bool: return $Music/Music.playing

func get_song_position() -> float: return $Music/Music.get_playback_position()


# Util


func bop_tween(object: Object, property: NodePath, original_val: Variant, final_val: Variant, duration: float, trans: Tween.TransitionType):
	
	var tween = create_tween()
	tween.set_trans(trans)
	
	tween.tween_property(object, property, final_val, duration * 0.0625).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(object, property, original_val, duration).set_ease(Tween.EASE_OUT).set_delay(duration * 0.0625)

func set_window_title(title: String): DisplayServer.window_set_title("Friday Night Funkin' Nexus Engine 2.3 | " + title)

func float_to_time(time: float) -> String:
	
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = (time - int(time))
	milliseconds = snapped(milliseconds, 0.001)
	
	if seconds < 10:
		return str(minutes) + ":0" + str(int(seconds) % 60) + str(milliseconds).trim_prefix("0")
	else:
		return str(minutes) + ":" + str(int(seconds) % 60) + str(milliseconds).trim_prefix("0")

func format_number(num: int) -> String:
	
	var output: String = str(num).trim_prefix("-").reverse()
	var length: int = output.length()
	
	var character: int = 0
	for i in range(length):
		
		if character % 3 == 0 and character != 0: output = output.insert(character, ",")
		character += 1
	
	output = output.reverse()
	if num < 0: output = "-" + output
	return output


# Visual Util


func show_volume():
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property($"UI/Voume Node", "position", Vector2(0, -360), 0.5)
	$"UI/Voume Node/Volume Sound".play()
	
	var master_volume = SettingsHandeler.get_setting("master_volume")
	
	if AudioServer.is_bus_mute(0):
		$"UI/Voume Node/ColorRect/Label".text = "Muted"
	else:
		$"UI/Voume Node/ColorRect/Label".text = "Master Volume: " + str(master_volume) + " db"


func hide_volume():
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property($"UI/Voume Node", "position", Vector2(0, -392), 0.5)


func _on_hide_timer_timeout(): hide_volume()
