class_name PlayableCharacter

@export_category("Songs")
@export var album: Album
@export_category("Menus")
@export var pause_song: AudioStream
@export_category("Results")
@export var result_songs: Dictionary[String, AudioStream] = {"default": AudioStream.new()}
@export var normal_intro: AudioStream
@export var loss_intro: AudioStream
@export var result_nodes: Dictionary[String, String] = {"default": ""}
@export var dj: PackedScene
