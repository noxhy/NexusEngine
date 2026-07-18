extends HBoxContainer
class_name ChartEditorLowerUI

@onready var play_button: Button = %"Play Button"
@onready var skip_to_beginning: Button = %"Skip to Beginning"
@onready var skip_backward: Button = %"Skip Backward"
@onready var skip_to_end: Button = %"Skip to End"
@onready var skip_forward: Button = %"Skip Forward"
@onready var difficulty_button: OptionButton = %"Difficulty Button"
@onready var chart_snap: SpinBox = %"Chart Snap"

@onready var current_time_label: Label = %"Current Time Label"

@onready var time_left_label: Label = %"Time Left Label"


var chart_editor: ChartEditor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chart_editor = get_parent().get_parent()
	
	play_button.connect(&"toggled", _play_button_pressed)
	skip_to_beginning.connect(&"pressed", chart_editor._on_skip_to_beginning_pressed)
	skip_to_end.connect(&"pressed", chart_editor._on_skip_to_end_pressed)
	skip_backward.connect(&"pressed", chart_editor._on_skip_backward_pressed)
	skip_forward.connect(&"pressed", chart_editor._on_skip_forward_pressed)
	difficulty_button.connect(&"item_selected", chart_editor._on_difficulty_button_item_selected)
	chart_snap.connect(&"value_changed", chart_editor._on_chart_snap_value_changed)
	
	#add menupopups to the thing
	
	difficulty_button.get_popup().add_to_group(&"windows")

func _play_button_pressed(v):
	chart_editor.toggle_audios(not v)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not chart_editor:
		return
		
	if ChartManager.song and chart_editor.instrumental and chart_editor.instrumental.stream:
		time_left_label.text = "-" + Global.format_time(chart_editor.instrumental.stream.get_length() - chart_editor.song_position - chart_editor.start_offset)
	else:
		time_left_label.text = "- ??:??"
		
	current_time_label.text = Global.format_time(chart_editor.song_position + chart_editor.start_offset)
	current_time_label.text += str(" (", chart_editor.song_speed, "x)")

func toggle_play_button_state(playing: bool):
	play_button.icon = load("uid://c1mgxe0dqdbgh") if playing else load("uid://byl3boevtc02p")
	play_button.set_pressed_no_signal(playing)
