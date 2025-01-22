@icon("res://assets/sprites/nodes/conductor.png")

extends Node
class_name Conductor

signal new_beat(current_beat: int, measure_relative: int)
signal new_step(current_step: int, measure_relative: int)

## The time where the conductor will [b]start[/b].
@export_range(0, 1000, 1) var offset = 0
## Node Path to an [code]AudioStreamPlayer[/code] that the Conductor will conduct.
@export_node_path("AudioStreamPlayer") var stream_player
## Beats per minute.
@export var tempo = 60.0

# Time Singatures
# Key:
# 4/16 = (♬♬ ♬♬ ♬♬ ♬♬) - Default
# 4/12 = (♪♪♪ ♪♪♪ ♪♪♪ ♪♪♪) - Triplets

var beats_per_measure = 4  	# The amount of beats in a measure (Default: 4)
var steps_per_measure = 4 * beats_per_measure  	# The amount of notes in a measure (Default: 16)

var seconds_per_beat = 1.0

var old_beat = -1
var old_step = -1

# Stored Statistics:
# These variables only exist for the purpose of grabbing info

var current_beat = 0
var current_step = 0
var measure_relative_beat = 0
var measure_relative_step = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	var time = get_node(stream_player).get_playback_position()
	time -= AudioServer.get_output_latency()
	
	current_beat = get_beat_at(time)
	current_step = get_step_at(time)
	
	measure_relative_beat = current_beat % beats_per_measure
	measure_relative_step = current_step % steps_per_measure
	
	seconds_per_beat = 60.0 / tempo
	
	# This detects if the beat or step changes
	if old_step != current_step:
		
		old_step = current_step
		emit_signal("new_step", current_step, measure_relative_step)
	
	if old_beat != current_beat:
		
			old_beat = current_beat
			emit_signal("new_beat", current_beat, measure_relative_beat)


func get_beat_at(time: float) -> int:
	
	time += offset
	return int(time / seconds_per_beat)


func get_step_at(time: float) -> int:
	
	time += offset
	@warning_ignore("integer_division")
	return int(time / (seconds_per_beat / (steps_per_measure / beats_per_measure)))


func get_measure_at(time: float) -> int:
	
	time += offset
	return int(time / (seconds_per_beat  * beats_per_measure))
