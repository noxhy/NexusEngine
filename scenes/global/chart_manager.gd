extends Node

static var song: Song = null
static var difficulty: String = ""

static var difficulties: Dictionary = {}
static var strum_count: int = 8
static var snap: float = 16

## Settings per strum, each key is it's label
var strum_data: Dictionary = {
	
	"Player": {
		
		"strums": [0, 3],
		"muted": false,
		"track": 0,
		
	},
	"Enemy": {
		
		"strums": [4, 7],
		"muted": false,
		"track": 1,
		
	},
}
