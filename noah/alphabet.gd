@tool
@icon("res://addons/at-icons/node2d/font.svg")

extends Node2D
class_name Alphabet

@export_group("Text Settings")
@export_multiline() var text:String = "":
	set(value):
		text = value
		update_text(value)

@export var horizontal_alignment: HorizontalAlignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT:
	set(v):
		horizontal_alignment = v
		update_text(text)

@export var vertical_alignment: VerticalAlignment = VerticalAlignment.VERTICAL_ALIGNMENT_TOP:
	set(v):
		vertical_alignment = v
		update_text(text)

@export_group("Glyph Settings")
@export var sprite_frames:SpriteFrames:
	set(value):
		sprite_frames = value
		update_text(text)

## ex. " bold"
@export var forced_anim_suffix:StringName = &"":
	set(value):
		forced_anim_suffix = value
		update_text(text)

@export var line_gap_offset:float = 0.0:
	set(value):
		line_gap_offset = value
		update_text(text)

@export var default_glyph_gap: float = 0.0:
	set(value):
		default_glyph_gap = value
		update_text(text)

@export var default_bottom_padding: float = 0.0:
	set(value):
		default_bottom_padding = value
		update_text(text)

@export_subgroup("Overrides")
@export var glyph_gaps:Dictionary[String, float] = {" ": 40.0}:
	set(value):
		glyph_gaps = value
		update_text(text)

@export var glyph_offsets:Dictionary[String, Vector2] = {
	"g": Vector2(0, 15),
	"j": Vector2(0, 15),
	"p": Vector2(0, 15),
	"q": Vector2(0, 15),
	"y": Vector2(0, 15),
	"\'": Vector2(0, -25),
	"-": Vector2(0, -18),
	"=": Vector2(0, -10),
	"+": Vector2(0, -8),
	"\"": Vector2(0, -18),
	"”": Vector2(0, -18),
	"“": Vector2(0, -18),
}:
	set(value):
		glyph_offsets = value
		update_text(text)

@export var glyph_name_overrides:Dictionary[String, StringName] = {
	"&": &"amp",
	"😠": &"angry faic",
	"'": &"apostraphie",
	",": &"comma",
	"$": &"dollarsign",
	"↓": &"down arrow",
	"”": &"end parentheses",
	"!": &"exclamation point",
	"/": &"forward slash",
	"#": &"hashtag ",
	"♥": &"heart",
	"♡": &"heart",
	"←": &"left arrow",
	"*": &"multiply x",
	".": &"period",
	"?": &"question mark",
	"→": &"right arrow",
	"“": &"start parentheses",
	"↑": &"up arrow",
	"\"": &"start parentheses",
}:
	set(value):
		glyph_name_overrides = value
		update_text(text)


func get_suffix(character:String) -> StringName:
	if !sprite_frames:
		return &""
	
	if forced_anim_suffix != &"" and sprite_frames.has_animation(character + forced_anim_suffix):
		return forced_anim_suffix
	if sprite_frames.has_animation(character):
		return &""
	if character == character.to_upper() and sprite_frames.has_animation(character + &" capital"):
		return &" capital"
	if character == character.to_lower() and sprite_frames.has_animation(character + &" lowercase"):
		return &" lowercase"
	
	return &""


func get_glyph_name(character: String) -> StringName:
	var glyph_name: String = glyph_name_overrides.get(character, character)
	return glyph_name + get_suffix(glyph_name)

func get_glyph_texture(glyph: String) -> Texture2D:
	if sprite_frames and sprite_frames.has_animation(glyph):
		return sprite_frames.get_frame_texture(glyph, 0)
	
	return null

## Returns the size of the string's glyphs
func get_string_size(_text: String) -> Vector2:
	if _text.is_empty():
		return Vector2.ZERO
	
	var max_width: int = 0
	var max_height: float = 0
	var max_width_i: int = -1
	var lines = _text.split("\n")
	var height: float = lines.size() * line_gap_offset
	
	var i: int = 0
	for line in lines:
		if len(line) > max_width:
			max_width = len(line)
			max_width_i = i
		
		max_height = 0
		for c in line:
			var glyph_name: StringName = get_glyph_name(c)
			var glyph_texture: Texture2D = get_glyph_texture(glyph_name)
			var glyph_offset: Vector2 = glyph_offsets.get(glyph_name, Vector2(0.0, 0.0))
			
			if glyph_texture:
				var glyph_height: float = glyph_texture.get_height() - glyph_offset.y
				
				if glyph_height > max_height:
					max_height = glyph_height
		
		height += max_height
		if i < lines.size() - 1:
			height += default_bottom_padding
		
		i += 1
	
	var line: String = lines[max_width_i]
	var width: float = 0
	i = 0
	for c in line:
		var glyph_name: StringName = get_glyph_name(c)
		var glyph_texture: Texture2D = get_glyph_texture(glyph_name)
		var glyph_offset: Vector2 = glyph_offsets.get(glyph_name, Vector2(0.0, 0.0))
		
		if glyph_texture:
			width += glyph_texture.get_width() - glyph_offset.x
		
		if i < len(line) - 1:
			width += glyph_gaps.get(c, default_glyph_gap)
		
		i += 1
	
	return Vector2(width, height)


func update_text(new_text: String):
	for glyph in get_children():
		glyph.queue_free()
	
	if new_text.is_empty():
		return
	
	var lines = new_text.split("\n")
	
	var next_x: float
	var next_y: float
	
	match horizontal_alignment:
		_:
			next_x = 0
	
	match vertical_alignment:
		
		VerticalAlignment.VERTICAL_ALIGNMENT_CENTER:
			next_y = -get_string_size(new_text).y / 2
		
		VerticalAlignment.VERTICAL_ALIGNMENT_BOTTOM:
			next_y = -get_string_size(new_text).y
		
		_:
			next_y = 0
	
	next_y += get_string_size(lines[0]).y
	
	var j: int = 0
	for line in lines:
		match horizontal_alignment:
			HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER:
				next_x = -get_string_size(line).x / 2
			
			HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT:
				next_x = -get_string_size(line).x
		
		var characters = line.split()
		for i in characters.size():
			var character: String = characters[i]
			var glyph: AnimatedSprite2D = AnimatedSprite2D.new()
			glyph.sprite_frames = sprite_frames
			glyph.centered = false
			
			var glyph_name: StringName = get_glyph_name(character)
			if sprite_frames:
				if sprite_frames.has_animation(glyph_name):
					glyph.play(glyph_name)
					sprite_frames.set_animation_loop(glyph_name, true)
			
			glyph.offset = glyph_offsets.get(character, Vector2(0.0, 0.0))
			self.add_child(glyph)
			
			glyph.position.x = next_x
			
			next_x = glyph.position.x
			if i < len(line) - 1:
				next_x += glyph_gaps.get(character, default_glyph_gap)
			
			var glyph_texture: Texture2D = get_glyph_texture(glyph_name)
			
			if glyph_texture:
				next_x += glyph_texture.get_width()
				glyph.position.y -= glyph_texture.get_height()
				glyph.position.y += next_y
		
		var line_size: Vector2 = get_string_size(line)
		next_x -= line_size.x
		next_y += line_size.y
		
		if j < lines.size() - 1:
			next_y += default_bottom_padding
		
		j += 1
