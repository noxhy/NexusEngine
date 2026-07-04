class_name WaveformDataParser


static func interpretSound(soundPath:String) -> WaveformData:
	if soundPath == null: 
		push_error("sound path is null?,... consider putting one in??")
		return null
	
	if not FileAccess.file_exists(soundPath):
		push_error("sound path %s doesnt exist!" % soundPath)
		return null
	
	var sound:AudioStream = SoundManager.get_stream(soundPath)
	if sound is AudioStreamOggVorbis:
		var soundBuffer = AudioStreamEXT.DecodeOggMem(soundPath)
		
		if not soundBuffer.is_empty():
			return interpretPackets(soundBuffer)
			
		
		push_error("critical error occured opening ogg :/ %s " % soundPath)
		return null
	push_error("Stream unsupported, try using ogg if you arent!! %s " % soundPath)
	return null

#im fucking geeked man !!! 
#straight tweakinnnnggggg
static func interpretPackets(soundBuffer) -> WaveformData:
	var samplesPerPoint = 256
	var result = WaveformData.new()
	result.create(2, soundBuffer.channels, soundBuffer.sample_rate, samplesPerPoint, soundBuffer.bitsPerSample, soundBuffer.pcm_data.size(), soundBuffer.pcm_data)
	result.songLength = soundBuffer.OGG_DURATION
	return result
