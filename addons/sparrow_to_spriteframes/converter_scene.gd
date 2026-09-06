@tool
extends Control

signal finished

var load_path: String : 
	get():
		return load_text.text.trim_suffix(".png").trim_suffix(".xml")
var save_path: String : 
	get():
		return load_path + get_save_ext()

@onready var status_label: Label = $"VBoxContainer/VBoxContainer/status label"
@onready var binary_checkbox: CheckBox = $VBoxContainer/VBoxContainer/HBoxContainer3/CheckBox
@onready var preview_sprite: TextureRect = $VBoxContainer/previewSprite

@onready var load_text: LineEdit = $"VBoxContainer/VBoxContainer/HBoxContainer/xml text"
@onready var convert: Button = $VBoxContainer/VBoxContainer/Convert
@onready var xml_find_file: Button = $"VBoxContainer/VBoxContainer/HBoxContainer/xml find file"

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


var snd: AudioStream

func _ready() -> void:
	finished.connect(finished_conversion)
	update_status()

var _running:bool = false
func init_converter():
	if _running: return
	
	_running = true
	
	update_status()
	
	if load_text.text.begins_with('uid'):
		load_text.text = ResourceUID.uid_to_path(load_text.text)
	
	attempt_conversion()
	
func finished_conversion():
	if snd:
		audio_stream_player.stream = snd
		audio_stream_player.play()

func failed(error: String):
	_running = false
	update_status(error)

func attempt_conversion():
	
	check_and_warn()
	
	var xml_parser = XMLParser.new()
	xml_parser.open(load_path + ".xml")
	
	var frames = SpriteFrames.new()
	var texture = load(load_path + ".png")
	var cur_anim_name: String
	
	var err = xml_parser.read()
	var has_default: bool = false
	while err == OK:
		if xml_parser.get_node_type() == XMLParser.NODE_ELEMENT or xml_parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			print("--- " + xml_parser.get_node_name() + " ---")
			var prev_frame_data: Dictionary
			
			if xml_parser.get_node_name() != "TextureAtlas":
				var loaded_anim_name: String = xml_parser.get_named_attribute_value("name")
				loaded_anim_name = loaded_anim_name.left(len(loaded_anim_name) - 4)
				print("loaded name: " + loaded_anim_name)
				
				if cur_anim_name != loaded_anim_name:
					frames.add_animation(loaded_anim_name)
					if loaded_anim_name == "default":
						has_default = true
					
					frames.set_animation_loop(loaded_anim_name, false)
					frames.set_animation_speed(loaded_anim_name, 24)
					cur_anim_name = loaded_anim_name
				
				var new_region = Rect2(int(xml_parser.get_named_attribute_value("x")), int(xml_parser.get_named_attribute_value("y")),
									int(xml_parser.get_named_attribute_value("width")), int(xml_parser.get_named_attribute_value("height")))
				var new_margin = Rect2()
				
				if xml_parser.has_attribute("frameX"):
					new_margin = Rect2(-int(xml_parser.get_named_attribute_value("frameX")), -int(xml_parser.get_named_attribute_value("frameY")),
										int(xml_parser.get_named_attribute_value("frameWidth")) - new_region.size.x, int(xml_parser.get_named_attribute_value("frameHeight")) - new_region.size.y)
				
				var num_frames = frames.get_frame_count(cur_anim_name)
				var prev_frame = frames.get_frame_texture(cur_anim_name, num_frames - 1) if num_frames > 0 else null
				
				if (prev_frame
				and (prev_frame_data.get("region", Vector2.ZERO))
				and (prev_frame_data.get("margin", Vector2.ZERO))):
					print("class: ", prev_frame.get_class())
					print("optimizing " + str(num_frames))
					frames.add_frame(cur_anim_name, prev_frame)
				else:
					var new_frame = AtlasTexture.new()
					new_frame.atlas = texture
					new_frame.region = new_region
					new_frame.margin = new_margin
					new_frame.filter_clip = true
					
					if xml_parser.has_attribute("rotated"):
						var image: Image = new_frame.get_image()
						image.rotate_90(COUNTERCLOCKWISE)
						new_frame.atlas = ImageTexture.create_from_image(image)
						new_region = Rect2(Vector2.ZERO, new_frame.atlas.get_size())
						new_frame.region = new_region
						if xml_parser.has_attribute("frameX"):
							new_margin = Rect2(-int(xml_parser.get_named_attribute_value("frameX")), -int(xml_parser.get_named_attribute_value("frameY")),
												int(xml_parser.get_named_attribute_value("frameWidth")) - new_region.size.x, int(xml_parser.get_named_attribute_value("frameHeight")) - new_region.size.y)
						
						new_frame.margin = new_margin
					
					prev_frame_data = {
					"region": new_region,
					"margin": new_margin
					}
					
					frames.add_frame(cur_anim_name, new_frame)
					preview_sprite.texture = new_frame
		
		await get_tree().create_timer(0.01).timeout
		err = xml_parser.read()
	
	print("complete")
	
	if !has_default:
		frames.remove_animation("default")
	
	var save_to = save_path.trim_suffix('.png').trim_suffix('.xml')
	if not save_to.get_extension() in ['tres', 'res']:
		save_to = save_to + get_save_ext()
	ResourceSaver.save(frames, save_to, ResourceSaver.FLAG_COMPRESS)
	
	finished.emit()
	frames = null
	_running = false
	check_and_warn()
	update_status("Finished Conversion")

func _on_file_dialog_file_selected(path: String) -> void:
	load_text.text = path
	check_and_warn()

func _on_convert_pressed() -> void:
	init_converter()

func _on_xml_text_text_changed(new_text: String) -> void:
	check_and_warn()

func check_and_warn():
	if _running:
		update_status("Converting...")
		set_active(false)
		return
	
	var can_convert = FileAccess.file_exists(load_text.text)
	if not can_convert:
		update_status("Cannot find file at given path")
	else:
		if load_text.text.begins_with('uid'):
			var to_path = ResourceUID.uid_to_path(load_text.text)
			can_convert = has_valid_extension(to_path)
		else:
			can_convert = has_valid_extension(load_text.text)
		
		if not can_convert:
			update_status("File found is not a .xml/.png")
	
	if can_convert:
		if not has_both_xml_and_png():
			update_status("Could not find pair of '.png' and '.xml' files at the given path")
			can_convert = false
		elif FileAccess.file_exists(save_path):
			update_status("File exists at save path already. converting will override (%s)" % save_path)
		else:
			update_status("Ready to convert")
	set_active(can_convert)

func has_both_xml_and_png() -> bool:
	var stripped = load_text.text.trim_suffix('.png').trim_suffix('.xml')
	return FileAccess.file_exists(stripped + '.png') and FileAccess.file_exists(stripped + '.xml')

func has_valid_extension(str: String):
	return str.ends_with('xml') or str.ends_with('png')

func get_save_ext() -> String:
	return ".res" if binary_checkbox.button_pressed else ".tres"

func update_status(txt: String = 'Awaiting response'):
	status_label.text = "Status: " + txt

func _on_check_box_pressed() -> void:
	check_and_warn()

func set_active(v: bool):
	convert.disabled = not v
	load_text.editable = v
	xml_find_file.disabled = not v
	binary_checkbox.disabled = not v
