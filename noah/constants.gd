extends Node

#scene ids
var CHART_EDITOR_SCENE: String = "uid://c3lux2ajoe1g6"
var EVENT_EDITOR_SCENE: String = "uid://cq6xqods6w7lw"
var START_MENU_SCENE: String = "uid://cmn3noo2keqes"
#region Event Data

# TODO: add descriptions
var EVENT_DATA: Dictionary = {
	"camera_position": {
		"parameters": ["Position Index", "Duration", "Easing Type"],
		"texture": "res://addons/at-icons/animation/film_camera.svg",
		"description": "Moves a camera towards a marker" # TODO: make these better (adding shitty rn to get a point across)
	},
	"play_animation": {
		"parameters": ["Group Name", "Animation ID", "(Optional) Duration"],
		"texture": "res://addons/at-icons/animation/film.svg",
		"description": "Plays a animation onto a character group" # TODO: make these better (adding shitty rn to get a point across)
	},
	"camera_bop": {
		"parameters": ["Camera Bop Amount", "UI Bop Amount"],
		"texture": "res://addons/at-icons/animation/photo_camera.svg",
		"description": "Bumps the camera" # TODO: make these better (adding shitty rn to get a point across)
	},
	"camera_zoom": {
		"parameters": ["Zoom", "Duration", "Easing Type"],
		"texture": "res://addons/at-icons/animation/security_camera.svg"
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
		"texture": "res://addons/at-icons/node/fast_forward.svg"
	},
	"camera_shake": {
		"parameters": ["Amount", "Duration"],
		"texture": "res://addons/at-icons/animation/video_camera.svg"
	},
	"set_prefix": {
		"parameters": ["Group Name", "Prefix"]
	},
	"comment": {
		"parameters": [""],
		"texture": "res://addons/at-icons/node/speech_bubble_ellipsis.svg"
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

## The highest rank. acquired if the player hits all notes and are all judged as [constant NoahStats.sicks].
const GOLD_RANK_NAME: String = 'gold'
## The perfect rank. acquired if the player hits all notes.
const PERFECT_RANK_NAME: String = 'perfect'
## The Excellent rank. acquired if [member NoahStats.grade] is equal or above [constant NoahStats.EXCELLENT_RANK_REQ].
const EXCELLENT_RANK_NAME: String = 'excellent'
## The Gret rank. acquired if [member NoahStats.grade] is equal or above [constant NoahStats.GREAT_RANK_REQ].
const GREAT_RANK_NAME: String = 'great'
## The Good rank. acquired if [member NoahStats.grade] is equal or above [constant NoahStats.GOOD_RANK_REQ].
const GOOD_RANK_NAME: String = 'good'
## The lowest rank. acquired if [member NoahStats.grade] is lower than [constant NoahStats.GOOD_RANK_REQ].
const LOSS_RANK_NAME: String = 'loss'
#region Note Types
## The note type and the corresponding animation prefix.
var NOTE_TYPES: Dictionary = {
	"mom": "",
	"no_animation": "",
	"alt_prefix": ""
}
#endregion
