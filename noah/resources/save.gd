extends Resource
class_name Save

## Save File for things like tokens or highscores

## Stuff for like "beat week 1" or "unlocked weekend 1"
@export var tokens: Array = []
## To put a song/week in highscores it needs to be a dictionary
## [br]Example: [code]"darnell": {"hard": {"highscore": 2418414, "grade": 94}, "erect": {"highscore": 3298517, "grade": 99}}[/code]
@export var song_stats: Dictionary = {}
@export var week_stats: Dictionary = {}
