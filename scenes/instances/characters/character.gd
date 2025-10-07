@icon("res://assets/sprites/nodes/character.png")

extends Node2D
class_name Character

@export_group("Animation Offset")
@export var idle_animation = "idle"
@export var animation_names: Dictionary[String, String] = {}
@export var offsets: Dictionary[String, Vector2] = {}

@export_group("Playstate")
@export var icons: SpriteFrames = preload("res://assets/sprites/playstate/icons/face.tres")
@export var color: Color = Color(0.168627, 0.121569, 0.203922)

var current_animation: String = idle_animation
var can_idle: bool = true

func _ready():
	$AnimatedSprite2D.play()

func play_animation(animation_name: String = "", time: float = -1.0):
	
	# Will not run idle animation if you can not run
	
	if animation_names.has(animation_name):
		
		if animation_name == idle_animation:
			
			if !can_idle:
				return
		
		var real_animation_name: String = animation_names.get(animation_name)
		can_idle = false
		
		if (time >= 0):
			
			# Calculates the speed it would need to go at the time requested
			
			var animatiom_speed: float = $AnimatedSprite2D.sprite_frames.get_animation_speed(real_animation_name)
			var frame_count: int = $AnimatedSprite2D.sprite_frames.get_frame_count(real_animation_name) 
			
			current_animation = animation_name
			$AnimatedSprite2D.play(real_animation_name, frame_count / (animatiom_speed * time))
			
		else:
			
			current_animation = animation_name
			$AnimatedSprite2D.play(real_animation_name, 1)
		
		$AnimatedSprite2D.frame = 0
		
		if offsets.has(real_animation_name):
			
			if offsets.get($AnimatedSprite2D.animation) is PackedVector2Array: $AnimatedSprite2D.position = offsets.get($AnimatedSprite2D.animation)[ $AnimatedSprite2D.frame - 1 ]
			else: $AnimatedSprite2D.position = offsets.get(real_animation_name)
	else:
		
		$AnimatedSprite2D.frame = 0
		print("Animation ", animation_name , " not found")


func get_real_animation(animation_name: String = ""):
	
	if animation_names.has(animation_name):
		
		var real_animation_name: String = animation_names.get(animation_name)
		return real_animation_name
	else: return null


func _on_animated_sprite_2d_animation_finished(): can_idle = true


func _on_animated_sprite_2d_frame_changed():
	
	var duration = $AnimatedSprite2D.sprite_frames.get_frame_duration($AnimatedSprite2D.animation, $AnimatedSprite2D.frame)
	$AnimatedSprite2D.rotation_degrees = 0 if duration == 1 else -90
	
	if offsets.get($AnimatedSprite2D.animation) is PackedVector2Array:
		
		$AnimatedSprite2D.position = offsets.get($AnimatedSprite2D.animation)[ $AnimatedSprite2D.frame ]
		print("Frame: ", $AnimatedSprite2D.frame, " Offset: ", offsets.get($AnimatedSprite2D.animation)[ $AnimatedSprite2D.frame ])
