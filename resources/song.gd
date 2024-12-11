@icon( "res://assets/sprites/nodes/song.png" )

extends Resource
class_name Song


@export_subgroup("Song Data")

## Strong the vocal tracks on a filepath makes use less memory to load in runtime
@export var vocals: Array[AudioStream] = []
## File path to the instrumental of the song
@export var instrumental: AudioStream
## Initial tempo of the song
@export var tempo: float = 60.0
## The name that displays on the freeplay and pause menu
@export var scene: String
## Each difficulty should have a filepath to a chart
## If you want to override the scene for a diffculty, add a key "scene" with a filepath to said scene.
@export var difficulties: Dictionary

@export_subgroup("Display Stuff")

@export var title: String
@export var artist: String
@export var icons: SpriteFrames = preload( "res://assets/sprites/playstate/icons/face.tres" )
@export var display_color: Color = Color(1, 1, 1)
@export var locked: bool = false
