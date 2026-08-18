extends TextureProgressBar
class_name BasicHealthBar

var target_health: float = 50

func _ready() -> void:
	Signals.play_health_changed.connect(health_changed)

func health_changed(v: float):
	target_health = v

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	value = Global.frame_independent_lerp(value, target_health, 25, delta)
	update_performance_text()

func update_performance_text():
	var perf_str: String = 'Botplay'
	
	if not SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "botplay"):
		perf_str = "Score: " + Global.format_number(GameManager.score) \
		+ " • " + "Misses: " + str(GameManager.tallies.get("miss", 0))
	
	$Performance.text = perf_str
