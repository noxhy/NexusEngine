extends Node

const save_path = "user://save.tres"
var save_file = Save.new()

func save():
	
	ResourceSaver.save(save_file, save_path)
	print("Saved Tokens and Highscores")

func load_save():
	
	if load(save_path) == null:
		init()
	
	save_file = load(save_path)
	
	print(save_path)


func init():
	
	save_file = Save.new()
	ResourceSaver.save(save_file, save_path)
	print("Setting Initialized")


func has_token(token: String) -> bool: return save_file.tokens.has(token)

## Checks if a token is in the list and then adds it
func add_token(token: String):
	
	if has_token(token):
		
		save_file.tokens.append(token)
		save()

## Checks if a token is in the list and then removes it
func remove_token(token: String):
	
	if has_token(token):
		
		save_file.tokens.erase(token)
		save()

## Sets the results data of a song for a certain difficulty
## Returns true if the new score is a highscore.
func set_song_stats(song: String, difficulty: String, score: int, grade: float) -> bool:
	
	var output: bool = false
	if !save_file.song_stats.has(song): save_file.song_stats[song] = {}
	if !save_file.song_stats[song].has(difficulty):
		save_file.song_stats[song][difficulty] = {"highscore": -1, "grade": -1}
	# So you don't have to worry about checking it yourself
	var highscore: int = get_highscore(song, difficulty)
	if (highscore == -1 || highscore < score):
		
		save_file.song_stats[song][difficulty]["highscore"] = score
		output = true
	
	# So you don't have to worry about checking it yourself
	var _grade: float = get_grade(song, difficulty)
	if (_grade == -1 || _grade < grade):
		save_file.song_stats[song][difficulty]["grade"] = grade
	
	save()
	return output


## Sets the results data of a week for a certain difficulty
## Returns true if the new score is a highscore.
func set_week_stats(week: String, difficulty: String, score: int, grade: float) -> bool:
	
	var output: bool = false
	if !save_file.week_stats.has(week): save_file.week_stats[week] = {}
	if !save_file.week_stats[week].has(difficulty):
		save_file.week_stats[week][difficulty] = {"highscore": -1, "grade": -1}
	# So you don't have to worry about checking it yourself
	var highscore: int = save_file.week_stats[week][difficulty]["highscore"]
	if (highscore == -1 || highscore < score):
		
		save_file.week_stats[week][difficulty]["highscore"] = score
		output = true
	
	# So you don't have to worry about checking it yourself
	var _grade: float = save_file.week_stats[week][difficulty]["grade"]
	if (_grade == -1 || grade < _grade):
		save_file.week_stats[week][difficulty]["grade"] = grade
	
	save()
	return output


## Gets the highscore of the difficulty of the song
func get_highscore(song: String, difficulty: String) -> int:
	
	if !save_file.song_stats.has(song): return -1
	if !save_file.song_stats[song].has(difficulty): return -1
	return save_file.song_stats[song][difficulty]["highscore"]

## Gets the grade of the difficulty of the song
func get_grade(song: String, difficulty: String) -> float:
	
	if !save_file.song_stats.has(song): return -1
	if !save_file.song_stats[song].has(difficulty): return -1
	return save_file.song_stats[song][difficulty]["grade"]

## Gets the highscore of the difficulty of the week
func get_week_highscore(week: String, difficulty: String) -> int:
	
	if !save_file.week_stats.has(week): return -1
	if !save_file.week_stats[week].has(difficulty): return -1
	return save_file.week_stats[week][difficulty]["highscore"]

## Gets the grade of the difficulty of the week
func get_week_grade(week: String, difficulty: String) -> float:
	
	if !save_file.week_stats.has(week): return -1
	if !save_file.week_stats[week].has(difficulty): return -1
	return save_file.week_stats[week][difficulty]["grade"]
