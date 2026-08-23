extends Resource
class_name NoahStats
## Handles values defining the players gameplay.

## The required minimum [member grade] must reach to provide [member GOLD_RANK_NAME]
const GOLD_RANK_REQ: float = 2.0
## The required minimum [member grade] must reach to provide [member PERFECT_RANK_REQ]
const PERFECT_RANK_REQ: float = 1.0
## The required minimum [member grade] must reach to provide [member EXCELLENT_RANK_REQ]
const EXCELLENT_RANK_REQ: float = 0.90
## The required minimum [member grade] must reach to provide [member GREAT_RANK_REQ]
const GREAT_RANK_REQ: float = 0.80
## The required minimum [member grade] must reach to provide [member GOOD_RANK_REQ]
const GOOD_RANK_REQ: float = 0.60
## The required minimum [member grade] must reach to provide [member LOSS_RANK_REQ]
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

## The judged "grade" based off player accuracy. From [code]0.0[/code] to [code]2.0[/code]
var grade: float : get = _get_grade

## The judged "Rank" based of a players [member grade]. Check [NoahStats] constants to see the "Rank" names and [member grade] requirements.
var rank: String : get = _get_rank

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
	sicks += stats.sicks
	goods += stats.goods
	bads += stats.bads
	shits += stats.shits
	total_notes += stats.total_notes
	
	if stats.max_combo > max_combo:
		max_combo = stats.max_combo

func _get_grade() -> float:
	return get_grade_from_stats(self)

## Gets a [code]Grade[/code] from a [NoahStats] instance.
static func get_grade_from_stats(_stats: NoahStats):
	if _stats.total_notes == 0:
		return 0.0
	if _stats.sicks == _stats.total_notes:
		return 2.0
	
	return float(_stats.sicks + _stats.goods - _stats.misses) / _stats.total_notes

func _get_rank() -> String:
	return get_rank_from_grade(grade)

## Returns a Rank from form a [NoahStats] instance.
static func get_rank_from_stats(_stats: NoahStats) -> String:
	return get_rank_from_grade(_stats.grade)

## Returns a rank by a grade / float. Check [member grade] to see what the values range is.
static func get_rank_from_grade(_grade: float) -> String:
	var accuracies = [
		[_grade == GOLD_RANK_REQ, Constants.GOLD_RANK_NAME],
		[_grade == PERFECT_RANK_REQ, Constants.PERFECT_RANK_NAME],
		[_grade >= EXCELLENT_RANK_REQ, Constants.EXCELLENT_RANK_NAME],
		[_grade >= GREAT_RANK_REQ, Constants.GREAT_RANK_NAME],
		[_grade >= GOOD_RANK_REQ, Constants.GOOD_RANK_NAME],
		[_grade >= LOSS_RANK_REQ, Constants.LOSS_RANK_NAME],
	]
	
	for condition in accuracies: if condition[0]:
		return condition[1]
	return "?"

func _to_string() -> String:
	var buffer: PackedStringArray = PackedStringArray()
	buffer.append('	Score: ' + str(int(score)))
	buffer.append('\n	Misses: ' + str(misses))
	buffer.append('\n	Combo: ' + str(combo))
	buffer.append('\n	Goods: ' + str(goods))
	buffer.append('\n	Bads: ' + str(bads))
	buffer.append('\n	Shits: ' + str(shits))
	
	return "Stats:\n%s" % ''.join(buffer)
