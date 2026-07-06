extends Node

const MODS_DIR: String = "mods"

enum ModError {
	OUTDATED_ENGINE,
	OUTDATED_MOD
}

var mods: PackedStringArray
var mod_data: Dictionary = {}

func _ready() -> void:
	find_mods()
	if OS.is_debug_build() and ModManager.mod_data.size() == 1:
		run_mod(mods[0])

## Locates the folders with a .zip and metadata.json and adds them to the cached mods list.
func find_mods() -> void:
	var mods_dir: String
	
	if OS.is_debug_build():
		mods_dir = "res://"
		if !DirAccess.open(mods_dir):
			push_error("(ModManager) No mods folder found at %s" % mods_dir)
			return
	else:
		mods_dir = OS.get_executable_path().get_base_dir().path_join(MODS_DIR)
		if !DirAccess.dir_exists_absolute(MODS_DIR):
			push_error("(ModManager) No mods folder found at %s" % mods_dir)
			return
	
	print("(ModManager) Opening mods folder at: ", mods_dir)
	for mod_dir_name in DirAccess.get_directories_at(mods_dir):
		var mod_dir: String = mods_dir.path_join(mod_dir_name)
		
		for file in DirAccess.get_files_at(mod_dir):
			if ["zip", "pck"].has(file.get_extension()):
				var meta_path: String = mod_dir.path_join("meta.json")
				print("(ModManager) Looking for meta at %s" % meta_path)
				if FileAccess.file_exists(meta_path):
					var data = JSON.parse_string(FileAccess.open(meta_path, FileAccess.READ).get_as_text())
					mod_data[mod_dir] = data
					mods.append(mod_dir)
					print("(ModManager) Found metadata for: ", data.get("name"))
				break

## Reads a mod directly from the mod cache and runs the init script.
func run_mod(mod_dir: String, debug: bool = false):
	var init_path: String = mod_dir
	
	if OS.is_debug_build():
		init_path = init_path.path_join("init.gd")
	else:
		var mod_path: String
		for file in DirAccess.get_files_at(mod_dir):
			if ["zip", "pck"].has(file.get_extension()):
				mod_path = mod_dir.path_join(file)
				init_path = "res://".path_join(mod_path.get_file().get_basename())
			
			break
		
		var rsp = ProjectSettings.load_resource_pack(mod_path, true)
		if rsp:
			print("(ModManager) Loading mod: ", mod_data[mod_dir].get("name", "No name found."))
			init_path = init_path.path_join("init.gd")
	
	if ResourceLoader.exists(init_path):
		print("(ModManager) Running init at: ", init_path)
		var init_res = load(init_path)
		if init_res:
			# You have to keep the script alive for it to keep changes to ProjectSettings.
			@warning_ignore("unused_variable")
			var init_instance = init_res.new()
	
	print("(ModManager) Running Mod: %s" % mod_data[mod_dir].get("name", "No name found."))
