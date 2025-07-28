extends TabContainer


func _on_button_pressed():
	
	Global.stop_song()
	Global.change_scene_to("res://scenes/options/offset_calibrator.tscn")


func _on_clear_save_pressed() -> void:
	SaveHandeler.init()
