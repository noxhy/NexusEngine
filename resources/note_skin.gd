@icon ( "res://assets/sprites/nodes/note skin.png" )

extends Resource
class_name NoteSkin

@export_subgroup("Textures")

@export var strums_texture: SpriteFrames
@export var notes_texture: SpriteFrames
@export var splashes_texture: SpriteFrames
@export var hold_covers_texture: SpriteFrames
@export var pixel_texture = false

@export_subgroup("Texture Scaling")

@export var notes_scale = 1.0
@export var sustain_width = 0

@export_subgroup("Offsets")
@export var animation_names = {}
@export var offsets = {}

@export_subgroup("Audio")
@export var hit_sound: AudioStream
