extends Node
class_name ZipTools


## path used to create dummy files for resource serialization
static var TEMP_RESOURCE: String = 'user://temp-resource.res'
static var TEMP_TEXT_RESOURCE: String = 'user://temp-resource.tres'

static func read_text_resource_from_zip(zip: ZIPReader, file_name: String):
	var buffer: PackedByteArray = zip.read_file(file_name)
	
	var file = FileAccess.open(TEMP_TEXT_RESOURCE, FileAccess.WRITE)
	file.store_string(buffer.get_string_from_utf8())
	file.close()
	
	var res = load(TEMP_TEXT_RESOURCE)

	DirAccess.remove_absolute(TEMP_TEXT_RESOURCE)
	
	return res

static func read_resource_from_zip(zip: ZIPReader, file_name: String):
	var buffer = zip.read_file(file_name)
	
	var file = FileAccess.open(TEMP_RESOURCE, FileAccess.WRITE)
	file.store_buffer(buffer)
	file.close()
	
	var res = load(TEMP_RESOURCE)
	
	DirAccess.remove_absolute(TEMP_RESOURCE)
	
	return res

static func read_dict_from_zip(zip: ZIPReader, file_name: String) -> Dictionary:
	var buffer = zip.read_file(file_name).get_string_from_utf8()
	
	return JSON.parse_string(buffer)

static func write_dict_to_zip(zip: ZIPPacker, file_name: String, dict:Dictionary):
	
	var stringify = JSON.stringify(dict)
	
	zip.start_file(file_name)
	zip.write_file(stringify.to_utf8_buffer())
	zip.close_file()
	
	print('Successfully written to zip')

static func write_snd_to_zip(zip: ZIPPacker, file_name: String, snd_path: String):
	
	if snd_path.begins_with('uid'):
		snd_path = ResourceUID.uid_to_path(snd_path)
	
	var file:FileAccess = FileAccess.open(snd_path, FileAccess.READ)
	if not file:
		printerr("failed to open file for path: ", snd_path)
		return 
	
	zip.start_file(file_name)
	zip.write_file(file.get_buffer(file.get_length()))
	zip.close_file()
	
	file.close()
	
	print('Successfully written to zip')


static func write_resource_to_zip(zip: ZIPPacker, file_name: String, resource: Resource):
	if file_name.get_extension().is_empty():
		file_name = file_name + '.res'

	ResourceSaver.save(resource, TEMP_RESOURCE)
	
	zip.start_file(file_name)
	zip.write_file(FileAccess.get_file_as_bytes(TEMP_RESOURCE))
	zip.close_file()
	
	DirAccess.remove_absolute(TEMP_RESOURCE)
	
	print('Successfully written to zip')
