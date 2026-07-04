extends Node

var song: Song
var chart: Chart
var difficulty: String = ""

var difficulties: Dictionary = {}
var strum_count: int = 8
var event_editor: bool = false

## Settings per strum, each key is it's label
var strum_data: Array = [
	{
		"name": "Player",
		"strums": [0, 3],
		"muted": false,
		"track": 0,
		"volume": 1,
		"hit_sounds": true,
		"waveform": true
	},
	{
		"name": "Enemy",
		"strums": [4, 7],
		"muted": false,
		"track": 1,
		"volume": 1,
		"hit_sounds": true,
		"waveform": true
		
	},
	#{
		#"name": "Third",
		#"strums": [8, 11],
		#"muted": false,
		#"track": 2,
		#
	#},
]

var event_tracks: Array = []
