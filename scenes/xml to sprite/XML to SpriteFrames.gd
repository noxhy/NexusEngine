extends Node2D

#
# I STOLE THIS CODE IDK WHO MADE IT (probably codist???)
# It's modified to support the bullshit "rotated" tag on the xml.
#

# ASSUMPTIONS:
# - Sheet and image have the same path
# - Sheet is an Adobe Animate XML and image is a PNG
@export var load_path: String = "res://"
@export var save_path: String = "res://"
@export var optimize: bool = false
signal finished
@onready var anim_sprite = $"UI/Display Panel/Preview"

func do_it():
	
	var xml_parser = XMLParser.new()
	xml_parser.open( load_path + ".xml" )
	
	var frames = anim_sprite.sprite_frames
	var texture = load( load_path + ".png" )
	var cur_anim_name: String
	
	print(ResourceSaver.get_recognized_extensions(frames))
	
	var err = xml_parser.read()
	while err == OK:
		
		if xml_parser.get_node_type() == XMLParser.NODE_ELEMENT or xml_parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			
			print("--- " + xml_parser.get_node_name() + " ---")
			
			if xml_parser.get_node_name() != "TextureAtlas":
				
				var loaded_anim_name: String = xml_parser.get_named_attribute_value("name")
				loaded_anim_name = loaded_anim_name.left(len(loaded_anim_name) - 4)
				print("loaded name: " + loaded_anim_name)
				
				if cur_anim_name != loaded_anim_name:
					
					frames.add_animation(loaded_anim_name)
					frames.set_animation_loop(loaded_anim_name, false)
					frames.set_animation_speed(loaded_anim_name, 24)
					cur_anim_name = loaded_anim_name
				
				var new_region = Rect2(int(xml_parser.get_named_attribute_value("x")), int(xml_parser.get_named_attribute_value("y")),
									int(xml_parser.get_named_attribute_value("width")), int(xml_parser.get_named_attribute_value("height")))
				var new_margin = Rect2()
				
				if xml_parser.has_attribute("frameX"):
					
					if !xml_parser.has_attribute("rotated"):
						
						new_margin = Rect2(-int( xml_parser.get_named_attribute_value("frameX") ), -int( xml_parser.get_named_attribute_value("frameY") ),
											int( xml_parser.get_named_attribute_value("frameWidth") ) - new_region.size.x, int( xml_parser.get_named_attribute_value("frameHeight") ) - new_region.size.y )
					else:
						
						new_margin = Rect2(-int(xml_parser.get_named_attribute_value("frameX")), -int(xml_parser.get_named_attribute_value("frameY")),
									int( xml_parser.get_named_attribute_value("frameWidth") ) - new_region.size.y, int( xml_parser.get_named_attribute_value("frameHeight")) - new_region.size.x )
				
				
				var num_frames = frames.get_frame_count(cur_anim_name)
				var prev_frame = frames.get_frame_texture(cur_anim_name, num_frames - 1) if num_frames > 0 else null
				
				if optimize and prev_frame and new_region == prev_frame.region and new_margin == prev_frame.margin:
					
					print("optimizing " + str(num_frames))
					
					if xml_parser.has_attribute("rotated"): frames.add_frame(cur_anim_name, prev_frame, 1.01)
					else: frames.add_frame(cur_anim_name, prev_frame)
				else:
					
					var new_frame = AtlasTexture.new()
					new_frame.atlas = texture
					new_frame.region = new_region
					new_frame.margin = new_margin
					new_frame.filter_clip = true
					
					if xml_parser.has_attribute("rotated"): frames.add_frame(cur_anim_name, new_frame, 1.01)
					else: frames.add_frame(cur_anim_name, new_frame)
				
				anim_sprite.scale = Vector2(176, 176) / new_region.size
				anim_sprite.scale.y = anim_sprite.scale.x
				
				$"UI/Display Panel/Label".text = loaded_anim_name
				
				anim_sprite.play(loaded_anim_name)
		await get_tree().create_timer(0.01).timeout
		err = xml_parser.read()
	
	print("done")
	
	frames.remove_animation("default")
	ResourceSaver.save(frames, save_path + ".res", ResourceSaver.FLAG_COMPRESS)
	
	emit_signal("finished")
	frames = null


func _ready():
	
	set_process(false)
	Global.set_window_title("XML to SpriteFrames Converter")
	
	await get_tree().process_frame
	
	$"UI/Input Panel/Load Path".text = load_path
	$"UI/Input Panel/Save Path".text = save_path
	
	$"UI/Input Panel/Label2".text = "Press " + "Enter" + " TO CONVERT"
	
var bunce = false


func _input(event):
	
	if event.is_action_pressed("ui_accept"):
		if bunce == false:
			
			bunce = true
			save_path = $"UI/Input Panel/Save Path".text
			load_path = $"UI/Input Panel/Load Path".text
			$"UI/Input Panel/Save Path".hide()
			$"UI/Input Panel/Load Path".hide()
			anim_sprite.sprite_frames = SpriteFrames.new()
			
			do_it()
			
			await self.finished
			$"UI/Display Panel/Label".text = "CONVERTED"
			$"Success Sound".play()
			
			$"UI/Input Panel/Save Path".text = ""
			$"UI/Input Panel/Load Path".text = ""
			
			$"UI/Input Panel/Save Path".show()
			$"UI/Input Panel/Load Path".show()
			
			bunce = false
		
	
