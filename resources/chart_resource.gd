@icon("res://assets/sprites/nodes/chart_file.png")

extends Resource
class_name Chart

@export_group("Music")

@export_file("*.mp3") var vocals = ""
@export_file("*.mp3") var instrumental = ""

@export_group("Credits") 

@export var artist = ""
@export var song_title = ""

@export_group("Chart Data")

@export var difficulty = ""
@export_range(0.0, 5.0, 0.1) var scroll_speed = 1.0
## Says the [code]offset[/code] of the chart, negative is [b]early[/b], positive is [b]late[/b]
@export var offset = 0.0

# Actual Chart Storage

@export var chart_data = {
	
	"notes": [],
	"events": [],
	"tempos": {0.0: 60},
	"meters": {0.0: [4, 16]},
	
}

func get_note_data() -> Array: return chart_data.get("notes")

func get_events_data() -> Array: return chart_data.get("events")

func get_tempos_data() -> Dictionary: return chart_data.get("tempos")

func get_meters_data() -> Dictionary: return chart_data.get("meters")
