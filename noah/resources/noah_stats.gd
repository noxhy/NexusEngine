extends Resource
class_name NoahStats
## A container of values defining the players gameplay

## The accumulated score reached by the player.
var score: float = 0

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

## the total notes within a song
var total_notes: int = 0

## resets all given values to their defaults.
func reset():
	score = 0
	misses = 0
	combo = 0
	max_combo = 0
	goods = 0
	bads = 0
	total_notes = 0

## Copies all the values from a NoahStats instance on to self.
func copy_from(stats: NoahStats):
	score = stats.score
	misses = stats.misses
	combo = stats.combo
	max_combo = stats.max_combo
	goods = stats.goods
	bads = stats.bads
	total_notes = stats.total_notes
	
## adds all the values from a NoahStats instance on to self.
func add_from(stats: NoahStats):
	score += stats.score
	misses += stats.misses
	combo += stats.combo
	goods += stats.goods
	bads += stats.bads
	total_notes += stats.total_notes
	
	if stats.max_combo > max_combo:
		max_combo = stats.max_combo
