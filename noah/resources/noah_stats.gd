extends Resource
class_name NoahStats
## A container of values defining the players gameplay

# explanatory.
const GOLD_RANK_REQ: float = 2.0
const PERFECT_RANK_REQ: float = 1.0
const EXCELLENT_RANK_REQ: float = 0.90
const GREAT_RANK_REQ: float = 0.80
const GOOD_RANK_REQ: float = 0.60
const LOSS_RANK_REQ: float = 0.00

## The accumulated score reached by the player.
var score: float = 0

## The accumulated score reached by the player represented as a int. Exists for basic convenience.
var score_as_int : int :
	get():
		return int(score)

## The amount of times the player missed.
var misses: int = 0

## The current combo reached by the player.
var combo: int = 0

## The highest combo reached by the player.
var max_combo: int = 0

## the total notes hit within the "sick" hit window by the player.
var sicks: int = 0

## the total notes hit within the "good" hit  window by the player.
var goods: int = 0

## the total notes hit within the "bad" hit  window by the player.
var bads: int = 0

## the total notes hit within the "shit" hit  window by the player.
var shits: int = 0 

## the total notes hit/missed within a song
var total_notes: int = 0

var grade: float : get = get_grade

var rank: String : get = get_rank

## resets all given values to their defaults.
func reset():
	score = 0
	misses = 0
	combo = 0
	max_combo = 0
	goods = 0
	bads = 0
	shits = 0
	total_notes = 0

## Copies all the values from a NoahStats instance on to self.
func copy_from(stats: NoahStats):
	score = stats.score
	misses = stats.misses
	combo = stats.combo
	max_combo = stats.max_combo
	goods = stats.goods
	bads = stats.bads
	shits = stats.shits
	total_notes = stats.total_notes
	
## adds all the values from a NoahStats instance on to self.
func add_from(stats: NoahStats):
	score += stats.score
	misses += stats.misses
	combo += stats.combo
	goods += stats.goods
	bads += stats.bads
	shits += stats.shits
	total_notes += stats.total_notes
	
	if stats.max_combo > max_combo:
		max_combo = stats.max_combo

func _to_string() -> String:
	var buffer: PackedStringArray = PackedStringArray()
	buffer.append('	Score: ' + str(int(score)))
	buffer.append('\n	Misses: ' + str(misses))
	buffer.append('\n	Combo: ' + str(combo))
	buffer.append('\n	Goods: ' + str(goods))
	buffer.append('\n	Bads: ' + str(bads))
	buffer.append('\n	Shits: ' + str(shits))
	
	return "Stats:\n%s" % ''.join(buffer)

func get_grade() -> float:
	return get_grade_from_stats(self)
	
static func get_grade_from_stats(_stats: NoahStats):
	if _stats.total_notes == 0:
		return 0.0
	if _stats.sicks == _stats.total_notes:
		return 2.0
	
	return float(_stats.sicks + _stats.goods - _stats.misses) / _stats.total_notes

func get_rank() -> String:
	return get_rank_from_grade(grade)

static func get_rank_from_stats(_stats: NoahStats):
	return get_rank_from_grade(_stats.grade)

static func get_rank_from_grade(_grade: float):
	var accuracies = [
		[_grade == GOLD_RANK_REQ, "gold"],
		[_grade == PERFECT_RANK_REQ, "perfect"],
		[_grade >= EXCELLENT_RANK_REQ, "excellent"],
		[_grade >= GREAT_RANK_REQ, "great"],
		[_grade >= GOOD_RANK_REQ, "good"],
		[_grade >= LOSS_RANK_REQ, "loss"],
	]
	
	for condition in accuracies: if condition[0]:
		return condition[1]
	return "?"
