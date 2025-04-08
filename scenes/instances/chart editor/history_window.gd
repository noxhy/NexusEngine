extends Window

const HISTORY_BUTTON_PRELOAD = preload("res://scenes/instances/chart editor/history_button.tscn")

signal selected(index: int)

func add_action(action_name: String) -> Node:
	
	var history_button_instance = HISTORY_BUTTON_PRELOAD.instantiate()
	
	history_button_instance.action_name = action_name
	
	$ScrollContainer/VBoxContainer.add_child(history_button_instance)
	# history_button_instance.connect("selected", self.select)
	return history_button_instance


func _on_close_requested() -> void:
	self.visible = false


func select(index: int): emit_signal("selected", index)
