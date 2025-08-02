class_name PlayableCharacter

@export_category("Songs")
@export var album: Album
@export_category("Menus")
@export_category("Pause")
@export var pause_song: AudioStream
@export_subgroup("Freeplay")
@export var dj: PackedScene
@export var background: Texture2D
@export_category("Results")
@export var result_songs: Dictionary[String, AudioStream] = {"default": AudioStream.new()}
@export var normal_intro: AudioStream
@export var loss_intro: AudioStream
@export var result_nodes: Dictionary[String, String] = {"default": ""}
