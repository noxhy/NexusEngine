extends Node2D

@export var option_name: String = "Menu Option"
@export var icon: Texture

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$Label.text = option_name
	if icon != null: $Sprite2D.texture = icon


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	$Label.text = option_name
	
	if icon != null:
		$Sprite2D.texture = icon
		$Sprite2D.position.x = $Label.size.x + $Sprite2D.texture.get_width() * 0.5 + 15
