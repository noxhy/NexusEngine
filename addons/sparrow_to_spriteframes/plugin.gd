@tool
extends EditorPlugin

static var converter: Control

var dock: EditorDock

func _enter_tree() -> void:
	
	var dir = get_script().resource_path.get_base_dir()
	converter = load(dir + '/converter_scene.tscn').instantiate()
	converter.snd = load(dir + '/notif.mp3')
	converter.get_node("VBoxContainer/HBoxContainer/Icon").texture = load(dir + '/Icon.svg')
	
	dock = EditorDock.new()
	dock.title = _get_plugin_name()
	dock.icon_name = &"SpriteFrames"
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	dock.available_layouts = EditorDock.DOCK_LAYOUT_HORIZONTAL
	dock.connect(&"closed", on_close)
	dock.add_child(converter)
	
	add_dock(dock)
	

func _get_plugin_name() -> String:
	return "Sparrow -> SpriteFrames"

func _exit_tree() -> void :
	remove_dock(dock)
	converter.queue_free()

func on_close():
	EditorInterface.set_plugin_enabled(_get_plugin_name(), false)
