extends HBoxContainer

signal removed

var event: String:
	set(v):
		%"Track Name".text = v

		var icon: String = Constants.EVENT_DATA.get(v, {}).get("texture", "res://addons/at-icons/node/diamond_shape.svg")
		%"Track Name".right_icon = load(icon)
		
		var tip: String = "event: " + v
		
		var desc: String = Constants.EVENT_DATA.get(v, {}).get("description", "")
		if not desc.is_empty():
			tip += '\ndesc: ' + Constants.EVENT_DATA.get(v, {}).get("description", "")
			
		
		%"Track Name".tooltip_text =tip
		
		event = v


func _on_remove_track_pressed() -> void:
	emit_signal(&"removed")
