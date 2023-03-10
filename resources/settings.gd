extends Resource
class_name Settings

@export var version = 1

@export_group( "Gameplay" )

@export var offset = 0.0 # Puts a delay on the notes
@export var ghost_tapping = true # Allows tapping when no notes are active
@export var downscroll = false # Notes go down instead of up, downscroll ui function is called

@export_group( "Preference" )

@export var combo_ui = false # Spawns the combo shit on the ui instead of world
@export var enemy_strum_glow = false # When notes are hit, the enemy strum will glow
@export var glow_notes = false # Glows notes when active
@export var note_splashes = true
@export var ui_bops = true # The UI will bop when called
@export var hit_sounds = false
@export var master_volume = 0
@export var music_volume = 0
@export var sfx_volume = 0

@export_group( "Misc" )

@export var song_speed = 1.0
@export var scroll_speed_scale = 1.0 # Multiplies scroll speed
@export var streamer_mode = false # Hides less important UI elements, streamer mode ui function is called
@export var show_performance = true # Shows FPS, Memory, delta and shit


# Keybinds


@export var keybinds = {
	
	# Keybinds
	
	"press_left": [KEY_LEFT, KEY_A],
	"press_down": [KEY_DOWN, KEY_S],
	"press_up": [KEY_UP, KEY_W],
	"press_right": [KEY_RIGHT, KEY_D],
	
	"kill": [82],
	
	# Ui Keybinds
	
	"ui_plus": [KEY_EQUAL],
	"ui_minus": [KEY_MINUS],
	
	"fullscreen": [KEY_F11],
	
	"ui_cancel": [KEY_ESCAPE],
	"ui_accept": [KEY_ENTER, KEY_SPACE],
	
	"ui_left": [KEY_LEFT],
	"ui_down": [KEY_DOWN],
	"ui_up": [KEY_UP],
	"ui_right": [KEY_RIGHT],
	
}
