extends Node

@onready var music:AudioStreamPlayer = $MusicPlayer
@onready var scroll:AudioStreamPlayer = $UI/ScrollPlayer
@onready var cancel:AudioStreamPlayer = $UI/CancelPlayer
@onready var accept:AudioStreamPlayer = $UI/AcceptPlayer
@onready var miss:AudioStreamPlayer = $Game/MissPlayer
@onready var hit: AudioStreamPlayer = $Game/HitPlayer
@onready var anti_spam: AudioStreamPlayer = $Game/AntiSpamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	
	AudioServer.set_bus_volume_linear(0, SettingsManager.get_setting("master_volume"))
	AudioServer.set_bus_volume_linear(1, SettingsManager.get_setting("music_volume"))
	AudioServer.set_bus_volume_linear(2, SettingsManager.get_setting("sfx_volume"))

func play_sound_once(path:Resource):
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = path
	player.play()
	player.bus = &'SFX'
	
	await player.finished
	
	player.queue_free()
