@icon("uid://c2la537hogg50")
extends Resource
class_name Chart

const CURRENT_VERSION: int = 1

enum ChartFormat {
	VSLICE = 0,
	PSYCH = 1,
	PSYCH_V1 = 2,
	CODENAME = 3,
	UNDEFINED = -1
}

static func chart_format_to_str(type:ChartFormat) -> String:
	match type:
		ChartFormat.CODENAME: return "Codename"
		ChartFormat.VSLICE: return 'VSlice'
		ChartFormat.PSYCH: return 'Psych Legacy'
		ChartFormat.PSYCH_V1: return 'Psych V1'
		_: return "Undefined"

@export_group("Chart Data")

@export_range(0.0, 5.0, 0.1) var scroll_speed = 1.0
## Audio latency.
@export var offset = 0.0

# Actual Chart Storage
@export var chart_data = {
	
	"notes": [],
	"events": [],
	"tempos": {0.0: 60},
	"meters": {0.0: [4, 4]},
}

#this isnt a "great" way to handle versions but i cant justify doing anything more elaborate
var version: int :
	get():
		return chart_data.get('version', 0)
	set(v):
		chart_data.set('version', v)

func get_notes_data() -> Array: return chart_data.get("notes")
func get_events_data() -> Array: return chart_data.get("events")
func get_tempos_data() -> Dictionary: return chart_data.get("tempos")
func get_meters_data() -> Dictionary: return chart_data.get("meters")

func merge_events_into_this(events:ChartEvents):
	var chart_events = get_events_data()
	
	chart_events.append_array(events.data)
	
	var ret_events = [] 
	var push = func(ev:Variant): #clear out dupes
		
		for event in ret_events:
			if is_equal_approx(event[0], ev[0]) \
			and event[1] == ev[1] \
			and event[2] == ev[2]: \
			return
		
		ret_events.append(ev)
	
	for event in chart_events: push.call(event)
	
	ret_events.sort_custom(sort_notes)
	
	chart_data.set('events', ret_events)


func get_tempo_at(time: float) -> float:
	time = max(0, time)
	var output: float = -1
	for point in get_tempos_data():
		if time >= point:
			output = get_tempos_data().get(point)
		else:
			continue
	
	return output


func get_meter_at(time: float) -> Array:
	time = max(0, time)
	var output: Array = []
	for point in get_meters_data():
		if time >= point:
			output = get_meters_data().get(point)
		else:
			continue
	
	return output


func get_tempo_time_at(time: float) -> float:
	time = max(0, time)
	var output: float = -1
	for point in get_tempos_data():
		if time >= point:
			output = point
	
	return output

## attempts to load a chart from a given path.
## This will automatically convert [code]CNE[/code], [code]V-Slice[/code], and [code]Psych[/code] charts to the engines format.
## [br][br]If a chart could not be loaded, a empty chart is provided.
static func load(path:String) -> Chart:
	if path.begins_with('uid'):
		path = ResourceUID.uid_to_path(path)

	if path.get_extension() == 'res' or path.get_extension() == 'tres': ##probably a chart already
		var chart_resource = load(path)
		
		if chart_resource and chart_resource is Chart:
			return update_chart(chart_resource)
			
		return Chart.new()
	elif path.get_extension() == 'json':
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.parse_string(file.get_as_text())
			if json and json is Dictionary:
				match resolve_chart_type(json):
					ChartFormat.PSYCH:
						var events = []
						var events_file = FileAccess.open(path.get_base_dir() + '/events.json', FileAccess.READ)
						
						if events_file:
							var events_json = JSON.parse_string(events_file.get_as_text())
							if events_json:
								if not events_json.has('events'):
									events_json = events_json.get('song')
								
								events = events_json.get('events', [])
								
						return convert_psych(json, events, false)
					ChartFormat.PSYCH_V1:
						var events = []
						var events_file = FileAccess.open(path.get_base_dir() + '/events.json', FileAccess.READ)
						
						if events_file: #maybe check if the events file is cne ?
							var events_json = JSON.parse_string(events_file.get_as_text())
							if events_json:
								if not events_json.has('events'):
									events_json = events_json.get('song')
								
								events = events_json.get('events', [])
						
						
						return convert_psych(json, events)
						
					ChartFormat.VSLICE:
						var meta_path: String = path.get_basename()
						meta_path = meta_path.replace('-chart', '-metadata') + ".json"
						
						assert(FileAccess.file_exists(meta_path), str('failed to find vslice chart metadata.json at: ', meta_path))
						
						var meta_file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
						var meta_json = JSON.parse_string(meta_file.get_as_text())
						if meta_json:
							return convert_vslice(json, meta_json)
					
					ChartFormat.CODENAME:
						var meta_path: String = path.get_base_dir() + '/meta.json'
						
						assert(FileAccess.file_exists(meta_path), 'failed to find cne chart meta.json')
						
						var events: Array = []
						var events_file = FileAccess.open(path.get_base_dir() + '/events.json', FileAccess.READ)
						
						if events_file:
							var events_json = JSON.parse_string(events_file.get_as_text())
							if events_json:
								if events_json is Dictionary:
									if events_json.has('events'):
										events = events_json.get('events')
						
						var meta_file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
						var meta_json = JSON.parse_string(meta_file.get_as_text())
						if meta_json:
							return convert_cne(json, meta_json, events)
					_:
						pass
	
	
	return Chart.new()

static func resolve_chart_type(raw_json:Dictionary) -> ChartFormat:
	
	if raw_json.has('format'):
		var format:String = raw_json.get('format')
		if format.contains('psych_v1'):
			return ChartFormat.PSYCH_V1
	
	if raw_json.has('codenameChart'):
		return ChartFormat.CODENAME
	
	if raw_json.has('version') and raw_json.has('scrollSpeed'):
		return ChartFormat.VSLICE
	
	if raw_json.has('song') and raw_json.get('song') is Dictionary and raw_json.get('song').has('gfVersion'):
		return ChartFormat.PSYCH
	
	return ChartFormat.UNDEFINED

# Sorting notes
static func sort_notes(a, b) -> bool:
	return a[0] < b[0]


static func update_chart(chart: Chart) -> Chart:
	
	if chart.version < CURRENT_VERSION:
		
		if chart.version == 0: #old chart
			print('updating legacy chart')
			var meters = chart.get_meters_data()
			
			for time in meters:
				var meter_data = meters.get(time)
				if int(meter_data[1]) == int(meter_data[0] * 4):
					meter_data[1] /= meter_data[0]
			
			for note in chart.get_notes_data():
				note[3] = str(note[3])
			
			chart.version = CURRENT_VERSION
		
		
		ResourceSaver.save(chart, chart.resource_path)
	
	return chart

static func convert_psych(data:Dictionary,events:Array = [], v1:bool = true) -> Chart:
	var chart = Chart.new()
	
	var note_data = []
	var event_data = []
	var tempo_data = {}
	var meter_data = {0.0: [4, 4]}
	var section_time = 0.0
	
	if not v1:
		data = data.get('song')
	
	var current_bpm:int = data.get('bpm')
	
	chart.scroll_speed = data.get('speed')
	
	tempo_data[0.0] = current_bpm
	
	for i in data.get("notes"):
		# Too lazy to make sure for BPM changes so
		var seconds_per_beat: float = 60.0 / current_bpm
		var section_beats: int = i.get("sectionBeats", 4)
		var seconds_per_measure: float = seconds_per_beat * section_beats
		
		# Checks if the tempo changes, then adds it to the tempos dictionary
		if i.has("changeBPM"):
			if i.changeBPM:
				tempo_data[section_time] = i.bpm
				meter_data[section_time] = [section_beats, 4]
				current_bpm = i.bpm
		
		# Camera movement conversion
		var camera_position: int = 0 if i.mustHitSection else 1
		if i.get("gfSection", false):
			camera_position = 2
		
		event_data.append([section_time, "camera_position", [camera_position]])
		
		for j in i.sectionNotes:
			# Format: time, lane, length in notes, note type
			# Converts the ms length to how many beats the hold node lasts
			var ms_to_notes = (j[2] / 1000.0) / seconds_per_beat
			var note = []
			var lane = j[1]
			
			# Deals with the stupid FnF must hit section bullshit
			if not v1 and camera_position == 1:
				if lane > 3:
					lane -= 4
				else:
					lane += 4
			
			# Creates the note
			note = [j[0] / 1000.0, int(lane), ms_to_notes]
			
			# Deals with note types
			if j.size() == 4:
				match j[3]:
					"No Animation":
						note.append('no_animation')
					"Alt Animation":
						note.append('alt_prefix')
					_:
						note.append(j[3])
			else:
				note.append("")
			
			note_data.append(note)
		
		note_data.sort_custom(sort_notes)
		
		section_time += seconds_per_measure
	
	if data.has('events'):
		events.append_array(data.get('events'))
	
	for i in events:
		var time = i[0]
		# Event name conversion
		for j in i[1]:
			match j[0]:
				"Play Animation":
					j[0] = 'play_animation'
					
					var anim = j[1]
					var char_group:String = j[2].to_lower()
					match char:
						'bf', 'boyfriend':
							char_group = 'player'
						'gf', 'girlfriend':
							char_group = 'metronome'
						_:
							char_group = 'enemy'
					
					j[1] = char_group
					j[2] = anim
				"Set Property":
					if j[1] == 'defaultCamZoom':
						j[0] = 'psych_camera_zoom'
						j[1] = j[2]
				"Change Scroll Speed": #psych changes it by multiplying the base so we r changing it to be direct
					j[0] = 'scroll_speed'
					var new_speed = float(j[1]) * chart.scroll_speed
					j[1] = str(new_speed)
					
			if EVENT_NAMES.has(j[0]):
				j[0] = EVENT_NAMES.get(j[0])
			
			# Creates the event
			## j[1] is the event name, j[2] is the event parameters
			event_data.append([time / 1000.0, j[0], [j[1], j[2]]])
	
	event_data.sort_custom(sort_notes)
	
	chart.chart_data = {
		"notes": note_data,
		"events": event_data,
		"tempos": tempo_data,
		"meters": meter_data
	}
	
	return chart

static func convert_vslice(data:Dictionary, meta:Dictionary,diff:String = '') -> Chart:
	if diff.is_empty():
		diff = GameManager.difficulty
	if diff.is_empty():
		diff = 'normal'
	
	if not data.get('notes').has(diff):
		diff = meta.get('playData').get('difficulties')[0]
	
	
	var chart = Chart.new()
	
	var note_data = []
	var event_data = []
	var tempo_data = {}
	var meter_data = {0.0: [4, 4]}
	
	# Get tempo at certain time
	var get_temp_at_struct = func(time:float, tempo_dict:Dictionary) -> float:
		var output: float = -1
		for point in tempo_dict:
			if time >= point:
				output = tempo_dict.get(point)
			else:
				continue
		
		return output
	
	
	chart.scroll_speed = data.scrollSpeed[diff]
	
	# Adding tempo data
	for i in meta.get('timeChanges'):
		if i.t < 0:
			i.t = 0
		
		tempo_data[i.t / 1000] = i.bpm
		meter_data[i.t / 1000] = [i.n, i.d]
	
	for i in data.get('notes').get(diff):
		var time = i.t / 1000.0
		var lane = int(i.d)
		
		var tempo = get_temp_at_struct.call(time, tempo_data)
		var seconds_per_beat = 60.0 / tempo
		
		var length = 0
		if i.has("l"):
			length = i.l / 1000.0 / seconds_per_beat
		
		var note_type: String = i.get("k", "")
		note_data.append([time, lane, length, note_type])
	
	note_data.sort_custom(sort_notes)
	
	# Adding event data.
	for i in data.get('events'):
		var time = i.t / 1000.0
		
		var tempo = get_temp_at_struct.call(time, tempo_data)
		var seconds_per_beat = 60.0 / tempo
		
		time = snapped(time, seconds_per_beat)
		
		var event = i.e
		var parameters = []
		
		var event_name = event
		if EVENT_NAMES.has(event):
			event_name = EVENT_NAMES.get(event)
		
		if i.v is Dictionary:
			parameters.append_array(i.v.values())
		else:
			parameters.append(str(i.v))
		
		if event == "FocusCamera":
			parameters = [int(i.v.char)]
		elif event == "ZoomCamera":
			parameters = [i.v.zoom, str(i.v.duration, 's'), i.v.get("ease", "CLASSIC")]
		elif event == "SetCameraBop":
			parameters = [i.v.rate * 4]
		elif event == "PlayAnimation":
			var char_group: String = i.v.target.to_lower()
			match char:
				'bf', 'boyfriend':
					char_group = 'player'
				'gf', 'girlfriend':
					char_group = 'metronome'
				_:
					char_group = 'enemy'
			
			parameters = [char_group, i.v.anim]
		
		event_data.append([time, event_name, parameters])
	
	event_data.sort_custom(sort_notes)
	
	chart.chart_data = {
		"notes": note_data,
		"events": event_data,
		"tempos": tempo_data,
		"meters": meter_data
	}
	
	return chart

static func convert_cne(data:Dictionary, meta:Dictionary, events:Array = []) -> Chart:
	var chart = Chart.new()
	
	var note_data = []
	var event_data = []
	var tempo_data = {}
	var meter_data = {0.0: [4, 4]}
	
	# Get tempo at certain time
	var get_temp_at_struct = func(time:float,tempo_dict:Dictionary) -> float:
		var output: float = -1
		for point in tempo_dict:
			if time >= point:
				output = tempo_dict.get(point)
			else:
				continue
		
		return output
	
	chart.scroll_speed = data.get('scrollSpeed')
	
	var current_bpm = meta.get('bpm')
	tempo_data[0.0] = current_bpm
	
	if data.has('events'):
		events.append_array(data.get('events'))
	
	for event_packet in events:
		
		var event = []
		if event_packet.name == 'Camera Movement':
			pass
			
			if event_packet.params[0] == 1: event_packet.params[0] = 0
			elif event_packet.params[0] == 0: event_packet.params[0] = 1
			
			
			event = [event_packet.time / 1000.0, 'camera_position', event_packet.params]
			
		elif EVENT_NAMES.has(event_packet.name):
			event = [event_packet.time / 1000.0, EVENT_NAMES[event_packet.name], event_packet.params]
		elif event_packet.name == "BPM Change":
			tempo_data[event_packet.time / 1000.0] = event_packet.params[0]
		else:
			event = [event_packet.time / 1000.0, event_packet.name, event_packet.params]
		
		event_data.append(event)
	
	event_data.sort_custom(sort_notes)
	
	for strumline in data.get('strumLines'):
		for i in strumline.notes:
			# Format: time, lane, length in notes, note type
			# Converts the ms length to how many beats the hold node lasts
			
			var time = i.time / 1000.0
			current_bpm = get_temp_at_struct.call(time, tempo_data)
			var seconds_per_beat = 60.0 / current_bpm
			var ms_to_notes = 0
			if i.sLen:
				ms_to_notes = ((i.sLen / 1000.0) / seconds_per_beat)
			var lane = i.id
			
			if strumline.position == "dad":
				lane += 4
			
			# Creates the note
			var note = [time, lane, ms_to_notes, i.type]
			note_data.append(note)
	
	note_data.sort_custom(sort_notes)
	
	chart.chart_data = {
		"notes": note_data,
		"events": event_data,
		"tempos": tempo_data,
		"meters": meter_data
	}
	
	return chart
	
# Event names for easy conversion to noah engine
const EVENT_NAMES = {
	
	# Psych Engine Names
	"Add Camera Zoom": "camera_bop",
	"Screen Shake": "psych_camera_shake",
	
	# Base Game Names
	"FocusCamera": "camera_position",
	"PlayAnimation": "play_animation",
	"SetCameraBop": "bop_rate",
	"ZoomCamera": "camera_zoom",
	
	# Codename names
	"Camera Movement": "camera_position",
	"Play Animation": "play_animation",
	"Camera Bop": "camera_bop",
	"Camera Zoom": "camera_zoom",
	"Camera Modulo Change": "bop_rate",
	"Scroll Speed Change": "scroll_speed",
	
}
