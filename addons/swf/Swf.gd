@tool
extends EditorPlugin



func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_custom_type("SwfAnimation", "Node2D", preload("res://addons/swf/SwfAnimation.gd"), preload("swf.png"))

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_custom_type("SwfAnimation")
