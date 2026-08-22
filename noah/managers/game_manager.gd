extends Node

##TODO: better docs use better tag stuff 
##TODO: rename storymode to playlist and alter some business

# These are explanatory.
const SICK_RATING_WINDOW: float = 0.045
const GOOD_RATING_WINDOW: float = 0.09
const BAD_RATING_WINDOW: float = 0.135
const SHIT_RATING_WINDOW: float = 0.16
const GOOD_COMBO_FREQUENCY: int = 50
const GREAT_COMBO_FREQUENCY: int = 200
const HOLD_NOTE_LENIENCY: float = 1 / 3.0

# These are explanatory.
const GOLD_RANK_REQ: float = 2.0
const PERFECT_RANK_REQ: float = 1.0
const EXCELLENT_RANK_REQ: float = 0.90
const GREAT_RANK_REQ: float = 0.80
const GOOD_RANK_REQ: float = 0.60
const LOSS_RANK_REQ: float = 0.00

## The last remembered path the loaded scene. Useful if u need to return to a song after temporarily exiting.
var song_scene: String = ''

## Global conductor utilized by the playstate.
var conductor:Conductor

## The current defined play mode. decides where [PlayState] will go next after a given song and whether to save score.
enum PLAY_MODE {
	## Used for playing a "week". Moves to the next songs scene after play and saves progression as a week.
	PLAYLIST,
	## Standard mode for playing a individual song. Moves to [member PlayState.next_scene] after play.
	FREEPLAY,
	## Returns to the editor after play.
	CHARTING,
}

## The previous played song's remembered stats. Can be used for things such as a result screen.
## Note these are only set after a song is finished and not in real time.
var last_song_stats: NoahStats = NoahStats.new()

## The accumulated stats from a week when playing in Story Mode.
var week_stats: NoahStats = NoahStats.new()

## The total deaths on a singular song.
var deaths: int = 0

## The total deaths within a week.
var week_deaths: int = 0

## The current difficulty being played. 
var difficulty: String = ''

## The current defined play mode. Check [enum GameManager.PLAY_MODE] for how these are used.
var play_mode: PLAY_MODE = PLAY_MODE.FREEPLAY

## Array of all songs currently loaded.
var week_songs: Array[Song] = []

## The current loaded song index within [member week_songs].
var current_week_song: int = 0

## The current week meta. Set via [method load_from_week]
var current_week: Week

## the currently loaded song. this should not be set directly with [method load_songs], [method load_song], [method load_from_week] being used instead.
## if current_song is null, the song was not set correctly.
var current_song: Song :
	set(_song):
		load_song(_song, difficulty)
	get():
		if week_songs.is_empty(): return null
		return week_songs[current_week_song % week_songs.size()]

## Func to initiate [code]GameManager[/code] for a song to be played. if the [param _play_mode] is not [code]PLAYLIST[/code], only the first song in songs is used.
## [br][br][color=khaki]NOTE[/color]: If you are using [code]PLAY_MODE.PLAYLIST[/code] look to [method load_from_week]
func load_songs(songs: Array[Song], _difficulty: String, _play_mode: PLAY_MODE = PLAY_MODE.FREEPLAY):
	play_mode = _play_mode
	difficulty = _difficulty
	
	current_week_song = 0
	week_songs = songs

## Helper func to initiate [code]GameManager[/code] to play a song.
## [br][br]Simplified wrapper to load 1 song via [method GameManager.load_songs]
func load_song(song: Song, _difficulty: String):
	load_songs([song], _difficulty, PLAY_MODE.FREEPLAY)

## Helper func to initiate [code]GameManager[/code] to play a playlist.
## [br][br]Simplified wrapper to load a playlist via [method GameManager.load_songs]
func load_from_week(week: Week, _difficulty: String):
	current_week = week
	load_songs(week.song_list, _difficulty, PLAY_MODE.PLAYLIST)

var character: PlayableCharacter
var current_character: String = ""

var grade: float = 0.0

## Will be true if the last played Song/Playlist got a highscore.
var highscore: bool = false

## The current song position. updated via [PlayState]
var song_position: float = 0.0

## Refreshes the conductor with a new instance.
func reset_conductor():
	if conductor:
		remove_child(conductor)
		conductor.free()
	conductor = Conductor.new()
	add_child(conductor)
	conductor.new_beat.connect(_beat_change)
	conductor.new_step.connect(_step_change)

func _step_change(step: int, measure: int):
	Signals.play_conductor_step_hit.emit(step, measure)

func _beat_change(beat: int, measure: int):
	Signals.play_conductor_beat_hit.emit(beat, measure)

func _ready() -> void:
	reset_conductor()
	reset_stats()

func started_song(song: Song):
	last_song_stats.reset()
	
	if Preload.character_data.has(current_character):
		character = Preload.character_data[current_character]

## called by PlayState whenever a song is finished. Saves scoring.
func save_and_refresh_stats(_stats: NoahStats):
	week_stats.add_from(_stats)
	last_song_stats.copy_from(_stats)
	
	week_deaths += deaths
	deaths = 0
	
	current_week_song += 1
	
	grade = get_grade(week_stats)
	
	if can_save_score():
		if play_mode == PLAY_MODE.PLAYLIST:
			highscore = current_week_song == week_songs.size() and SaveManager.set_week_stats(current_week, difficulty, week_stats.score_as_int, grade)
		else:
			highscore = SaveManager.set_song_stats(current_song, difficulty, _stats.score_as_int, get_grade(last_song_stats))
	else:
		highscore = false

## Resets all remembered gameplay stats back to 0.
func reset_stats():
	week_stats.reset()
	last_song_stats.reset()
	
	deaths = 0
	week_deaths = 0
	
	current_week_song = 0
	
## Checks preferences to see if scoring should be saved.
func can_save_score() -> bool:
	if SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "botplay"):
		return false
	
	if play_mode == PLAY_MODE.CHARTING:
		return false
		
	if !is_equal_approx(SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "song_speed"), 1):
		return false
	
	if !is_equal_approx(SettingsManager.get_value(SettingsManager.SEC_GAMEPLAY, "scroll_speed_scale"), 1):
		return false
	
	return true

## gets a grade from a stats
func get_grade(_stats: NoahStats = last_song_stats) -> float:
	if _stats.total_notes == 0:
		return 0.0
	if _stats.sicks == _stats.total_notes:
		return 2.0
	
	return float(_stats.sicks + _stats.goods - _stats.misses) / _stats.total_notes

## gets a rank by a grade.
func get_rank(_grade: float) -> String:
	var accuracies = [
		[_grade == GOLD_RANK_REQ, "gold"],
		[_grade == PERFECT_RANK_REQ, "perfect"],
		[_grade >= EXCELLENT_RANK_REQ, "excellent"],
		[_grade >= GREAT_RANK_REQ, "great"],
		[_grade >= GOOD_RANK_REQ, "good"],
		[_grade >= LOSS_RANK_REQ, "loss"],
	]
	
	for condition in accuracies: if condition[0]:
		return condition[1]
	return "?"
