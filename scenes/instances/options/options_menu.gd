extends TabContainer


func _on_button_pressed():
	
	SoundManager.music.stop()
	Global.change_scene_to("res://scenes/options/offset_calibrator.tscn")


func _on_clear_save_pressed() -> void:
	SaveManager.init()
