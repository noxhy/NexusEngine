extends Node2D

@export var wait_time: float = 1.0

var scroll_timer: float = 0.0
var wait_timer: float = 0.0
var positive: bool = true
var index: int

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
	
	var scroll_bar: HScrollBar = $Container.get_h_scroll_bar()
	if scroll_bar.max_value > 0:
		
		if wait_timer <= 0:
			
			var condition: bool = false
			if positive:
				
				scroll_bar.value = int(scroll_timer)
				var diff = %Label.size.x - $Container.size.x
				condition = (scroll_bar.value >= diff)
			else:
				scroll_bar.value = int(scroll_bar.max_value - scroll_timer)
				condition = (scroll_bar.value == 0)
			
			scroll_timer += delta * 50
			if condition:
				
				wait_timer = wait_time
				positive = !positive
				scroll_timer = 0.0
		else:
			wait_timer -= delta
