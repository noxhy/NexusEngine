extends Node

var players: Dictionary[StringName, AudioStreamPlayer] = {}

@onready var music: AudioStreamPlayer = $MusicPlayer ## global music player
@onready var scroll: AudioStreamPlayer = $UI/ScrollPlayer ## global menu scroll sfx
@onready var cancel: AudioStreamPlayer = $UI/CancelPlayer ## global menu cancel sfx
@onready var accept: AudioStreamPlayer = $UI/AcceptPlayer ## global menu accept sfx

@onready var miss: AudioStreamPlayer = $Game/MissPlayer ## note miss sfx
@onready var hit: AudioStreamPlayer = $Game/HitPlayer ## note hit sfx
@onready var anti_spam: AudioStreamPlayer = $Game/AntiSpamPlayer ## anti spam sfx

@onready var conductor_beat: AudioStreamPlayer = %"Conductor Beat"
@onready var conductor_off_beat: AudioStreamPlayer = %"Conductor Off Beat"
@onready var conductor_step: AudioStreamPlayer = %"Conductor Step"
@onready var tool_hit: AudioStreamPlayer = %"Hit Sound"
@onready var tool_note_place: AudioStreamPlayer = %"Note Place"
@onready var tool_mouse_click: AudioStreamPlayer = %"Mouse Click"
@onready var tool_note_remove: AudioStreamPlayer = %"Note Remove"
@onready var tool_note_stretch: AudioStreamPlayer = %"Note Stretch"
@onready var tool_open_window: AudioStreamPlayer = %"Open Window"
@onready var tool_close_window: AudioStreamPlayer = %"Close Window"
@onready var tool_undo: AudioStreamPlayer = %Undo
@onready var tool_redo: AudioStreamPlayer = %Redo

func _ready() -> void:
	AudioServer.set_bus_mute(0, SettingsManager.get_value(SettingsManager.SEC_AUDIO, 'is_muted', false))
	AudioServer.set_bus_volume_linear(0, SettingsManager.get_value('audio', "master_volume", 1.0))
	AudioServer.set_bus_volume_linear(1, SettingsManager.get_value('audio', "music_volume", 1.0))
	AudioServer.set_bus_volume_linear(2, SettingsManager.get_value('audio', "sfx_volume", 1.0))

func _process(delta: float) -> void:
	AudioServer.set_bus_volume_linear(0, SettingsManager.get_value('audio', "master_volume", 1.0))
	AudioServer.set_bus_volume_linear(1, SettingsManager.get_value('audio', "music_volume", 1.0))
	AudioServer.set_bus_volume_linear(2, SettingsManager.get_value('audio', "sfx_volume", 1.0))

func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if event.is_echo():
		return
	if event is not InputEventKey:
		return
	#if Global.lock_keybinds:
		#return
	var ev:InputEventKey = event
	
	if event.shift_pressed or event.ctrl_pressed or event.alt_pressed:
		return
	
	if ev.pressed:
		if ev.is_action(&'mute'):
			SettingsManager.set_value(SettingsManager.SEC_AUDIO, 'is_muted', !SettingsManager.get_value(SettingsManager.SEC_AUDIO, 'is_muted', false))
			
			_updated_volume()
		elif ev.is_action(&'volume_up'):
			SettingsManager.set_value(SettingsManager.SEC_AUDIO, 'is_muted', false)
			
			var new_vol = clampf(SettingsManager.get_value(SettingsManager.SEC_AUDIO,'master_volume') + 0.05, 0.0, 1.0)
			SettingsManager.set_value(SettingsManager.SEC_AUDIO, 'master_volume', new_vol)
			
			_updated_volume()
		elif ev.is_action(&'volume_down'):
			SettingsManager.set_value(SettingsManager.SEC_AUDIO, 'is_muted', false)
			
			var new_vol = clampf(SettingsManager.get_value(SettingsManager.SEC_AUDIO,'master_volume') - 0.05, 0.0, 1.0)
			SettingsManager.set_value(SettingsManager.SEC_AUDIO, 'master_volume', new_vol)
			
			_updated_volume()

func _updated_volume():
	AudioServer.set_bus_mute(0, SettingsManager.get_value(SettingsManager.SEC_AUDIO, 'is_muted', false))
	AudioServer.set_bus_volume_linear(0, SettingsManager.get_value('audio', "master_volume", 1.0))
	
	SettingsManager.flush()
	if Global.volume_display:
		Global.volume_display.show_volume()


## plays the global audio track from stream or path
func play_music(stream: Variant, start_time: float = 0) -> void:
	stream = get_stream(stream)
	music.stream = stream
	
	music.play(start_time)

## Plays a audio once and frees it after its use
func play_sound_once(stream: Variant, volume_linear: float = 1) -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = get_stream(stream)
	player.volume_linear = volume_linear
	player.play()
	player.bus = &'SFX'
	
	await player.finished
	
	remove_child(player)
	player.queue_free()

## attempts to retrieve a stream more thoroughly and asserts when failure.
## [br][br]If the given file is a [code]String[/code], the func will attempt to load it (supports absolute paths)
func get_stream(stream: Variant) -> AudioStream:
	if stream is AudioStream or stream is AudioStreamOggVorbis:
		return stream
	elif stream is String:
		if not stream.begins_with('res://') and not stream.begins_with("uid://"):
			var file: FileAccess = FileAccess.open(stream, FileAccess.READ)
			if file:
				var raw_buffer = file.get_buffer(file.get_length())
				
				var potential_stream = get_stream_from_buffer(raw_buffer, stream.get_extension())
				
				file.close()
				
				if potential_stream:
					return potential_stream
		
		if not ResourceLoader.exists(stream):
			printerr("(Snd Manager): Could not find stream at %s." % stream)
			return null
		
		var loaded_sound = load(stream)
		
		if (loaded_sound is not AudioStream and stream is not AudioStreamOggVorbis):
			printerr("(Snd Manager): %s was not a valid audio stream." % stream)
			return null
		
		return loaded_sound
	else:
		printerr("(Snd Manager): %s was not a valid audio stream." % stream)
		return null

func get_stream_from_buffer(buffer: PackedByteArray, ext: String) -> AudioStream:
		match ext:
			'ogg':
				return AudioStreamOggVorbis.load_from_buffer(buffer)
			'wav':
				return AudioStreamWAV.load_from_buffer(buffer)
			'mp3':
				return AudioStreamMP3.load_from_buffer(buffer)
		return null

## Creates a new [AudioStreamPlayer] that will always exist in memory.
func create_player(id: StringName, sound: Variant) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = &'SFX'
	player.stream = get_stream(sound)
	add_child(player)
	players[id] = player
	return player

## Returns an [AudioStreamPlayer] from the user-generated players dictionary.
func get_player(id: StringName) -> AudioStreamPlayer:
	return players.get(id, null)
