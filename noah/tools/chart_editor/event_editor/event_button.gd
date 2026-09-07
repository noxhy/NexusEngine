extends HBoxContainer

signal removed

var event: String:
	set(v):
		%"Track Name".text = v
		var icon: String = Constants.EVENT_DATA.get(v, {}).get("texture", "")
		if ResourceLoader.exists(icon):
			%"Track Name".right_icon = load(icon)
			
		
		%"Track Name".tooltip_text = "event: " + v + '\n\ndesc: ' + Constants.EVENT_DATA.get(v, {}).get("description", "")
		
		event = v


func _on_remove_track_pressed() -> void:
	emit_signal(&"removed")
