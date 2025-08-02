extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

var index: int
var rank: Variant = null
var total: float = 0.0

@export var icon: Texture2D:
	set(v):
		
		icon = v
		$Icon.texture = v


@export var state: String:
	set(v):
		
		state = v
		$Capsule.play_animation(state)
		
		if v == "idle":
			
			%Label.label_settings.font_color = Color(0.404, 0.471, 0.506)
			%Label.label_settings.outline_color = Color(0.259, 0.361, 0.4)
		elif v == "selected":
			
			%Label.label_settings.font_color = Color(1, 1, 1)
			%Label.label_settings.outline_color = Color(0.039, 0.471, 0.576)


@export var text: String:
	set(v):
		
		text = v
		%Label.text = v


func _process(delta: float) -> void:
	
	var scroll_bar: HScrollBar = %Scroll.get_h_scroll_bar()
	var diff = %Label.size.x - %Scroll.size.x
	var half_diff = diff / 2
	
	if diff > 0:
		
		scroll_bar.value = cos(total) * -half_diff + half_diff
		total += delta * 1.5
	
	var texture: Texture2D
	if rank != null:
		
		texture = animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation, animated_sprite.frame
		)
		$HBoxContainer/TextureRect.texture = texture
		$HBoxContainer/TextureRect.visible = true
	else:
		$HBoxContainer/TextureRect.visible = false


func display_rank(_rank: Variant):
	
	if _rank == "?":
		_rank = null
	
	if _rank != null:
		animated_sprite.play_animation(_rank)
	
	rank = _rank
