extends Node2D

@export var texture: Texture2D:
	set(v):
		texture = v
		$Sprite.texture = v
