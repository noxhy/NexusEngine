@icon("uid://ij1ectsa31bd")

extends Node
class_name Conductor

signal new_beat(beat: int, measure_relative: int)
signal new_step(step: int, measure_relative: int)
signal new_tempo(_tempo: float)
signal new_numerator(_numerator: int)
signal new_denominator(_denominator: int)

## The time where the conductor will [b]start[/b].
var offset: float = 0
## Node Path to an [AudioStreamPlayer] that the Conductor will conduct.
## [br]If there is no [AudioStreamPlayer], or if it isn't playing, you can set [param time] manually.
@export var stream_player: AudioStreamPlayer
## Beats per minute.
@export var tempo: float:
	set(v):
		if tempo != v:
			emit_signal(&"new_tempo", v)
		
		tempo = v
	get():
		return tempo


@export var numerator: int = 4:
	set(v):
		var emit: bool = false
		if numerator != v:
			emit = true
		
		numerator = v
		if emit:
			emit_signal(&"new_numerator", v)


@export var denominator: int = 4:
	set(v):
		var emit: bool = false
		if denominator != v:
			emit = true
		denominator = v
		
		if emit:
			emit_signal(&"new_denominator", v)

var seconds_per_beat: float:
	get():
		return (60.0 / tempo) * (4.0 / denominator)

var seconds_per_step: float:
	get():
		return seconds_per_beat / denominator

# Stored Statistics:
# These variables only exist for the purpose of grabbing info
var current_beat: int = -1:
	set(v):
		measure_relative_beat = v % numerator
		if current_beat != v:
			emit_signal(&"new_beat", v, measure_relative_beat)
		
		current_beat = v

var current_step: int = -1:
	set(v):
		measure_relative_step = v % (numerator * denominator)
		if current_step != v:
			emit_signal(&"new_step", v, measure_relative_step)
		
		current_step = v

var measure_relative_beat: int = 0
var measure_relative_step: int = 0
var time: float = 0
var latency: float = AudioServer.get_output_latency()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if stream_player and stream_player.playing:
		time = stream_player.get_playback_position()
		time -= latency
		# time += AudioServer.get_time_since_last_mix()
	
	current_beat = get_beat_at(time)
	current_step = get_step_at(time)


func get_beat_at(_time: float) -> int:
	return floor((_time - offset) / seconds_per_beat)


func get_step_at(_time: float) -> int:
	return floor((_time - offset) / seconds_per_step)


func get_measure_at(_time: float) -> int:
	return floor((_time - offset) / (seconds_per_beat * numerator))
