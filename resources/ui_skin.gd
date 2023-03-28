@icon ( "res://assets/sprites/nodes/ui skin.png" )

extends Resource
class_name UISkin

@export_subgroup("Textures")

@export var rating_texture: SpriteFrames
@export var numbers_texture: SpriteFrames
@export var pixel_texture = false

@export_subgroup("Texture Scaling")

@export var rating_scale = 1.0
@export var numbers_scale = 1.0
@export var numbers_spacing = 64

@export_subgroup("Offsets")

@export var animation_names = {}
@export var offsets = {}

@export_subgroup("Scenes")

@export var countdown_animation = "developer_countdown"
@export var pause_scene = "res://scenes/playstate/pause_menu.tscn"
