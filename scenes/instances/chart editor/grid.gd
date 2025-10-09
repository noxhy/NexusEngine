extends Node2D

@export_group("Zoom")
@export var zoom = Vector2(1, 1)

@export_group("Grid Settings")
@export var grid_size = Vector2(16, 16)
@export var columns = 4
@export var rows = 16
@export var centered = true
@export var grid_color: Color = Color(0, 0)

@export_group("Colors")
@export var event_column_color = Color(1, 1, 1, 0.5)
@export var position_column_color = Color(1, 1, 1, 0.5)

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$TextureRect.size = Vector2(16, 16) * Vector2(columns, rows)
	$TextureRect.scale = grid_size / Vector2(16, 16)
	$TextureRect.scale *= zoom
	$TextureRect.self_modulate = grid_color
	
	if centered:
		$TextureRect.position.x = ($TextureRect.size.x * $TextureRect.scale.x) / -2.0
	else:
		$TextureRect.position = Vector2(0, 0)
	
	queue_redraw()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	$TextureRect.size = Vector2(16, 16) * Vector2(columns, rows)
	$TextureRect.scale = grid_size / Vector2(16, 16)
	$TextureRect.scale *= zoom
	$TextureRect.self_modulate = grid_color
	
	if centered:
		$TextureRect.position.x = ($TextureRect.size.x * $TextureRect.scale.x) / -2.0
	else:
		$TextureRect.position = Vector2(0, 0)
	
	queue_redraw()


func _draw():
	
	## Color's the events column (the first one)
	var rect = Rect2(get_real_position(Vector2(0, 0)), get_real_position(Vector2(columns, rows)) - get_real_position(Vector2(columns - 1, 0)))
	draw_rect(rect, event_column_color)
	
	## Color's the position column (the last one)
	rect = Rect2(get_real_position(Vector2(columns - 1, 0)), get_real_position(Vector2(1, rows)) - get_real_position(Vector2(0, 0)))
	draw_rect(rect, position_column_color)

## Returns the relative position of a grid position from the top left corner of a gridspace
func get_real_position(location: Vector2, snap: Vector2 = grid_size) -> Vector2:
	
	var output: Vector2 = Vector2(location) * snap * zoom
	output += $TextureRect.position
	return output

## Returns the grid position of a location
func get_grid_position(location: Vector2, snap: Vector2 = grid_size) -> Vector2:
	
	var output: Vector2 = location - $TextureRect.position
	output /= snap * zoom
	return output

## Returns the size of the grid
func get_size() -> Vector2:
	return $TextureRect.size * $TextureRect.scale
