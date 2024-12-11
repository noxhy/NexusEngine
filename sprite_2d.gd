extends Node2D

@onready var swf = $SwfAnimation

func _ready() -> void:
	swf.set_animation("DEA")


func _on_swf_animation_play_end() -> void:
	swf.set_animation("WAI")
