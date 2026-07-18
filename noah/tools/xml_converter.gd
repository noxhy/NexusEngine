extends Node

#
# I STOLE THIS CODE IDK WHO MADE IT (probably codist???)
# It's modified to support the "rotated" tag on the xml.
#

# ASSUMPTIONS:
# - Sheet and image have the same path
# - Sheet is an Adobe Animate XML and image is a PNG
@export var load_path: String = "res://"
@export var save_path: String = ""
@export var optimize: bool = false
signal finished

@onready var anim_sprite = $VBoxContainer/PreviewSpr

func do_it():
	if load_path.length() == 0:
		printerr("path was not specified")
	var xml_parser = XMLParser.new()
	xml_parser.open(load_path + ".xml")
	
	var frames = anim_sprite.sprite_frames
	var texture = load(load_path + ".png")
	var cur_anim_name: String
	
	print(ResourceSaver.get_recognized_extensions(frames))
	
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
				
				if (optimize and prev_frame
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
				
				anim_sprite.scale = Vector2(176, 176) / new_region.size
				anim_sprite.scale.y = anim_sprite.scale.x
				
				anim_sprite.play(loaded_anim_name)
		
		await get_tree().create_timer(0.01).timeout
		err = xml_parser.read()
	
	print("done")
	
	if !has_default:
		frames.remove_animation("default")
	
	ResourceSaver.save(frames, save_path + ".res", ResourceSaver.FLAG_COMPRESS)
	
	emit_signal("finished")
	frames = null


func _ready() -> void:
	set_process(false)
	Global.set_window_title("XML to SpriteFrames Converter")
	get_tree().get_root().files_dropped.connect(on_files_dropped)
	
	await get_tree().process_frame
	
	$VBoxContainer/LoadTxt.text = load_path

var _running:bool = false
func init_converter():
	if _running: return
	_running = true
	
	$VBoxContainer/State.text = 'Converting...'
	
	load_path = $VBoxContainer/LoadTxt.text.trim_suffix(".png").trim_suffix(".xml")
	if save_path.length() == 0:
		save_path = load_path
	else:
		save_path = save_path.trim_suffix(".png").trim_suffix(".xml")
	
	anim_sprite.sprite_frames = SpriteFrames.new()
	do_it()
	
	await self.finished
	
	SoundManager.accept.play()
	$VBoxContainer/State.text = 'Complete'
	
	_running = false

func on_files_dropped(files: PackedStringArray):
	print("Received files: ", files)
	var file: String = files[0]
	var local_file: String = ProjectSettings.localize_path(file)
	print("File taken: ", local_file)
	if ResourceLoader.exists(file) and ["png", "xml"].has(file.get_extension()):
		$VBoxContainer/LoadTxt.text = local_file
		load_path = local_file.trim_suffix(".png").trim_suffix(".xml")
		$FileDialog.current_dir = local_file.get_base_dir()
		$FileDialog.current_file = local_file.get_file()
		$SaveDialog.current_dir = local_file.get_base_dir()
		$SaveDialog.current_file = local_file.get_file().trim_suffix(".png").trim_suffix(".xml")

func _on_save_dialog_file_selected(path: String) -> void:
	save_path = path
	init_converter()

func _on_file_dialog_file_selected(path: String) -> void:
	$VBoxContainer/LoadTxt.text = path
