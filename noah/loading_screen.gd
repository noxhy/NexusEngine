extends Node2D
class_name LoadingScreen

@onready var progress_bar = $Background/ProgressBar
static var scene = ""

var progress: Array = []
var scene_load_status: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(ResourceLoader.exists(scene), '%s could not be loaded.' % scene)
	
	ResourceLoader.load_threaded_request(scene)
	get_window().content_scale_size = Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	scene_load_status = ResourceLoader.load_threaded_get_status(scene, progress)
	progress_bar.value = progress[0] * 100.0
	
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene))
		Global.transitioning = false
		TransitionManager.resume()
