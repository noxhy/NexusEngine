extends ColorRect
class_name EditorMinimap

const COLORS: Array[Color] = [Color(0.49, 0.078, 1.0), Color(0.086, 0.737, 0.749),
Color(0.235, 0.769, 0.208), Color(0.757, 0.149, 0.322)]

@export var precision: int = 1:
	set(v):
		precision = v
		point_size = size.x / ChartManager.strum_count
		refresh(data)

var chart_editor: ChartEditor
var data: Array[Vector2] = []
var point_size: float = 1

func _ready() -> void:
	chart_editor = get_parent().get_parent()


func refresh(_data: Array):
	data = []
	for packet in _data:
		map(packet)


func map(packet):
	data.append(Vector2(packet[1], packet[0]))


func unmap(packet):
	data.erase(Vector2(packet[1], packet[0]))


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for point in data:
		var y: float = point.y / chart_editor.instrumental.stream.get_length()
		y *= (size.y - precision)
		y = snappedf(y, precision)
		var rect: Rect2 = Rect2(Vector2(point_size * point.x, y), Vector2(point_size, precision))
		draw_rect(rect, COLORS[int(point.x) % 4])
