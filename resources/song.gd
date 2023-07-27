@icon( "res://assets/sprites/nodes/song.png" )

extends Resource
class_name Song


@export_subgroup("Song Data")

@export var chart: Chart
@export var scene: String

@export_subgroup("Display Stuff")

@export var icons: SpriteFrames = preload( "res://assets/sprites/playstate/icons/face.tres" )
@export var display_color: Color = Color(1, 1, 1)
@export var locked: bool = false
