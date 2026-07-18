@icon("uid://b1yfbu2p6scl0")
extends Resource
class_name Week

@export var week_name: String
@export var week_animation: String

## to do: make a better system for this, not likin it, doesnt adapt to name changes, etc
@export var node_path: String

@export_subgroup("Song List")
@export var song_list: Array[Song]
