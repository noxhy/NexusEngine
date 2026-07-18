extends Node2D
class_name Grid

@export_group("Zoom")
@export var zoom: Vector2 = Vector2(1, 1):
	set(v):
		zoom = v
		draw()
	get():
		return zoom

@export_group("Grid Settings")
@export var event_grid: bool = false
@export var grid_size: Vector2 = Vector2(16, 16):
	set(v):
		grid_size = v
		draw()
	get():
		return grid_size

@export var columns: int = 4:
	set(v):
		columns = v
		draw()
	get():
		return columns

@export var rows: int = 16:
	set(v):
		rows = v
		draw()
	get():
		return rows

@export var centered: bool = true:
	set(v):
		centered = v
		draw()
	get():
		return centered
@export var grid_color: Color = Color(0, 0):
	set(v):
		grid_color = v
		draw()
	get():
		return grid_color

@export_group("Colors")
@export var event_column_color: Color = Color(1, 1, 1, 0.5)
@export var position_column_color: Color = Color(1, 1, 1, 0.5)

@onready var texture_rect: TextureRect = $TextureRect

# Called when the node enters the scene tree for the first time.
func draw():
	if texture_rect:
		texture_rect.size = Vector2(16, 16) * Vector2(columns, rows)
		texture_rect.scale = grid_size / Vector2(16, 16)
		texture_rect.scale *= zoom
		texture_rect.self_modulate = grid_color
		
		if centered:
			if !event_grid:
				texture_rect.position.x = (texture_rect.size.x * texture_rect.scale.x) / -2.0
			else:
				texture_rect.position.y = (texture_rect.size.y * texture_rect.scale.y) / -2.0
		else:
			texture_rect.position = Vector2.ZERO


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	queue_redraw()


func _draw():
	if !event_grid:
		## Color's the events column (the last one)
		var rect = Rect2(get_real_position(Vector2(0, 0)), get_real_position(Vector2(columns, rows)) - get_real_position(Vector2(columns - 1, 0)))
		draw_rect(rect, event_column_color)
		
		## Color's the position column (the first one)
		rect = Rect2(get_real_position(Vector2(columns - 1, 0)), get_real_position(Vector2(1, rows)) - get_real_position(Vector2(0, 0)))
		draw_rect(rect, position_column_color)
	else:
		## Color's the position column (the first one)
		var rect = Rect2(get_real_position(Vector2(0, 0)), get_real_position(Vector2(columns, 1)) - get_real_position(Vector2(0, 0)))
		draw_rect(rect, position_column_color)

## Returns the relative position of a grid position from the top left corner of a gridspace
func get_real_position(location: Vector2, snap: Vector2 = grid_size) -> Vector2:
	var output: Vector2 = Vector2(location) * snap * zoom
	output += texture_rect.position
	return output

## Returns the grid position of a location
func get_grid_position(location: Vector2, snap: Vector2 = grid_size) -> Vector2:
	var output: Vector2 = location - texture_rect.position
	output /= snap * zoom
	return output

## Returns the size of the grid
func get_size() -> Vector2:
	return texture_rect.size * texture_rect.scale
