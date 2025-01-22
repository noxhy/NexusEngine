extends Node

var song: Song = null
var difficulty: String = ""

var difficulties: Dictionary = {}
var strum_count: int = 8
var snap: float = 16
## Settings per strum, each key is it's label
var strum_data: Dictionary = {
	
	"Enemy": {
		
		"strums": [0, 1, 2, 3],
		"mute": false,
		"track": 0,
		
	},
	"Player": {
		
		"strums": [4, 5, 6, 7],
		"mute": false,
		"track": 0,
		
	},
}
