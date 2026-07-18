@icon ("uid://obbw51pf8bd0")
extends Resource
class_name UISkin

@export_subgroup("Textures")
@export var rating_texture: SpriteFrames
@export var numbers_texture: SpriteFrames
@export var pixel_texture: bool = false

@export_subgroup("Texture Scaling")
@export var rating_scale: float = 1.0
@export var numbers_scale: float = 1.0
@export var numbers_spacing: float = 64

@export_subgroup("Offsets")
@export var animation_names: Dictionary[StringName, StringName] = {}
@export var offsets: Dictionary[StringName, Vector2] = {}

@export_subgroup("Scenes")
@export_file var countdown: String
@export_file var pause_scene: String = "uid://djhqiluiy02ao"
