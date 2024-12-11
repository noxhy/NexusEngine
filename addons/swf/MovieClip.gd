class_name MovieClip

var current_frame: int
var total_frames: int

var container: Array

var first_transform: Transform2D

var timelines: Dictionary
var depth_frame: Dictionary

func _init(_total_frames: int, _timelines: Dictionary) -> void:
	total_frames = _total_frames
	timelines = _timelines
	current_frame = 0
	for depth in timelines.keys():
		# 填入{depth: [index, durating]}
		depth_frame[depth] = {"index": 0, "duration": 1}

var shape_transform: Dictionary


enum NextFrame {
	Next,
	First,
}

func _deterimine_current_frame() -> NextFrame:
	if current_frame < total_frames:
		return NextFrame.Next
	elif total_frames > 1:
		return NextFrame.First
	else:
		return NextFrame.Next
