extends Node

const SICK_RATING_WINDOW = 0.045
const GOOD_RATING_WINDOW = 0.09
const BAD_RATING_WINDOW = 0.135
const SHIT_RATING_WINDOW = 0.16

# Constants are read only even if I set a new variable to the constant
# so it's just a regular variable with constant notations
# future note: ok so this apparently just also gets set whenever
# other things do so idk
@onready var DEFAULT_TALLIES: Dictionary = {
	
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

var freeplay: bool = true
var difficulty: String
var play_mode = PLAY_MODE.FREEPLAY
var current_song: Song
var current_week: String
var character: PlayableCharacter
var current_character: String = "boyfriend"

var week_score: int = 0
var week_deaths: int = 0
var total_accuracy: float = 0
var songs_played: int = 0
var week_tallies: Dictionary = DEFAULT_TALLIES.duplicate()
var tallies: Dictionary = DEFAULT_TALLIES.duplicate()
var grade: float
var highscore: bool = false

var accuracy: float = 0.0
var deaths: int = 0
var song_position: float
var seconds_per_beat: float
var offset: float

func _ready() -> void:
	reset_stats()

func started_song(song: Song):
	
	tallies = DEFAULT_TALLIES.duplicate()
	accuracy = 0.0
	current_song = song
	character = Preload.character_data[current_character]

func finished_song(score: int):
	
	week_score += score
	week_deaths += deaths
	total_accuracy += accuracy
	songs_played += 1
	deaths = 0
	
	for tally in tallies.keys():
		
		if week_tallies.has(tally): week_tallies[tally] += tallies[tally]
		else: week_tallies[tally] = tallies[tally]
	
	get_rank()
	if !SettingsManager.get_setting("botplay"):
		
		match play_mode:
			
			PLAY_MODE.CHARTING:
				highscore = false
			
			PLAY_MODE.PRACTICE:
				highscore = false
			
			_:
				
				if GameManager.freeplay:
					highscore = SaveManager.set_song_stats(current_song.title, difficulty, score, grade)
				else:
					highscore = SaveManager.set_week_stats(current_week, difficulty, score, grade)
		
	else:
		highscore = false

func reset_stats():
	
	accuracy = 0.0
	deaths = 0
	week_score = 0
	week_deaths = 0
	songs_played = 0
	
	tallies = DEFAULT_TALLIES.duplicate()
	week_tallies = DEFAULT_TALLIES.duplicate()

func get_week_accuracy() -> float: return total_accuracy / songs_played

func get_rank(_grade: Variant = null) -> String:
	
	var _tallies = week_tallies
	
	if _grade == null:
		
		if _tallies.total_notes > 0:
			
			if (_tallies.sick) == _tallies.total_notes:
				_grade = 2
			else:
				_grade = float(_tallies.sick + _tallies.good - _tallies.miss) / _tallies.total_notes
		else:
			_grade = 0
		
		grade = _grade
	
	var accuracies = [
		[_grade == 2, "gold"],
		[_grade == 1, "perfect"],
		[_grade >= 0.90, "excellent"],
		[_grade >= 0.80, "great"],
		[_grade >= 0.60, "good"],
		[_grade >= 0, "loss"],
	]
	
	for condition in accuracies: if condition[0]: return condition[1]
	return "?"
