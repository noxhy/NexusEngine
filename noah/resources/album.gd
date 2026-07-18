@icon("uid://bggbycx6telfb")
extends Resource
class_name Album

@export_subgroup("Album Stats")

@export var name: String
@export var cover: Texture
@export_multiline var credits: String

@export_subgroup("Song List")

@export var song_list: Array[Song]
