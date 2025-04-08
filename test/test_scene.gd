extends Node2D

@export var chart: Chart

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var path: String = "res://test/chart.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	var data: Dictionary = {
		
		"version": "2.0.0",
		"scrollSpeed": {"hard": 2.4},
		  "events": [],
		  "notes": {"hard": []},
		  "generatedBy": "noah"
		
	}
	
	# Adding Note Data
	for i in chart.chart_data["notes"]:
		
		var note: Dictionary = {}
		var time = i[0] * 1000.0
		note["t"] = time
		var tempo = chart.get_tempo_at(time)
		var seconds_per_beat = 60.0 / tempo
		note["d"] = i[1]
		note["l"] = i[2] * 1000.0 * seconds_per_beat
		
		data["notes"]["hard"].append(note)
	
	var json = JSON.stringify(data, "\t")
	file.store_string(json)
	$RichTextLabel.text = json

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
