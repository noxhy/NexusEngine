extends Node2D

var mod_node = load("uid://dquulk3yl1u8e")
var nodes: Array = []

var selected: int = -1

@onready var mod_container = %"Mod Container"
@onready var info_container = %"Information Container"
@onready var mod_icon = %Icon
@onready var mod_name = %Name
@onready var mod_description = %Description
@onready var credits = %Credits
@onready var information_label = %"Notification Label"

# Meant to be replaced
func _ready() -> void:
	display_mods()
	
	if ModManager.mod_data.size() == 1 and get_tree().get_nodes_in_group(&"mods")[0].errors.is_empty():
		selected = 0
		_on_run_mod_pressed()
		return
	
	update(-1)
	
	var i: int = 0
	for node in get_tree().get_nodes_in_group(&"mods"):
		node.connect(&"mouse_entered", self.update.bind(i))
		node.connect(&"mouse_exited", self.update.bind(-1))
		node.connect(&"gui_input", self.mod_input.bind(node))
		i += 1
	
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	http.connect(&"request_completed", self.engine_http)
	
	var error = http.request("https://raw.githubusercontent.com/noxhy/NoahEngine/refs/heads/master/project.godot")
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"chart_editor"):
		Global.change_scene_to(Constants.CHART_EDITOR_SCENE, null)


func display_mods() -> void:
	for mod_dir in ModManager.mods:
		var data = ModManager.mod_data[mod_dir]
		
		var mod_instance = mod_node.instantiate()
		mod_container.add_child(mod_instance)
		mod_instance.image = ImageTexture.create_from_image(Image.load_from_file(mod_dir.path_join("icon.png")))
		mod_instance.mod_name = data.get("name", "No name found.")
		mod_instance.description = data.get("credits", "No credits found.")
		mod_instance.dir = mod_dir
		
		if !data.get("supported_versions", []).has(ProjectSettings.get_setting("application/config/version")):
			mod_instance.errors.append(ModManager.ModError.OUTDATED_ENGINE)
		
		if data.has("meta_link"):
			var http: HTTPRequest = HTTPRequest.new()
			add_child(http)
			var github_http = func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
				var mod_version = JSON.parse_string(body.get_string_from_utf8()).get("version", "0.0.0")
				
				if mod_version != ModManager.mod_data[mod_dir].get("version", "0.0.0"):
					mod_instance.errors.append(ModManager.ModError.OUTDATED_MOD)
				
				update(selected)
			
			http.connect(&"request_completed", github_http)
			http.request(data.get("meta_link", ""))


func update(i: int):
	var j: int = 0
	for node in get_tree().get_nodes_in_group(&"mods"):
		if j != selected:
			if !node.errors.is_empty():
				node.change_style(ModNode.ButtonStyle.WRONG)
			elif j == i:
				node.change_style(ModNode.ButtonStyle.HOVER)
			else:
				node.change_style(ModNode.ButtonStyle.IDLE)
		else:
			node.change_style(ModNode.ButtonStyle.ACTIVE)
		
		j += 1


func update_mod_info():
	var mod_dir: String = ModManager.mods[selected]
	var mod_instance = get_tree().get_nodes_in_group(&"mods")[selected]
	
	mod_icon.texture = ImageTexture.create_from_image(Image.load_from_file(mod_dir.path_join("icon.png")))
	mod_name.text = ModManager.mod_data[mod_dir].get("name", "No name found.")
	credits.text = ModManager.mod_data[mod_dir].get("credits", "No credits found.")
	mod_description.text = ""
	
	if !mod_instance.errors.is_empty():
		mod_description.text = str("[color=red]Error(s): ", format_errors(mod_instance.errors, ModManager.mod_data[mod_dir]), "[/color]\n")
	
	mod_description.text += str("Version: ", ModManager.mod_data[mod_dir].get("version", "0.0.0"))
	mod_description.text += str("\nDescription: ", ModManager.mod_data[mod_dir].get("description", "No description found."))


func mod_input(event: InputEvent, node: Variant):
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			selected = ModManager.mods.find(node.dir)
			info_container.visible = true
			update(selected)
			update_mod_info()


func _on_run_mod_pressed() -> void:
	ModManager.start_scene = true
	await get_tree().process_frame
	ModManager.run_mod(ModManager.mods[selected])

# Checks the current master engine version
func engine_http(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.parse(body.get_string_from_utf8())
	
	var engine_version: String = config.get_value("application", "config/version", "0.0.0")
	var current_version: String = ProjectSettings.get_setting("application/config/version")
	
	if current_version != engine_version:
		information_label.text = "[url=https://github.com/noxhy/NoahEngine/releases]Update available: %s[/url]" % engine_version


func _on_notification_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))


func format_errors(list: Array, data: Dictionary = {}) -> String:
	var output: Array = []
	for error in list:
		match error:
			ModManager.ModError.OUTDATED_ENGINE:
				output.append(str("This mod supports NoahEngine versions: ", ", ".join(data.get("supported_versions", []))))
			
			ModManager.ModError.OUTDATED_MOD:
				output.append(str("[url=", data.get("download_link"), "]Update available[/url]."))
	
	return "\n".join(output)


func _on_description_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
