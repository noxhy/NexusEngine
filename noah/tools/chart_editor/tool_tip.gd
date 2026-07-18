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
	
	
	visible = ChartManager.chart and chart_editor and chart_editor.is_mouse_over_grid() and (chart_editor.hovered_event != -1 or chart_editor.hovered_note != -1)
	if not visible:
		return

	var last_text = text
	if chart_editor.hovered_note != -1:
		var note_type: String = ChartManager.chart.get_notes_data()[chart_editor.hovered_note][3]
		var text_str: String = str('Type: ', note_type if not note_type.is_empty() else '?') 
		text = text_str
	elif chart_editor.hovered_event != -1:
		text = get_event_str()
	
	if last_text != text:
		size = get_minimum_size()
	
	position = get_global_mouse_position() + mouse_offset

func get_event_str() -> String:
	
	if chart_editor.name != 'Chart Editor':
		var event = ChartManager.chart.get_events_data()[chart_editor.hovered_event]
		var parameters = ChartManager.chart.get_events_data()[chart_editor.hovered_event][2]
		return event[1] + ': [%s]' % ", ".join(PackedStringArray(parameters))
	
	var found_events = chart_editor.find_events_at(ChartManager.chart.get_events_data()[chart_editor.hovered_event][0])
	
	var ret: String = ''
	
	for ev_idx in found_events:
		var ev = ChartManager.chart.get_events_data()[ev_idx]
		var ev_params = ev[2]
		ret += ev[1] + ': [%s]' % ", ".join(PackedStringArray(ev_params)) + '\n'
	return ret.strip_edges()
