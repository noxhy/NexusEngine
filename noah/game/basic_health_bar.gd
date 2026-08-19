extends TextureProgressBar
class_name BasicHealthBar

var target_health: float = 50
var target_score: int = 0


func _ready() -> void:
	Signals.play_health_changed.connect(health_changed)
	Signals.play_stats_changed.connect(stats_changed)

func health_changed(v: float, delta: float):
	target_health = v
	
func stats_changed(stats: NoahStats):
	target_score = int(stats.score)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.value = Global.frame_independent_lerp(self.value, target_health, 25, delta)
	update_performance_text()

func update_performance_text():
	var perf_str: String = 'Botplay'
	
	if not SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "botplay"):
		perf_str = "Score: " + Global.format_number(target_score) \
		+ " • " + "Misses: " + str(GameManager.tallies.get("miss", 0))
	
	$Performance.text = perf_str
