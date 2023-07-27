@icon( "res://assets/sprites/nodes/album.png" )

extends Resource
class_name Album

@export_subgroup("Album Stats")

@export var name: String
@export var cover: Texture2D
@export_multiline var credits

@export_subgroup("Song List")

@export var song_list: Array[Song]
