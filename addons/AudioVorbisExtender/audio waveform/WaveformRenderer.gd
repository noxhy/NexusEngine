class_name WaveformRenderer ; extends WaveFormMesh

enum orientation {HORIZONTAL,VERTICAL}

var time := 0.0 ; var duration := 5.0
var width := 100.0 ; var height := 100.0

var amplitude := 200.0
var minWaveformSize := 0.5

var current_orientation := orientation.HORIZONTAL

var data:WaveformData

var line_width := -1.0
var wave_color:Color
var bg_color:Color

var antialiasing := false

var dirty := false


var vertical:bool:
	get():
		return current_orientation == orientation.VERTICAL

var dimensions:Vector2:
	get():
		return Vector2(width,height) if !vertical else Vector2(height,width)




func _init(p_data:WaveformData,p_duration := 0.0,p_color := Color.WHITE,p_bg := Color.GRAY) -> void:
	wave_color = p_color ; bg_color = p_bg
	data = p_data
	if data:
		if p_duration <= 0.0: p_duration = data.songLength * 130
		duration = p_duration
	
	dirty = true

func _process(_delta) -> void:
	queue_redraw()
	if !dirty: return
	
	render()
	dirty = false


func render():
	clear()
	if data == null: printerr('waveform data is null') ; return
	var waveformCenterPos := int(height / 2)
	
	var startIndex = data.secondsToIndex(time)
	var Index = data.secondsToIndex(duration)
	
	var pixelsPerIndex = float(width) / (Index)
	var indexesPerPixel = 1 / pixelsPerIndex
	
	var this_channel = data.channel(0)
	
	
	for pixel in width:
		var sampleMax = 0 ; var sampleMin = 0
		
		var rangeStart = int(pixel * indexesPerPixel + startIndex)
		var rangeEnd = int((pixel + 1) * indexesPerPixel + startIndex)
		
		sampleMax = min(this_channel.maxSampleRangeMap(rangeStart,rangeEnd) * amplitude,1.0)
		sampleMin = max(this_channel.minSampleRangeMap(rangeStart,rangeEnd) * amplitude,-1.0)
		
		
		var sampleMaxSize = 0 ; var sampleMinSize = 0
		if sampleMax + sampleMin != 0:
			sampleMaxSize = sampleMax * height / 2
			if sampleMaxSize < minWaveformSize: sampleMaxSize = minWaveformSize

			sampleMinSize = sampleMin * height / 2
			if sampleMinSize > -minWaveformSize: sampleMinSize = -minWaveformSize
		
		var vertexTopY = int(waveformCenterPos - sampleMaxSize)
		var vertexBottomY = int(waveformCenterPos - sampleMinSize)
		build_line(vertexTopY,vertexBottomY,pixel,vertical)


func _draw():
	draw_rect(Rect2(0,0,dimensions.x,dimensions.y),bg_color)
	if vertices.is_empty(): return
	if antialiasing and line_width < 0: line_width = 1.0
	draw_polyline(vertices,wave_color,line_width,antialiasing)


func _exit_tree():
	if data == null: return
	data.clear_data()
	data = null

class WaveFormMesh:
	extends Node2D
	var vertices:PackedVector2Array = []
	
	func build_line(y,yy,x,vertical,to = vertices):
		var line = [Vector2(x, y),Vector2(x, yy)]
		if vertical: line = [Vector2(y, x),Vector2(yy, x)]
		
		to.append_array(line)


	func clear():
		vertices.clear()
	
	func build():
		vertices = PackedVector2Array(vertices)
