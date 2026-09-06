@icon("res://addons/at-icons/node/file_note_double.svg")

extends Resource
class_name Album

@export_subgroup("Album Stats")

@export var name: String
@export var cover: Texture
@export_multiline var credits: String

@export_subgroup("Song List")

@export var song_list: Array[Song]
