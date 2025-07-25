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
## Set in each difficult a file path for the "chart" key.
## If you want to override the scene for a diffculty, add a key "scene" with a filepath to said scene.
@export var difficulties: Dictionary[String, Dictionary]

@export_subgroup("Display Stuff")

@export var title: String
@export var artist: String
@export var icons: SpriteFrames = preload("res://assets/sprites/playstate/icons/face.tres")
@export var locked: bool = false
