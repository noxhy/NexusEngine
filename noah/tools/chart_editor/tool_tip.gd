extends Label

var chart_editor: ChartEditor

var mouse_offset: Vector2 = Vector2(10, 5)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chart_editor = get_parent().get_parent()
	var stylebox = StyleBoxFlat.new()
	stylebox.set_expand_margin(SIDE_LEFT, 2)
	stylebox.set_expand_margin(SIDE_RIGHT, 2)
	stylebox.bg_color = Color(0.0, 0.0, 0.0, 0.686)
	add_theme_stylebox_override("normal", stylebox)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if chart_editor and chart_editor.is_mouse_over_grid() and ChartManager.chart:
		var last_text = text
		if chart_editor.hovered_note != -1:
			var note_type: String = ChartManager.chart.get_notes_data()[chart_editor.hovered_note][3]
			var text_str: String = str('Type: ', note_type if not note_type.is_empty() else '?') 
			text = text_str
			visible = true
			position = get_global_mouse_position() + mouse_offset
		elif chart_editor.hovered_event != -1:
			var event = ChartManager.chart.get_events_data()[chart_editor.hovered_event][1]
			var parameters = ChartManager.chart.get_events_data()[chart_editor.hovered_event][2]
			var text_str: String = event + ': [%s]' % ", ".join(PackedStringArray(parameters))
			text = text_str
			visible = true
			position = get_global_mouse_position() + mouse_offset
		else:
			visible = false
		
		if last_text != text:
			size = get_minimum_size()
