extends Node

const SICK_RATING_WINDOW: float = 0.045
const GOOD_RATING_WINDOW: float = 0.09
const BAD_RATING_WINDOW: float = 0.135
const SHIT_RATING_WINDOW: float = 0.16
const GOOD_COMBO_FREQUENCY: int = 50
const GREAT_COMBO_FREQUENCY: int = 200
const HOLD_NOTE_LENIENCY: float = 1 / 3.0

var song_scene = null

var conductor:Conductor

# Constants are read only even if I set a new variable to the constant
# so it's just a regular variable with constant notations
# future note: ok so this apparently just also gets set whenever
# other things do so idk
var DEFAULT_TALLIES: Dictionary = {
	"sick": 0,
	"good": 0,
	"bad": 0,
	"shit": 0,
	"miss": 0,
	"max_combo": 0,
	"total_notes": 0
}

enum PLAY_MODE {
	STORY_MODE,
	FREEPLAY,
	CHARTING,
	PRACTICE
}

var week_stats: NoahStats = NoahStats.new()
var deaths: int = 0
var week_deaths: int = 0

var freeplay: bool = true
var difficulty: String
var play_mode: PLAY_MODE = PLAY_MODE.FREEPLAY

# TODO: make this _

var current_week: Week

var week_songs: Array[Song] = []
var current_week_song: int = 0
var _current_song_freeplay: Song

var current_song: Song :
	get():
		if freeplay:
			return _current_song_freeplay
		if current_week_song > week_songs.size():
			return week_songs[current_week_song]
		return null

var character: PlayableCharacter
var current_character: String = ""

var songs_played: int = 0
var week_tallies: Dictionary = DEFAULT_TALLIES.duplicate()
var tallies: Dictionary = DEFAULT_TALLIES.duplicate()
var grade: float
var highscore: bool = false


var song_position: float
var seconds_per_beat: float :
	get():
		return conductor.seconds_per_beat
var seconds_per_step: float :
	get():
		return conductor.seconds_per_step
var offset: float :
	get():
		return conductor.offset

func reset_conductor():
	if conductor:
		remove_child(conductor)
		conductor.free()
	conductor = Conductor.new()
	add_child(conductor)
	conductor.new_beat.connect(_beat_change)
	conductor.new_step.connect(_step_change)

func _step_change(step: int, measure: int):
	Signals.play_conductor_step_hit.emit(step, measure)

func _beat_change(beat: int, measure: int):
	Signals.play_conductor_beat_hit.emit(beat, measure)

func _ready() -> void:
	reset_conductor()
	reset_stats()

func started_song(song: Song):
	tallies = DEFAULT_TALLIES.duplicate()
	current_song = song
	character = Preload.character_data[current_character]

func start_week(week: Week):
	current_week = week
	week_songs = week.song_list.duplicate()
	current_week_song = 0
	freeplay = false
	play_mode = GameManager.PLAY_MODE.STORY_MODE

func finished_song(_stats: NoahStats = null):
	var _score: int = 0
	if _stats:
		week_stats.add_from(_stats)
		_score = int(_stats.score)
	week_deaths += deaths
	
	deaths = 0
	
	songs_played += 1
	current_week_song += 1
	
	for tally in tallies.keys():
		if week_tallies.has(tally):
			week_tallies[tally] += tallies[tally]
		else:
			week_tallies[tally] = tallies[tally]
	
	grade = get_grade(week_tallies)
	get_rank(grade)
	if !SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "botplay"):
		match play_mode:
			PLAY_MODE.CHARTING:
				highscore = false
			
			PLAY_MODE.PRACTICE:
				highscore = false
			
			_:
				if (SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "song_speed") != 1
				or SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "scroll_speed_scale") != 1):
					highscore = SaveManager.set_song_stats(current_song, difficulty, _score, get_grade(tallies))
					if !GameManager.freeplay and current_week_song == week_songs.size():
						highscore = SaveManager.set_week_stats(current_week, difficulty, week_stats.score, grade)
					else:
						highscore = false
	else:
		highscore = false

func reset_stats():
	week_stats.reset()
	
	tallies = DEFAULT_TALLIES.duplicate()
	week_tallies = DEFAULT_TALLIES.duplicate()
	deaths = 0
	week_deaths = 0
	
	songs_played = 0
	current_week_song = 0
	


func get_grade(_tallies: Dictionary = tallies) -> float:
	if _tallies.total_notes > 0:
		if _tallies.sick == _tallies.total_notes:
			return 2
		else:
			return float(_tallies.sick + _tallies.good - _tallies.miss) / _tallies.total_notes
	else:
		return 0

func get_rank(_grade: float) -> String:
	var accuracies = [
		[_grade == 2, "gold"],
		[_grade == 1, "perfect"],
		[_grade >= 0.90, "excellent"],
		[_grade >= 0.80, "great"],
		[_grade >= 0.60, "good"],
		[_grade >= 0, "loss"],
	]
	
	for condition in accuracies: if condition[0]:
		return condition[1]
	return "?"
