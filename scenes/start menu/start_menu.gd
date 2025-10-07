extends Node2D

# To make smooth tweens
# Ease in by < time * 0.0625 >
# Ease out by <time>

@export var intro_done: bool = true
var can_click = true
var flashing_colors = PackedColorArray([
	Color(0, 0.07451, 0.176471),
	Color(0.141449, 0, 0.175781),
	Color(0.242188, 0, 0.119202)]
	)

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$AnimationPlayer.play("start")
	Global.set_window_title("Start Screen")
	
	var keycode = SettingsManager.get_keybind("ui_accept")
	$"UI/Play Label".text = "Press " + SettingsManager.get_keycode_string(keycode) + " to Play"
	
	$Conductor.stream_player = SoundManager.music.get_path()
	
	if not SoundManager.music.playing:
		SoundManager.music.play()
	
	await $Conductor.ready
	
	$Conductor.tempo = SoundManager.music.stream._get_bpm()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	# Pressing enter
	if Input.is_action_just_pressed("ui_accept"):
		
		if intro_done:
			
			$AnimationPlayer.play("press_enter")
			can_click = false
		else:
			$AnimationPlayer.play("intro_finish")


func _on_conductor_new_beat(current_beat, measure_relative):
	
	# Metronome Bop Animation
	
	if( measure_relative % 2 == 0 ):
		
		%Metronome.can_idle = true
		%Metronome.play_animation( "idle", $Conductor.seconds_per_beat * 2 )
	
	var time = 0
	
	if intro_done:
			
			var tween = create_tween()
			
			time = 0.5
			
			# Background color phase
			$Background/ColorRect.color = flashing_colors[ current_beat % flashing_colors.size() ]
			tween.tween_property($Background/ColorRect, "color", Color(0, 0, 0), 0.3)
			
			# "Press enter" text color phasing, i most definitely could've done a sine equation
			if( current_beat % 2 == 0 ):
				
				tween.tween_property($"UI/Play Label", "theme_override_colors/font_color", Color(0, 0.366667, 1, 0.8), $Conductor.seconds_per_beat * 2)
			else:
				
				tween.tween_property($"UI/Play Label", "theme_override_colors/font_color", Color(0.501961, 0.682353, 1, 0.8), $Conductor.seconds_per_beat * 2)
	
	# Logo Bopping
	var tween2 = create_tween()
	tween2.set_trans(Tween.TRANS_CUBIC)
	
	time = 0.2
	
	tween2.tween_property( $UI/Logo, "scale", Vector2(0.95, 0.95), time * 0.0625 ).set_ease(Tween.EASE_IN_OUT)
	tween2.tween_property( $UI/Logo, "scale", Vector2(0.9, 0.9), time ).set_delay( time * 0.0625 ).set_ease(Tween.EASE_OUT)


func _on_animation_player_animation_finished(anim_name):
	
	if anim_name == "press_enter":
		Global.change_scene_to( "res://scenes/main menu/main_menu.tscn" )
