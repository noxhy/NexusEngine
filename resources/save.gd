extends Resource
class_name Save

## Save File for things like tokens or highscores

## Stuff for like "beat x week" or "unlocked x song"
@export var tokens: Array = []
## To put a song/week in highscores it needs to be a dictionary
## ex) "darnell": { "hard": { "highscore": 2418414, "grade": 94 }, "erect": { "highscore": 3298517, "grade": 99 } }
@export var song_stats: Dictionary = {}
