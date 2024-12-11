extends Node

const save_path = "user://save.tres"
var save_file = Save.new()

func save():
	
	ResourceSaver.save( save_file, save_path )
	print( "Saved Tokens and Highscores" )

func load_save():
	
	if load( save_path ) == null || save_file.version != 1:
		init()
	
	save_file = load( save_path )
	
	print( save_path )


func init():
	
	save_file = Save.new()
	ResourceSaver.save( save_file, save_path )
	print( "Setting Initialized" )


func has_token( token: String ) -> bool: return save_file.tokens.has(token)

## Checks if a token is in the list then adds it
func add_token( token: String ):
	
	if has_token(token):
		
		save_file.tokens.append(token)
		save()

## Checks if a token is in the list then removes it it
func remove_token( token: String ):
	
	if has_token(token):
		
		save_file.tokens.erase(token)
		save()

## Sets the results data of a song for a certain difficulty
func set_song_stats( song: String, difficulty: String, score: int, grade: int ):
	
	if !save_file.song_stats.has(song): save_file.song_stats[song] = {}
	# So you don't have to worry about checking it yourself
	if !save_file.song_stats[song][difficulty].has("highscore"): save_file.song_stats[song][difficulty]["highscore"] = score
	elif get_highscore( song, difficulty ) < score: save_file.song_stats[song][difficulty]["highscore"] = score
	save_file.song_stats[song][difficulty]["grade"] = grade
	save()

## Gets the highscore of the difficulty of the song
func get_highscore( song: String, difficulty: String) -> int:
	
	if !save_file.song_stats.has(song): return -1
	if !save_file.song_stats[song].has(difficulty): return -1
	return save_file.song_stats[song][difficulty]["highscore"]

## Gets the grade of the difficulty of the song
func get_grade( song: String, difficulty: String) -> int:
	
	if !save_file.song_stats.has(song): return -1
	if !save_file.song_stats[song].has(difficulty): return -1
	return save_file.song_stats[song][difficulty]["grade"]
