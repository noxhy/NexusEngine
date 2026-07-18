@icon("uid://dqfu1k7ka1prj")
extends Node
class_name Stage

func _ready() -> void:
	Signals.play_conductor_beat_hit.connect(_on_conductor_new_beat)

func _on_conductor_new_beat(current_beat, measure_relative):
	pass
