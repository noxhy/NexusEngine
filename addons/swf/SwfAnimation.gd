@tool
extends Node2D

class_name SwfAnimation

signal play_end

@export var animation_data: JSON:
	set(data):
		animation_data = data
		notify_property_list_changed()
		

@export var preview: bool

var current_movie_clip: MovieClip
var animations: Dictionary
var base_animations: Dictionary
var shape_transform: Dictionary
var shape_texture: Dictionary
var animation_name: String
var animation_names: Array = []
var frame_rate: float
# 所有子MC动画实例
var movie_clip_pool: Dictionary

# 保存生成的子节点
var node_cache: Dictionary
# 记录当前帧可视节点
var visiable_node: Array

const base_transform: Vector2 = Vector2(685.5, 255)

func _ready() -> void:
	if animation_data != null:
		parse()


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	if animation_data == null:
		return properties
	else:
		parse()

	if animation_names.size() > 0:
		#pass
		properties.append({
			"name": "swf_current_animation",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(animation_names),
		})

	return properties

var elapsed_time: float = 0
var current_frame: int = 0
var total_frames: int = 0
var internal_data: Dictionary = {}


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("swf_"):
		internal_data[property] = value
		if property == "swf_current_animation" && animation_names.size() > 0:
			current_movie_clip = MovieClip.new(animations[animation_names[value]].total_frames, animations[animation_names[value]]["timelines"])
		return true
	return false

func _get(property: StringName) -> Variant:
	if property.begins_with("                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    "):
		return internal_data.get_or_add(property, 0)
	return null

func _process(delta: float) -> void:
	# TODO: 动画播放
	if !preview:
		return
	if animations == null || current_movie_clip == null:
		return
	# 总帧数
	total_frames = current_movie_clip["total_frames"]
	## 按照帧率播放
	elapsed_time += delta
	if elapsed_time >= 1.0 / frame_rate:
		elapsed_time -= 1.0 / frame_rate
		current_frame += 1
		if current_frame >= total_frames:
			current_frame = 0
			play_end.emit()
		visiable_node.clear()
		run_frame(current_movie_clip, "Normal")
		for child in node_cache.values():
			# 全部隐藏
			if child is CanvasItem:
				child.visible = false
		var i = 0;
		for node_name in visiable_node:
			# 设置当前帧可视
			node_cache[node_name].visible = true
			# 设置z_index，重新排序
			node_cache[node_name].z_index = i
			i += 1


func run_frame(movie_clip: MovieClip, blend_mode: String, filters: Array = [], parent_transform: Transform3D = Transform3D.IDENTITY, parent_mult_color: Vector4 = Vector4(1, 1, 1, 1), parent_add_color: Vector4 = Vector4(0, 0, 0, 0)) -> void:
	match movie_clip._deterimine_current_frame():
		MovieClip.NextFrame.Next:
			movie_clip.current_frame += 1
		MovieClip.NextFrame.First:
			movie_clip.current_frame = 1
			for key in movie_clip.depth_frame:
				movie_clip.depth_frame[key].index = 0
				movie_clip.depth_frame[key].duration = 1

	for depth in movie_clip.timelines:
		var frames: Array = movie_clip.timelines[depth]
		var depth_frame = movie_clip.depth_frame[depth]
		# 表示该时间轴已经用完
		if depth_frame.index >= frames.size():
			continue
		var frame = frames[depth_frame.index]
		if frame.place_frame > movie_clip.current_frame || (frame.place_frame + depth_frame.duration) > movie_clip.current_frame:
			continue
		if depth_frame.duration < movie_clip.total_frames:
			depth_frame.duration += 1
		if depth_frame.duration > frame.duration:
			depth_frame.index += 1
			depth_frame.duration = 1

		var matrix = frame.transform.matrix
		var current_transform: Transform3D

		# 不应用根动画的位置
		if (current_movie_clip == movie_clip):
			current_transform = parent_transform * Transform3D(Vector3(matrix.a, matrix.b, 0), Vector3(matrix.c, matrix.d, 0), Vector3(0, 0, 1), Vector3(0, 0, 0))
		else:
			current_transform = parent_transform * Transform3D(Vector3(matrix.a, matrix.b, 0), Vector3(matrix.c, matrix.d, 0), Vector3(0, 0, 1), Vector3(matrix.tx, matrix.ty, 0))
		var color_transform = frame.transform.color_transform
		var mult_color = Vector4(color_transform.mult_color[0], color_transform.mult_color[1], color_transform.mult_color[2], color_transform.mult_color[3])
		var current_add_color = Vector4(color_transform.add_color[0], color_transform.add_color[1], color_transform.add_color[2], color_transform.add_color[3]) + mult_color * parent_add_color
		var current_mult_color = parent_mult_color * mult_color
		
		var child_clip = movie_clip_pool.get(str(frame.id))
		# 如果子动画存在，则递归调用
		if child_clip != null:
			run_frame(child_clip, frame.blend_mode, frame.filters, current_transform, current_mult_color, current_add_color)
		else:
			# 加载纹理资源
			var shader_material = ShaderMaterial.new()
			# 设置混合着色器
			shader_material.shader = get_blend_mode(blend_mode)
			# 用于抵消shape定义的偏移
			var shape_translate = shape_transform[str(frame.id)]
			# 设置动画变换
			shader_material.set_shader_parameter("world_matrix", current_transform.translated_local(Vector3(shape_translate[0], shape_translate[1], 0)))
			shader_material.set_shader_parameter("mult_color", current_mult_color)
			shader_material.set_shader_parameter("add_color", current_add_color)

			# 设置滤镜
			var filter_mode = 0; # 1:无滤镜 2:发光滤镜 4: 模糊滤镜 8：颜色滤镜
			# 跳过目前未处理标签（DefineMorphShape）
			var texture: Texture2D = shape_texture.get(str(frame.id))
			if texture == null:
				return

			
			var is_processed: bool = false
			
			# 为了性能是否考虑缓存滤镜渲染结果
			for filter: Dictionary in filters:
				var glow = filter.get("GlowFilter")
				if glow != null:
					# 发光滤镜
					filter_mode = 1 << 1
					
					var color = glow.color
					var blur_x = glow.blur_x
					var blur_y = glow.blur_y
					var strength = glow.strength
					var flags: int = glow.flags
					# 发光需要先模糊
					create_blur_filter(depth, frame.id, blur_x, blur_y, flags, texture, shader_material, current_transform, shape_translate, current_mult_color, current_add_color)
					var blur_flags = (flags & 0b11111) << 3
					
					shader_material.set_shader_parameter("glow_color", Color(color[0], color[1], color[2], color[3]))
					shader_material.set_shader_parameter("glow_strength", strength)
					shader_material.set_shader_parameter("glow_inner", 1 if flags & (1 << 7) != 0 else 0)
					shader_material.set_shader_parameter("glow_knockout", 1 if flags & (1 << 6) != 0 else 0)
					shader_material.set_shader_parameter("glow_composite_source", 1 if flags & (1 << 5) != 0 else 0)
					#shader_material.set_shader_parameter("blurred", temp_texture)
				# 模糊滤镜
				var blur_filter = filter.get("BlurFilter")
				if blur_filter != null:
					filter_mode = filter_mode + 1 << 2
					var blur_x = blur_filter.blur_x
					var blur_y = blur_filter.blur_y
					var num_pass = blur_filter.flags
					is_processed = true
					create_blur_filter(depth, frame.id, blur_x, blur_y, num_pass, texture, shader_material, current_transform, shape_translate, current_mult_color, current_add_color)
				
				# 颜色滤镜
				var color_matrix_filter = filter.get("ColorMatrixFilter")
				if color_matrix_filter != null:
					filter_mode = filter_mode + 1 << 3
					set_color_matrix(shader_material, color_matrix_filter.matrix)
					
					
			if !is_processed:
				visiable_node.append(str(depth) + "-" + str(frame.id))

				shader_material.set_shader_parameter("filter_mode", filter_mode)
				var res_sprite
				if node_cache.get(str(depth) + "-" + str(frame.id)) != null:
					res_sprite = node_cache.get(str(depth) + "-" + str(frame.id))
					res_sprite.material = shader_material
				else:
					res_sprite = Sprite2D.new()
					node_cache[str(depth) + "-" + str(frame.id)] = res_sprite
					res_sprite.texture = texture
					node_cache[str(depth) + "-" + str(frame.id)] = res_sprite
					add_child(res_sprite)
					res_sprite.material = shader_material
				

func get_blend_mode(blend_mode: String) -> Shader:
	if blend_mode == "Add":
		return preload("res://addons/swf/shaders/blend/add.gdshader")
	elif blend_mode == "Lighten":
		return preload("res://addons/swf/shaders/blend/lighten.gdshader")
	elif blend_mode == "Multiplay":
		return preload("res://addons/swf/shaders/blend/multiply.gdshader")
	elif blend_mode == "Darken":
		return preload("res://addons/swf/shaders/blend/darken.gdshader")
	elif blend_mode == "Overlay":
		return preload("res://addons/swf/shaders/blend/overlay.gdshader")
	elif blend_mode == "HardLight":
		return preload("res://addons/swf/shaders/blend/hardlight.gdshader")
	elif blend_mode == "Difference":
		return preload("res://addons/swf/shaders/blend/difference.gdshader")
	elif blend_mode == "Alpha":
		return preload("res://addons/swf/shaders/blend/alpha.gdshader")
	elif blend_mode == "Invert":
		return preload("res://addons/swf/shaders/blend/invert.gdshader")
	elif blend_mode == "Erase":
		return preload("res://addons/swf/shaders/blend/erase.gdshader")
	elif blend_mode == "Subtract":
		return preload("res://addons/swf/shaders/blend/subtract.gdshader")
	elif blend_mode == "Screen":
		return preload("res://addons/swf/shaders/blend/screen.gdshader")
	else:
		return preload("res://addons/swf/shaders/blend/normal.gdshader")

func create_blur_filter(depth: String, charact_id: int, blur_x: float, blur_y: float, num_pass: int, texture: Texture2D, shader_material: ShaderMaterial, current_transform: Transform3D, shape_translate: Array, current_mult_color: Vector4, current_add_color: Vector4):
	var blur_view: SubViewport
	if node_cache.get(depth + "-" + str(charact_id) + "subViewPost") != null:
		blur_view = node_cache.get(str(depth) + "-" + str(charact_id) + "subViewPost")
		blur_view.size = get_viewport().size
		var sprite: Sprite2D = blur_view.get_node("Sprite2D")
		var material: ShaderMaterial = sprite.material
		# 更新每一帧的变换
		material.set_shader_parameter("world_matrix", current_transform.translated_local(Vector3(shape_translate[0], shape_translate[1], 0)))
		material.set_shader_parameter("mult_color", current_mult_color)
		material.set_shader_parameter("add_color", current_add_color)
		sprite.transform = Transform2D(0, transform.get_origin())
		# 更新x轴模糊滤镜参数
		var color_rect_x: ColorRect = blur_view.get_node("CanvasLayerX/ColorRectX")
		var blur_x_material: ShaderMaterial = color_rect_x.material
		blur_x_material.set_shader_parameter("blur_x", blur_x)
		blur_x_material.set_shader_parameter("num_pass", num_pass)
		# 更新y轴模糊滤镜参数
		var color_rect_y: ColorRect = blur_view.get_node("CanvasLayerY/ColorRectY")
		var blur_y_material: ShaderMaterial = color_rect_y.material
		blur_y_material.set_shader_parameter("blur_y", blur_y)
		blur_y_material.set_shader_parameter("num_pass", num_pass)
	else:
		blur_view = SubViewport.new()
		# 设置其size与当前窗口大小一致
		blur_view.size = get_viewport().size
		blur_view.set_transparent_background(true)
		
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = texture
		sprite.transform = Transform2D(0, transform.get_origin())
		sprite.material = shader_material
		blur_view.add_child(sprite)
		
		# 创建x轴模糊滤镜
		create_blur_post_process(blur_view, preload("res://addons/swf/shaders/filter/blur_x.gdshader"), blur_x, num_pass, "blur_x", "CanvasLayerX", "ColorRectX")
		# 创建y轴模糊滤镜
		create_blur_post_process(blur_view, preload("res://addons/swf/shaders/filter/blur_y.gdshader"), blur_y, num_pass, "blur_y", "CanvasLayerY", "ColorRectY")
		
		node_cache[str(depth) + "-" + str(charact_id) + "subViewPost"] = blur_view
		add_child(blur_view)
		
	# 获取模糊后的纹理以显示
	var texture_rec: TextureRect
	visiable_node.append(str(depth) + "-" + str(charact_id) + "texture_rec")
	if node_cache.get(str(depth) + "-" + str(charact_id) + "texture_rec") != null:
		texture_rec = node_cache.get(str(depth) + "-" + str(charact_id) + "texture_rec")
	else:
		texture_rec = TextureRect.new()
		texture_rec.texture = blur_view.get_texture()
		var add_blend_material = CanvasItemMaterial.new()
		# TODO: 设置混合模式，目前只能设置为加法混合解决背景为黑色的问题
		add_blend_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		texture_rec.material = add_blend_material
		add_child(texture_rec)
		node_cache[str(depth) + "-" + str(charact_id) + "texture_rec"] = texture_rec

	#is_processed = true
	texture_rec.set_position(-transform.get_origin())

func create_blur_post_process(blur_view: SubViewport, blur_shader: Shader, blur: float, num_pass: int, direction: String, layer_name: String, color_rect_name: String) -> void:
	var color_rect = ColorRect.new()
	color_rect.name = color_rect_name
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var blur_material = ShaderMaterial.new()
	blur_material.shader = blur_shader
	blur_material.set_shader_parameter(direction, blur)
	blur_material.set_shader_parameter("num_pass", num_pass)
	color_rect.material = blur_material
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = layer_name
	canvas_layer.add_child(color_rect)
	blur_view.add_child(canvas_layer)

func set_color_matrix(shader_material: ShaderMaterial, matrix: Array):
	shader_material.set_shader_parameter("r_to_r", matrix[0])
	shader_material.set_shader_parameter("g_to_r", matrix[1])
	shader_material.set_shader_parameter("b_to_r", matrix[2])
	shader_material.set_shader_parameter("a_to_r", matrix[3])
	shader_material.set_shader_parameter("r_extra", matrix[4])
	shader_material.set_shader_parameter("r_to_g", matrix[5])
	shader_material.set_shader_parameter("g_to_g", matrix[6])
	shader_material.set_shader_parameter("b_to_g", matrix[7])
	shader_material.set_shader_parameter("a_to_g", matrix[8])
	shader_material.set_shader_parameter("g_extra", matrix[9])
	shader_material.set_shader_parameter("r_to_b", matrix[10])
	shader_material.set_shader_parameter("g_to_b", matrix[11])
	shader_material.set_shader_parameter("b_to_b", matrix[12])
	shader_material.set_shader_parameter("a_to_b", matrix[13])
	shader_material.set_shader_parameter("b_extra", matrix[14])
	shader_material.set_shader_parameter("r_to_a", matrix[15])
	shader_material.set_shader_parameter("g_to_a", matrix[16])
	shader_material.set_shader_parameter("b_to_a", matrix[17])
	shader_material.set_shader_parameter("a_to_a", matrix[18])
	shader_material.set_shader_parameter("a_extra", matrix[19])
	
	
func parse():
	animation_name = animation_data.data["name"]
	frame_rate = animation_data.data["frame_rate"]
	base_animations = animation_data.data["base_animations"]
	shape_transform = animation_data.data["shape_transform"]
	animations = animation_data.data["animations"]
	
	for id in shape_transform:
		var path = "res://%s.sprites/%s.tres" % [animation_name, str(id)]
		shape_texture[id] = load(path)
	animation_names = animation_data.data["animations"].keys()
	for child in base_animations:
		var movie_clip = MovieClip.new(base_animations[child].total_frames, base_animations[child].timelines)
		movie_clip_pool[child] = movie_clip


func set_animation(name: String):
	preview = true
	current_movie_clip = MovieClip.new(animations[name].total_frames, animations[name].timelines)
