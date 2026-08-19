extends Node2D
class_name ChartEvent

@onready var area = $Area2D
@onready var collision_shape = $Area2D/CollisionShape2D
@onready var sprite: TextureRect = $Sprite2D

var time: float
var event: String
var parameters: Array
var grid_size: Vector2 = Vector2(128, 128)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Constants.EVENT_DATA.has(event):
		if Constants.EVENT_DATA[event].has("texture"):
			sprite.texture = load(Constants.EVENT_DATA[event]["texture"])
	
	update()

func update():
	if sprite:
		sprite.size = grid_size
		sprite.position = -sprite.size / 2
	
	if collision_shape:
		collision_shape.shape = RectangleShape2D.new()
		$VisibleOnScreenEnabler2D.scale = grid_size / $VisibleOnScreenEnabler2D.rect.size
		collision_shape.scale = $VisibleOnScreenEnabler2D.scale * 0.9
		collision_shape.shape.set_size($VisibleOnScreenEnabler2D.rect.size)


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	$Sprite2D.visible = true


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	$Sprite2D.visible = false
