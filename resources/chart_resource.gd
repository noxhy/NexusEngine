@icon("res://assets/sprites/nodes/chart_file.png")

extends Resource
class_name Chart

@export_group("Chart Data")

@export_range(0.0, 5.0, 0.1) var scroll_speed = 1.0
## Says the [code]offset[/code] of the chart, negative is [b]early[/b], positive is [b]late[/b]
@export var offset = 0.0

# Actual Chart Storage

@export var chart_data = {
	
	"notes": [],
	"events": [],
	"tempos": { 0.0: 60 },
	"meters": { 0.0: [ 4, 16 ] },
	
}


func get_notes_data() -> Array: return chart_data.get("notes")
func get_events_data() -> Array: return chart_data.get("events")
func get_tempos_data() -> Dictionary: return chart_data.get("tempos")
func get_meters_data() -> Dictionary: return chart_data.get("meters")


func get_tempo_at(time: float) -> float:
	
	var output: float = -1
	for point in get_tempos_data(): if time >= point: output = get_tempos_data().get(point)
	else: continue
	
	return output


func get_meter_at(time: float) -> Array:
	
	var output: Array = []
	for point in get_meters_data(): if time >= point: output = get_meters_data().get(point)
	else: continue
	
	return output
