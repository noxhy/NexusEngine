extends Button

@export var action_name: String
@export var index: int

signal selected(index: int)

func _ready() -> void:
	text = action_name


func _on_pressed() -> void:
	emit_signal("selected", index)
