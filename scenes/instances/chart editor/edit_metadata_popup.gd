extends Window

@export var artist: String = ""
@export var song_title: String = ""
@export var song_difficulty: String = ""

@export var offset: float
@export var scroll_speed: float

signal metadata_changed( artist: String, song_title: String, song_difficulty: String, offset: float, scroll_speed: float )

func _ready():
	
	%"Artist Name".text = artist
	%"Song Title".text = song_title
	%"Song Difficulty".text = song_difficulty
	
	%Offset.value = offset
	%"Scroll Speed".value = scroll_speed


func _on_save_button_pressed():
	
	emit_signal( "metadata_changed", %"Artist Name".text, %"Song Title".text, %"Song Difficulty".text, %Offset.value, %"Scroll Speed".value )
	self.queue_free()


func _on_close_requested(): self.queue_free()
