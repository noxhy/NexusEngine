@tool
extends EditorPlugin


var sparrow_spriteframes


func _enter_tree() -> void:
	sparrow_spriteframes = preload('res://addons/godot_sparrow/sparrow_spriteframes.gd').new()
	add_import_plugin(sparrow_spriteframes)


func _exit_tree() -> void:
	remove_import_plugin(sparrow_spriteframes)
	sparrow_spriteframes = null
