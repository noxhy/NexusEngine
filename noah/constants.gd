extends Node

#scene ids
var CHART_EDITOR_SCENE: String = "uid://c3lux2ajoe1g6"
var EVENT_EDITOR_SCENE: String = "uid://cq6xqods6w7lw"
var START_MENU_SCENE: String = "uid://cmn3noo2keqes"
#region Event Data

var EVENT_DATA: Dictionary = {
	"camera_position": {
		"parameters": ["Position Index"],
		"texture": "uid://b4ve504nau36k"
	},
	"play_animation": {
		"parameters": ["Group Name", "Animation ID", "(Optional) Duration"],
		"texture": "uid://d0bn2mll0jrpd"
	},
	"camera_bop": {
		"parameters": ["Camera Bop Amount", "UI Bop Amount"],
		"texture": "uid://qe3r1k3apxbl"
	},
	"camera_zoom": {
		"parameters": ["Zoom", "Duration", "Easing Type"],
		"texture": "uid://bs2p6h6sokqf0"
	},
	"bop_rate": {
		"parameters": ["Step Rate"]
	},
	"bop_strength": {
		"parameters": ["Camera Amount", "UI Amount"],
	},
	"set_smoothing": {
		"parameters": ["Toggled"],
	},
	"scroll_speed": {
		"parameters": ["Amount", "Ease Duration"],
		"texture": "uid://cdyobnrt3rnml"
	},
	"camera_shake": {
		"parameters": ["Amount", "Duration"],
		"texture": "uid://da6pn1kq8iao0"
	},
	"set_prefix": {
		"parameters": ["Group Name", "Prefix"]
	},
	"comment": {
		"parameters": [""],
		"texture": "uid://bwp1pd1s3xmka"
	}
}
#endregion

#region Transitions
var DEFAULT_TRANSITION = &"down"
var TRANSITIONS: Dictionary = {
	&"down": "uid://degdcsx3er4ug",
	&"fade": "uid://dp5sadsewp7fw"
}
#endregion

#playstate constants
var SCORING_SLOPE: float = 0.08
var SCORING_OFFSET: float = 0.05499
var COMBO_SLOPE: float = 20.0

var HOLD_SCORE_GAIN_PER_SECOND: float = 250
var MIN_SCORE_GAIN: int = 9
var MAX_SCORE_GAIN: int = 500

var HEALTH_GAIN: float = 1
var HOLD_HEALTH_GAIN_PER_SECOND: float = 6

var BAD_HIT_HEALTH_PENALTY: float = 0.5
var MISS_BASE_HEALTH_PENALTY: float = 4
var MISS_MAX_HEALTH_PENALTY: float = 20.0

var SPAM_SCORE_PENALTY: float = 10
var SPAM_HEALTH_PENALTY: float = 1
var MISS_SCORE_PENALTY: float = 100

var DEFAULT_NOTE_SKIN: String = "uid://buly8rgmgrrnm"
#region Note Types
## The note type and the corresponding animation prefix.
var NOTE_TYPES: Dictionary = {
	"mom": "",
	"no_animation": "",
	"alt_prefix": ""
}
#endregion
