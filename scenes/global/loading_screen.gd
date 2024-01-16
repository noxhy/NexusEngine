extends Node2D

@export var scene = "res://test/test_scene.tscn"

var progress = []
var scene_load_status = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	scene = Global.new_scene
	SettingsHandeler.load_settings()
	ResourceLoader.load_threaded_request(scene)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	scene_load_status = ResourceLoader.load_threaded_get_status(scene, progress)
	
	var progress_bar = $Background/ProgressBar
	progress_bar.value = progress[0] * 100
	
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		
		get_tree().change_scene_to_packed( ResourceLoader.load_threaded_get( scene ) )


func _input(event):
	
	# Funny Bop
	if event.is_pressed():
		var tween = create_tween()
		var time = 0.2
		
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property( $Background/LoadingScreen, "scale", Vector2(1.05, 1.05), time * 0.0625 ).set_ease( Tween.EASE_IN_OUT )
		tween.tween_property( $Background/LoadingScreen, "scale", Vector2(1.0, 1.0), time ).set_delay( time * 0.0625 ).set_ease( Tween.EASE_OUT )
