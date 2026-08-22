extends TextureRect
class_name EditorMinimap

const COLORS: Array[Color] = [Color(0.49, 0.078, 1.0), Color(0.086, 0.737, 0.749),
Color(0.235, 0.769, 0.208), Color(0.757, 0.149, 0.322)]

@export var background_color: Color = Color(0.114, 0.133, 0.161)
@export var area_color: Color = Color(1.0, 1.0, 1.0, 0.4)
@export var precision: int = 2

var chart_editor: ChartEditor
var point_width: float:
	get():
		return size.x / ChartManager.strum_count

var minimap_image: Image
var point_data: Dictionary[int, Dictionary] = {}

var point_size: Vector2:
	get():
		return Vector2(point_width, precision)


func _ready() -> void:
	chart_editor = get_parent().get_parent()
	texture = ImageTexture.create_from_image(Image.create_empty(0, 0, false, Image.FORMAT_RGB8))


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if ChartManager.chart:
		for pixel in point_data:
			var packet: Dictionary = point_data[pixel]
			draw_rect_on_texture(packet.get("position"), point_size, packet.get("color"))
		
		
		var _range: float = chart_editor.conductor.numerator * chart_editor.conductor.denominator * chart_editor.conductor.seconds_per_step / chart_editor.grid.zoom.y
		var point_a: Vector2i = map_to_image_position(Vector2(0, chart_editor.song_position))
		var point_b: Vector2i = map_to_image_position(Vector2(0,
		chart_editor.song_position + _range))
		
		@warning_ignore("narrowing_conversion")
		var rect: Rect2 = Rect2(point_a, point_b - point_a + Vector2i(size.x, 0))
		draw_rect(rect, area_color)
		
		draw_rect_on_texture(map_to_image_position(Vector2(0,
		chart_editor.song_position + chart_editor.start_offset)), Vector2(size.x, precision), Color.RED)

## Creates an image texture of a map of the given data
func refresh(data: Array):
	minimap_image = Image.create_empty(int(size.x), int(size.y), false, Image.FORMAT_RGB8)
	point_data = {}
	draw_rect_on_image(Vector2i(0, 0), size, background_color)
	
	for packet in data:
		map_to_image(packet)
	
	update()


func update():
	texture.update(minimap_image)

## Draws the note color at a point on the image.
func map_to_image(packet):
	var pos: Vector2i = Vector2i(packet[1], packet[0])
	draw_rect_on_image(map_to_image_position(pos), point_size, COLORS[packet[1] % 4])

## Draws the background color at a point on the image.
func unmap_from_image(packet):
	var pos: Vector2i = Vector2i(packet[1], packet[0])
	draw_rect_on_image(map_to_image_position(pos), point_size, background_color)

## Returns the given point to its pixel number
func map_point_to_pixel(point: Vector2i) -> int:
	return point.x + point.y * minimap_image.get_height()

## Adds a point to draw over the image with the note color.
func map_to_texture(packet):
	var pos: Vector2i = Vector2i(packet[1], packet[0])
	var point: Vector2i = map_to_image_position(pos)
	point_data[map_point_to_pixel(pos)] = {
		"position": point,
		"color": COLORS[packet[1] % 4]
	}

## Adds a point to draw over the image with the background color.
func unmap_from_texture(packet):
	var pos: Vector2i = Vector2i(packet[1], packet[0])
	var point: Vector2i = map_to_image_position(pos)
	point_data[map_point_to_pixel(pos)] = {
		"position": point,
		"color": background_color
	}

## Maps a point to a position on the container
func map_to_image_position(point: Vector2) -> Vector2i:
	var y: float = point.y / chart_editor.instrumental.stream.get_length()
	y *= size.y
	y = snappedi(y, precision)
	return Vector2i(int(point_width * point.x), int(y))

## Draws a rectangle on the image
func draw_rect_on_image(pos: Vector2i, rect_size: Vector2i, color: Color):
	for y in rect_size.y:
		for x in rect_size.x:
			minimap_image.set_pixel(pos.x + x, pos.y + y, color)

## Draws a rectangle over the image
func draw_rect_on_texture(pos: Vector2i, rect_size: Vector2i, color: Color):
	var rect: Rect2 = Rect2(pos, rect_size)
	draw_rect(rect, color)
