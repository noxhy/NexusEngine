@icon ("uid://d0x87ek7hwhdm")
extends Resource
class_name NoteSkin

@export_subgroup("Textures")
@export var strums_texture: SpriteFrames
@export var notes_texture: SpriteFrames
@export var splashes_texture: SpriteFrames
@export var hold_covers_texture: SpriteFrames
@export var pixel_texture: bool = false

@export_subgroup("Texture Config")
@export_range(0, 1) var sustain_opacity: float = 0.6
@export var notes_scale: float = 1.0
@export var splash_scale: float = 1.0
@export var sustain_width: float = 0
@export var hold_covers_scale: float = 1.0

@export_subgroup("Offsets")
@export var animation_names: Dictionary[StringName, StringName] = {}
@export var offsets: Dictionary[StringName, Vector2] = {}

@export_subgroup("Audio")
@export var hit_sound: AudioStream
