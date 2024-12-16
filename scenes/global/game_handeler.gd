extends Node

# Constants are read only even if I set a new variable to the constant
# so it's just a regular variable with constant notations
# future note: ok so this apparently just also gets set whenever
# other things do so idk
@onready var DEFAULT_TALLIES: Dictionary = {
	
	"epic": 0,
	"sick": 0,
	"good": 0,
	"bad": 0,
	"shit": 0,
	"miss": 0,
	"max_combo": 0,
	"total_notes": 0
	
}


var freeplay: bool = true
var difficulty: String

var week_score: int = 0
var week_deaths: int = 0
var total_accuracy: float = 0
var songs_played: int = 0
var week_tallies: Dictionary = {}
var tallies: Dictionary = {}

var accuracy: float = 0.0
var deaths: int = 0

func started_song():
	
	tallies = {
		
		"epic": 0,
		"sick": 0,
		"good": 0,
		"bad": 0,
		"shit": 0,
		"miss": 0,
		"max_combo": 0,
		"total_notes": 0
		
	}
	accuracy = 0.0

func finished_song( score: int ):
	
	week_score += score
	week_deaths += deaths
	total_accuracy += accuracy
	songs_played += 1
	deaths = 0
	
	for tally in tallies.keys():
		
		if week_tallies.has(tally): week_tallies[tally] += tallies[tally]
		else: week_tallies[tally] = tallies[tally]

func reset_stats():
	
	accuracy = 0.0
	deaths = 0
	week_score = 0
	week_deaths = 0
	songs_played = 0
	
	# I hate that I have to do this because of Godot jank
	tallies = {
		
		"epic": 0,
		"sick": 0,
		"good": 0,
		"bad": 0,
		"shit": 0,
		"miss": 0,
		"max_combo": 0,
		"total_notes": 0
		
	}
	week_tallies = {
		
		"epic": 0,
		"sick": 0,
		"good": 0,
		"bad": 0,
		"shit": 0,
		"miss": 0,
		"max_combo": 0,
		"total_notes": 0
		
	}

func get_week_accuracy() -> float: return total_accuracy / songs_played

func get_rank() -> String:
	
	var grade: float = 0.0
	if tallies.total_notes > 0: grade = float( tallies.epic + tallies.sick + tallies.good ) / tallies.total_notes
	
	var accuracies = [
		[ ( tallies.epic + tallies.sick ) == tallies.total_notes, "gold" ],
		[ grade == 1, "perfect" ],
		[ grade >= 0.90, "excellent" ],
		[ grade >= 0.80, "great" ],
		[ grade >= 0.60, "good" ],
		[ grade >= 0, "fail" ],
	]
	
	for condition in accuracies: if condition[0]: return condition[1]
	return "?"
