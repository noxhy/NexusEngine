extends Label
var chart_editor: ChartEditor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chart_editor = get_parent().get_parent()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if chart_editor and ChartManager.chart:
		if chart_editor.hovered_note != -1:
			var note_type: String = ChartManager.chart.get_notes_data()[chart_editor.hovered_note][3]
			var text_str: String = str('Type: ', note_type if not note_type.is_empty() else '?') 
			text = text_str
			visible = true
			position = get_global_mouse_position() + Vector2(8, 5)
		
		elif chart_editor.hovered_event != -1:
			var event = ChartManager.chart.get_events_data()[chart_editor.hovered_event][1]
			var parameters = ChartManager.chart.get_events_data()[chart_editor.hovered_event][2]
			var text_str: String = event + ': [%s]' % ", ".join(PackedStringArray(parameters))
			text = text_str
			visible = true
			position = get_global_mouse_position() + Vector2(8, 5)
		else:
			visible = false
