@tool
@icon('animate_symbol.svg')
class_name AnimateSymbol extends Node2D
## Node that lets you play Adobe Animate Texture Atlases
## in Godot.


## The folder path to the atlas that is loaded.
## [br][br][b]Note[/b]: This automatically reloads the atlas when
## changed.
@export_dir var atlas: String:
	set(v):
		atlas = v
		load_atlas(atlas)


## The current frame of the animation.
## [br][br][b]Note[/b]: This automatically redraws the entire
## atlas when changed.
@export var frame: int = 0:
	set(v):
		frame = v
		queue_redraw()

## The current symbol used by the animation. Empty uses the timeline symbol.
## [br][br][b]Note[/b]: This automatically sets [member frame] to 0 when
## changed. (Resetting the current animation)
@export var symbol: String = '':
	set(v):
		symbol = v
		symbol_changed.emit(v)
		frame = 0
		_timer = 0.0

## Keeps track of whether or not the sprite is being animated automatically.
@export var playing: bool = false
@export_range(0.1, 2.0, 0.1) var play_speed: float = 1.0
## Automatically starts the animation when created during runtime.
@export var auto_start: bool = false

## Defines what happens when the end of the animation is reached.
## [br][br]Loop loops the animation forever and Play Once just stops.
@export_enum('Loop', 'Play Once') var loop_mode: String = 'Loop'
@export var loop_frame: int = 0

@export_tool_button('Cache Atlas', 'Save') var cache_atlas := _cache_atlas
@export_tool_button('Reload Atlas', 'Reload') var reload_atlas := _reload_atlas

var _timeline:
	get:
		if not is_instance_valid(_animation):
			return null
		return _animation.symbol_dictionary.get(symbol, _animation.timeline)

var _collections: Array[SpriteCollection]
var _animation: AtlasAnimation
var _timer: float = 0.0
var _current_transform: Transform2D = Transform2D.IDENTITY
var _canvas_items: Array[RID] = []
var _filters: Array[Filter] = []
var _filter_material: ShaderMaterial
var _active_materials = {}
var _color_transform: ColorTansform

signal finished
signal symbol_changed(symbol: String)


func _ready() -> void:
	if auto_start:
		playing = true
		frame = 0


func _process(delta: float) -> void:
	if not is_instance_valid(_animation):
		if frame > 0:
			frame = 0
		return
	
	if not playing:
		return
	
	_timer += delta * play_speed
	if _timer >= 1.0 / _animation.framerate:
		var frame_diff := _timer / (1.0 / _animation.framerate)
		frame += floori(frame_diff)
		_timer -= (1.0 / _animation.framerate) * frame_diff
		if frame > _timeline.length - 1:
			match loop_mode:
				'Loop':
					frame = loop_frame
				_:
					if playing:
						playing = false
						finished.emit()
					frame = _timeline.length - 1


func _cache_atlas() -> void:
	var parsed := ParsedAtlas.new()
	parsed.collections = _collections
	parsed.animation = _animation
	
	var atlas_directory := atlas
	if not atlas_directory.get_extension().is_empty():
		atlas_directory = atlas_directory.get_base_dir()
	
	var err := ResourceSaver.save(parsed, \
			'%s/Animation.res' % [atlas_directory], ResourceSaver.FLAG_COMPRESS)
	if err != OK:
		printerr(err)


func _reload_atlas() -> void:
	var atlas_directory := atlas
	if not atlas_directory.get_extension().is_empty():
		atlas_directory = atlas_directory.get_base_dir()
	load_atlas(atlas_directory, false)


## Loads a new atlas from the specified [param path].
func load_atlas(path: String, use_cache: bool = true) -> void:
	_collections.clear()
	_animation = null
	_active_materials = {}
	
	var atlas_directory := path
	if not atlas_directory.get_extension().is_empty():
		atlas_directory = atlas_directory.get_base_dir()
	
	var parsed_path := '%s/Animation.res' % atlas_directory
	if ResourceLoader.exists(parsed_path) and use_cache:
		var parsed: ParsedAtlas = load(parsed_path)
		_animation = parsed.animation
		_collections = parsed.collections
		_clear_items()
		frame = 0
		return
	
	var files := ResourceLoader.list_directory(atlas_directory)
	for file in files:
		if file.begins_with('spritemap') and file.ends_with('.json'):
			var spritemap_string := FileAccess.get_file_as_string('%s/%s' % [atlas_directory, file])
			var spritemap_json: Variant = JSON.parse_string(spritemap_string)
			if spritemap_json == null:
				printerr('Failed to parse %s' % file)
				return
			var sprite_collection := SpriteCollection.load_from_json(
				spritemap_json,
				load('%s/%s.png' % [atlas_directory, file.get_basename()])
			)
			_collections.push_back(sprite_collection)
	
	var animation_string := FileAccess.get_file_as_string('%s/Animation.json' % [atlas_directory])
	if animation_string.is_empty():
		return
	
	var animation_json: Variant = JSON.parse_string(animation_string)
	if animation_json == null:
		return
	_animation = AtlasAnimation.load_from_json(animation_json)
	frame = 0


func _draw_symbol(element: Element) -> void:
	if not _animation.symbol_dictionary.has(element.name):
		printerr('Tried to draw invalid symbol "%s"' % [element.name])
		return
	
	_filters = element.filters
	_color_transform = element.color_transform
	_draw_timeline(_animation.symbol_dictionary.get(element.name), element.frame)


func _draw_sprite(element: Element) -> void:
	for collection in _collections:
		if not collection.map.has(element.name):
			continue
		var use_item: bool = true
		var sprite: CollectedSprite = collection.map.get(element.name)
		var item: RID
		if use_item:
			item = RenderingServer.canvas_item_create()
			_canvas_items.push_back(item)
			RenderingServer.canvas_item_set_z_index(item, 
					mini(_canvas_items.size() - 1, RenderingServer.CANVAS_ITEM_Z_MAX))
			RenderingServer.canvas_item_set_parent(item, get_canvas_item())
			RenderingServer.canvas_item_set_transform(item, _current_transform)
			
			if not _filters.is_empty():
				var mat := ShaderMaterial.new()
				_active_materials[item] = mat
				RenderingServer.canvas_item_set_material(item, mat.get_rid())
				
				for filter in _filters:
					match filter.type:
						Filter.FilterType.BLUR:
							
							mat.set_shader(filter.shader)
							mat.set_shader_parameter("blur_x", filter.x)
							mat.set_shader_parameter("blur_y", filter.y)
							mat.set_shader_parameter("num_pass", filter.quality)
							# print("x: ", filter.x, " y: ", filter.y, " quality: ", filter.quality)
			
			if _color_transform != null:
				
				if _color_transform is TintTransform:
					var mat := ShaderMaterial.new()
					_active_materials[item] = mat
					RenderingServer.canvas_item_set_material(item, mat.get_rid())
					
					mat.set_shader(_color_transform.shader)
					mat.set_shader_parameter("tint_color", _color_transform.tint_color)
					mat.set_shader_parameter("intensity", _color_transform.opacity)
				
				elif _color_transform is AlphaTransform:
					RenderingServer.canvas_item_set_self_modulate(item, Color(1.0, 1.0, 1.0, _color_transform.multiplier))
				
				elif _color_transform is AdvancedTransform:
					var mat := ShaderMaterial.new()
					_active_materials[item] = mat
					RenderingServer.canvas_item_set_material(item, mat.get_rid())
					
					mat.set_shader(_color_transform.shader)
					mat.set_shader_parameter("mult_color", _color_transform.multiplier)
					mat.set_shader_parameter("add_color", _color_transform.offset)
			
		else:
			draw_set_transform_matrix(_current_transform)
		
		if is_instance_valid(sprite.custom_texture):
			if use_item:
				RenderingServer.canvas_item_add_texture_rect(
					item,
					Rect2(
						Vector2.ZERO,
						Vector2(sprite.rect.size.y, sprite.rect.size.x) \
								* (Vector2.ONE / collection.scale)
					),
					sprite.custom_texture
				)
			else:
				draw_texture_rect(
					sprite.custom_texture,
					Rect2(
						Vector2.ZERO,
						Vector2(sprite.rect.size.y, sprite.rect.size.x) \
								* (Vector2.ONE / collection.scale)
					),
					false
				)
		else:
			if use_item:
				RenderingServer.canvas_item_add_texture_rect_region(
					item,
					Rect2(Vector2.ZERO, Vector2(sprite.rect.size) * (Vector2.ONE / collection.scale)),
					collection.texture,
					Rect2(sprite.rect)
				)
			else:
				draw_texture_rect_region(
					collection.texture,
					Rect2(Vector2.ZERO, Vector2(sprite.rect.size) * (Vector2.ONE / collection.scale)),
					Rect2(sprite.rect),
				)
		return
	printerr('Tried to draw invalid sprite "%s"' % [element.name])


func _draw_timeline(timeline: Timeline, target_frame: int) -> void:
	var layer_transform := _current_transform
	for i in timeline.layers.size():
		var layer: Layer = timeline.layers[timeline.layers.size() - (i + 1)]
		for layer_frame in layer.frames:
			if target_frame < layer_frame.index:
				continue
			if target_frame > layer_frame.index + layer_frame.duration - 1:
				continue
			for element in layer_frame.elements:
				_current_transform = layer_transform
				_current_transform *= element.transform
				match element.type:
					Element.ElementType.SYMBOL:
						_draw_symbol(element)
					Element.ElementType.SPRITE:
						_draw_sprite(element)


func _clear_items() -> void:
	_active_materials = {}
	RenderingServer.canvas_item_clear(get_canvas_item())
	while not _canvas_items.is_empty():
		var item: RID = _canvas_items.pop_back()
		RenderingServer.free_rid(item)


func _exit_tree() -> void:
	_active_materials = {}
	_clear_items()


func _draw() -> void:
	_clear_items()
	
	if not is_instance_valid(_timeline):
		return
	_current_transform = Transform2D.IDENTITY
	_draw_timeline(_timeline, frame)
