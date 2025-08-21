extends CanvasLayer

@onready var strums = [ $"Player Strum", $"Enemy Strum" ]

@onready var player_icon = $"Health Bar/Icon Manager/Player"
@onready var enemy_icon = $"Health Bar/Icon Manager/Enemy"

@export var target_scale = Vector2(1, 1)
@export var lerp_weight = 0.1
@export var lerping = true

@export var target_health = 50.0

var accuracy: float = 0.0
var misses: int = 0
var rank: String = "?"
var score: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# Just in case anyone wants to display this information
	# $Performance.text = "Accuracy: " + str( snappedf( accuracy * 100, 0.01 ) ) + "%"
	# $Performance.text += " • " + "Rank: " + rank
	
	$"Health Bar/Performance".text = "Score: " + Global.format_number(score)
	$"Health Bar/Performance".text += " • " + "Misses: " + str(misses)
	
	
	update_health_bar( lerp( $"Health Bar".value, target_health, 0.115 ) )


func _physics_process(delta):
	
	scale = lerp( scale, target_scale, lerp_weight )


# Util


func set_player_icons(icons: SpriteFrames): player_icon.frames = icons
func set_enemy_icons(icons: SpriteFrames): enemy_icon.frames = icons

func set_player_color(color: Color): $"Health Bar".tint_progress = color
func set_enemy_color(color: Color): $"Health Bar".tint_under = color


# Visual Util


func icon_bop(time: float):
	
	Global.bop_tween( player_icon, "scale", Vector2(0.8, 0.8), Vector2(0.9, 0.9), time, Tween.TRANS_QUAD )
	Global.bop_tween( enemy_icon, "scale", Vector2(0.8, 0.8), Vector2(0.9, 0.9), time, Tween.TRANS_QUAD )


func update_health_bar( health: float ):
	
	$"Health Bar".value = health
	
	var display_x = ( $"Health Bar".value / $"Health Bar".max_value ) * $"Health Bar".size.x
	display_x = $"Health Bar".size.x - display_x
	
	$"Health Bar/Icon Manager".position = Vector2( display_x, 10 )
	
	var conditions = [
		[ health >= 85, "winning", "losing" ],
		[ health <= 15, "losing", "winning" ],
		[ true, "default", "default" ],
	]
	
	for condition in conditions:
		
		if condition[0]:
			
			if player_icon.sprite_frames.get_animation_names().has( condition[1] ):
				player_icon.animation = condition[1]
			
			if enemy_icon.sprite_frames.get_animation_names().has( condition[2] ):
				enemy_icon.animation = condition[2]
			break

func downscroll_ui():
	
	$"Player Strum".position.y *= -1
	$"Enemy Strum".position.y *= -1
	$"Health Bar".position.y *= -1


func streamer_ui():
	
	$"Health Bar".visible = false
	$"Health Bar/Performance".visible = false


func set_credits( song_name: String, artist_names: String ):
	
	$"Song Credits/ColorRect/Label".text = song_name
	$"Song Credits/ColorRect/Label".text += "\n-\n"
	$"Song Credits/ColorRect/Label".text += artist_names


func show_credits(): $AnimationPlayer.play("credits_show")
func hide_credits(): $AnimationPlayer.play("credits_hide")
