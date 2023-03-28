extends TabContainer


func _on_button_pressed():
	
	Global.stop_song()
	Global.change_scene_to("res://scenes/options/offset_calibrator.tscn")
