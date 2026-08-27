@icon("uid://5rxblw3n5d5")
extends Resource
class_name Song
## The metadata for a Song. Contains all necessary files for a song to be loaded via playstate

@export_subgroup("Song Data")

## Path to the vocals of the song.
@export_file("*.ogg", "*.mp3", "*.wav") var vocals: Array[String] = []
## Path to the instrumental of the song
@export_file("*.ogg", "*.mp3", "*.wav") var instrumental: String
## Initial tempo of the song
@export var tempo: float = 60.0
## The path to the scene containing the playstate to play.
@export_file("*.tscn") var scene: String

## The charts for this song by difficulty.
@export var difficulties: Dictionary[String, SongDifficultyData]

## Optional filepath to a an Events Resource.
## These events will be loaded regardless of difficulty
@export_file('*.tres','*.res') var events: String

@export_subgroup("Display Stuff")

## The display name for the Song
@export var title: String
## The displayed artist for this Song
@export var artist: String
## The displayed charter for this Song
@export var charter: String
@export_file('*.res', '*.tres') var icons: String
@export var locked: bool = false

@export_subgroup("Story Mode Stuff")
@export var dont_display_until_played: bool = false
