extends Node

##TODO: better docs use better tag stuff 

const SICK_RATING_WINDOW: float = 0.045
const GOOD_RATING_WINDOW: float = 0.09
const BAD_RATING_WINDOW: float = 0.135
const SHIT_RATING_WINDOW: float = 0.16
const GOOD_COMBO_FREQUENCY: int = 50
const GREAT_COMBO_FREQUENCY: int = 200
const HOLD_NOTE_LENIENCY: float = 1 / 3.0

const GOLD_RANK_REQ: float = 2.0
const PERFECT_RANK_REQ: float = 1.0
const EXCELLENT_RANK_REQ: float = 0.90
const GREAT_RANK_REQ: float = 0.80
const GOOD_RANK_REQ: float = 0.60
const LOSS_RANK_REQ: float = 0.00

## The last remembered path the loaded scene. Useful if u need to return to a song after exiting.
var song_scene: String = ''

var conductor:Conductor

## The current defined play mode. decides where playstate will go next after a given song and whether to save score.
enum PLAY_MODE {
	STORY_MODE,
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

var difficulty: String
var play_mode: PLAY_MODE = PLAY_MODE.FREEPLAY

var week_songs: Array[Song] = []
var current_week_song: int = 0
var _current_song_freeplay: Song

var current_week: Week

## the currently loaded song. this should not be set directly with set_song_freeplay and set_song_storymode being used instead.
## if current_song is null, the song was not set correctly.
var current_song: Song :
	get():
		if play_mode == PLAY_MODE.STORY_MODE and current_week_song > week_songs.size():
			return week_songs[current_week_song]
		
		return _current_song_freeplay

## helper function to prepare the game for song to use a given song in the next playstate instance
func set_song_freeplay(song: Song, song_difficulty: String):
	_current_song_freeplay = song
	play_mode = PLAY_MODE.FREEPLAY
	difficulty = song_difficulty
	
## helper function to prepare the game to use a given week in the next playstate instance
func set_song_storymode(songs: Array[Song], song_difficulty: String):
	week_songs = songs
	current_week_song = 0
	play_mode = PLAY_MODE.STORY_MODE
	difficulty = song_difficulty

var character: PlayableCharacter
var current_character: String = ""

var songs_played: int = 0
var grade: float
var highscore: bool = false

var song_position: float
var seconds_per_beat: float :
	get():
		return conductor.seconds_per_beat
var seconds_per_step: float :
	get():
		return conductor.seconds_per_step
var offset: float :
	get():
		return conductor.offset

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
	
	current_song = song
	character = Preload.character_data[current_character]

func start_week(week: Week):
	current_week = week
	week_songs = week.song_list.duplicate()
	current_week_song = 0
	play_mode = GameManager.PLAY_MODE.STORY_MODE

## called by PlayState whenever a song is finished. Saves scoring.
func save_and_refresh_stats(_stats: NoahStats):
	week_stats.add_from(_stats)
	last_song_stats.copy_from(_stats)
	
	week_deaths += deaths
	deaths = 0
	
	songs_played += 1
	current_week_song += 1
	
	grade = get_grade(week_stats)
	
	if can_save_score():
		highscore = SaveManager.set_song_stats(current_song, difficulty, _stats.score_as_int, get_grade(last_song_stats))
		if play_mode != PLAY_MODE.FREEPLAY and current_week_song == week_songs.size():
			highscore = SaveManager.set_week_stats(current_week, difficulty, week_stats.score_as_int, grade)
		else:
			highscore = false
	else:
		highscore = false

## Resets all remembered gameplay stats back to 0.
func reset_stats():
	week_stats.reset()
	last_song_stats.reset()
	
	deaths = 0
	week_deaths = 0
	
	songs_played = 0
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

func get_grade(_stats: NoahStats = last_song_stats) -> float:
	if _stats.total_notes == 0:
		return 0.0
	if _stats.sicks == _stats.total_notes:
		return 2.0
	
	return float(_stats.sick + _stats.good - _stats.miss) / _stats.total_notes

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
