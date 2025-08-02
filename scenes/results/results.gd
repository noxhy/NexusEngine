extends Node2D

@export var scrolling_text: String

var rank: String
var current_delta: float
var idx: int = 0
var grade: int
var _grade: int = 0

func _ready() -> void:
	
	Global.set_window_title("Results Screen")
	# GameHandeler.reset_stats()
	# GameHandeler.tallies.sick = randi() % 1500
	# GameHandeler.tallies.good = randi() % 1500
	# GameHandeler.tallies.bad = randi() % 750
	# GameHandeler.tallies.shit = randi() % 200
	# GameHandeler.tallies.total_notes = (
	#	GameHandeler.tallies.sick + GameHandeler.tallies.good + GameHandeler.tallies.bad + GameHandeler.tallies.shit
	#)
	#GameHandeler.tallies.max_combo = randi() % GameHandeler.tallies.total_notes
	#GameHandeler.week_score = GameHandeler.tallies.total_notes * 350
	#if GameHandeler.tallies.total_notes != GameHandeler.tallies.max_combo:
	#	GameHandeler.tallies.miss = randi() % (GameHandeler.tallies.total_notes - GameHandeler.tallies.max_combo)
	#GameHandeler.highscore = true
	#GameHandeler.character = preload("res://assets/characters/boyfriend.tres")
	#GameHandeler.difficulty = "nightmare"
	#GameHandeler.current_song = load("res://assets/songs/playable songs/cocoa/cocoa.tres")
	
	rank = GameHandeler.get_rank()
	if rank == "loss":
		$Audio/Intro.stream = GameHandeler.character["loss_intro"]
	else:
		$Audio/Intro.stream = GameHandeler.character["normal_intro"]
	$Audio/Intro.play()
	
	%Difficulty.play(GameHandeler.difficulty)
	if GameHandeler.freeplay:
		%"Song Name".text = str(GameHandeler.current_song.title, " by ", GameHandeler.current_song.artist)
	else:
		%"Song Name".text = str(GameHandeler.current_week)
	grade = min(int(GameHandeler.grade * 100), 100)
	%"Clear Percentage".text = str(grade, "%")
	
	$AnimationPlayer.play("intro")


func _process(delta: float) -> void:
	
	current_delta = delta
	
	update_display()
	%"Difficulty Display".texture = %Difficulty.sprite_frames.get_frame_texture(
		%Difficulty.animation, %Difficulty.frame
	)
	
	if Input.is_action_just_pressed("ui_accept"):
		
		GameHandeler.reset_stats()
		Transitions.transition("down")
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property($Audio/Music, "pitch_scale", 0.0, 0.5)
		
		await get_tree().create_timer(1).timeout
		
		GameHandeler.reset_stats()
		if GameHandeler.freeplay:
			Global.change_scene_to("res://scenes/freeplay/freeplay.tscn")
		else:
			Global.change_scene_to("res://scenes/story mode/story_mode.tscn")


func update_display():
	
	$"Scrolling Text/ParallaxLayer/RichTextLabel".size = Vector2(0, 0)
	$"Scrolling Text/ParallaxLayer/RichTextLabel".text = str(
		"[font_size=72][font=\"res://assets/fonts/Results Background.ttf\"]",
		scrolling_text,
		"[/font]"
	)
	$"Scrolling Text/ParallaxLayer2/RichTextLabel".text = $"Scrolling Text/ParallaxLayer/RichTextLabel".text
	
	$"Vertical Scrolling/ParallaxLayer3/RichTextLabel".size = Vector2(48, 0)
	$"Vertical Scrolling/ParallaxLayer3/RichTextLabel".text = str(
		"[font_size=72][font=\"res://assets/fonts/Results Background.ttf\"][font bt=-16.0][pulse freq=1.5 color=#ffffff90 ease=-2.0]",
		scrolling_text,
		"[/pulse][/font]"
	)
	
	var size: Vector2 = $"Scrolling Text/ParallaxLayer/RichTextLabel".size
	$"Scrolling Text/ParallaxLayer2/RichTextLabel".size = size
	
	$"Scrolling Text/ParallaxLayer".repeat_size = size + Vector2(15, size.y)
	$"Scrolling Text/ParallaxLayer2".repeat_size = size + Vector2(15, size.y)
	$"Scrolling Text/ParallaxLayer2/RichTextLabel".position = Vector2(size.x / 4, size.y)
	
	size = $"Vertical Scrolling/ParallaxLayer3/RichTextLabel".size
	$"Vertical Scrolling/ParallaxLayer3".repeat_size = Vector2(0, size.y + 70.5)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	
	if anim_name == "intro":
		$AnimationPlayer.play("score_tally")
	elif anim_name == "score_tally":
		$AnimationPlayer.play("scrolling")


func tween_tally(node: NodePath, tally: String):
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(get_node(node), "number", GameHandeler.week_tallies[tally], 0.5)


func update_score():
	%"Score Display".number = GameHandeler.week_score


func highscore():
	
	if GameHandeler.highscore:
		
		await %"Score Display".finished
		%Highscore.visible = true
		%Highscore.play("highscoreAnim")


func _on_highscore_animation_finished() -> void:
	%Highscore.play("loop")


func clear_tally():
	
	$AnimationPlayer.pause()
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(self.grade_step, 0.0, float(grade), 2.0)
	
	await tween.finished
	
	$"Audio/Intro Finish".pitch_scale = 0.5 + (grade / 100.0)
	$"Audio/Intro Finish".play()
	$AnimationPlayer.play()
	scrolling_text = rank.to_upper()
	
	var scene = load(GameHandeler.character["result_nodes"][rank])
	var instance = scene.instantiate()
	
	instance.position = Vector2(380, 360)
	
	%"Character Viewport".add_child(instance)
	
	await $Audio/Intro.finished
	
	$Audio/Music.stream = GameHandeler.character["result_songs"][rank]
	$Audio/Music.play()


func grade_step(g: float):
	
	if (int(g) != _grade):
		
		if (idx % 2) == 0:
			
			$Audio/Step.play(0.05)
			$Audio/Step.pitch_scale = 1 + (g / 100.0)
		
		idx += 1
	
	$"UI/Clear Percent/Label".text = str(int(g))
	_grade = int(g)
