@icon("uid://5rxblw3n5d5")
extends Resource
class_name Song

@export_subgroup("Song Data")

## Strong the vocal tracks on a path makes use less memory to load in runtime
@export_file("*.ogg", "*.mp3", "*.wav") var vocals: Array[String] = []
## Path to the instrumental of the song
@export_file("*.ogg", "*.mp3", "*.wav") var instrumental: String
## Initial tempo of the song
@export var tempo: float = 60.0
## The name that displays on the freeplay and pause menu
@export_file("*.tscn") var scene: String
## Each difficulty should have a filepath to a chart
## Set in each difficult a file path for the "chart" key.
## If you want to override the scene for a diffculty, add a key "scene" with a path to said scene.
@export var difficulties: Dictionary[String, Dictionary]

## Optional filepath to a an Events Resource.
## These events will be loaded regardless of difficulty
@export_file('*.tres','*.res') var events: String

@export_subgroup("Display Stuff")

@export var title: String
@export var artist: String
@export var charter: String
@export var icons: SpriteFrames
@export var locked: bool = false

@export_subgroup("Story Mode Stuff")
@export var dont_display_until_played: bool = false
