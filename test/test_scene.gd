extends Node2D

@export var album_list: Array[Album]


# Called when the node enters the scene tree for the first time.
func _ready():
	
	for i in album_list:
		
		$"Album List".text += i.name + " " + i.credits + "\n"
	
	$"Song List".text = album_list[0].name + " Song List:\n\n"
	
	for i in album_list[0].song_list:
		
		i.chart.chart_data.erase( "notes" )
		i.chart.chart_data.erase( "events" )
		$"Song List".text += i.chart.song_title + " by " + i.chart.artist + "\n"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
