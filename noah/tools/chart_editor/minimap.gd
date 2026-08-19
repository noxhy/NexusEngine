extends ColorRect
class_name EditorMinimap

@export var precision: int = 1

var data: Array[Vector2]

var min: float = 0
var max: float = 100

func refresh(_data: Array):
	for packet in _data:
		map(packet)

func map(packet):
	pass

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	for point in data:
		var rect: Rect2 = Rect2()
		draw_rect(rect, Color.WHITE)
