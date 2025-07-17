class_name SymbolElement extends Element

enum SymbolType {
	GRAPHIC = 0,
	MOVIE_CLIP
}

enum SymbolLoopMode {
	LOOP = 0,
	ONE_SHOT,
	FREEZE_FRAME,
	REVERSE_ONE_SHOT,
	REVERSE_LOOP
}


@export var instance_name: StringName
@export var symbol_type: SymbolType
@export var frame: int
@export var loop_mode: SymbolLoopMode
@export var filters: Array[Filter] = []
@export var color_transform: ColorTansform

# -------------------------------------------------------------------
# Key aliases – add new rows here when you support more filter types
# -------------------------------------------------------------------
var FILTER_ALIASES := {
	
	"BLUR": {
		"nodes": ["BlurFilter", "BLF"],
		"props": {
			"x": ["blurX", "BLX"],
			"y": ["blurY", "BLY"],
			"quality": ["quality", "Q"],
		},
		"class": BlurFilter,
		"f_type": Filter.FilterType.BLUR,
	},
	"ACF": {
		"nodes": ["AdjustColorFilter", "ACF"],
		"props": {
			"brightness": ["brightness", "BRT"],
			"contrast": ["contrast", "CT"],
			"saturation": ["saturation", "SAT"],
			"hue": ["hue", "H"],
		},
		"class": BlurFilter,
		"f_type": Filter.FilterType.BLUR,
	},
	
}


# -------------------------------------------------------------------
# Tiny helpers (now instance methods)
# -------------------------------------------------------------------
func _pick(dict: Dictionary, keys: Array, default_val):
	
	for k in keys: if dict.has(k): return dict[k]
	return default_val

func _parse_filters(symbol: Dictionary) -> Array[Filter]:
	
	var out: Array[Filter] = []
	
	for filter_data in FILTER_ALIASES.values():
		var node_dict = _pick(symbol, filter_data["nodes"], {})
		if node_dict.is_empty():
			continue
		
		var f = filter_data["class"].new()
		var props = filter_data["props"]
		for property in props:
			f.set(property, _pick(node_dict, props[property], 0.0))
		f.type = filter_data["f_type"]
		out.append(f)
	
	return out

func _parse_color_effect(effect: Dictionary) -> ColorTansform:
	
	var out: ColorTansform
	
	if effect.keys().has("M"):
		
		if (effect.M == "Tint" or effect.M == "T"):
			out = TintTransform.new(Color.hex(int("0x" + effect.TC.substr(1))), effect.TM)
		elif (effect.M == "CA" or effect.M == "Alpha"):
			out = AlphaTransform.new(effect.AM)
		elif (effect.M == "AD" or effect.M == "Advanced"):
			out = AdvancedTransform.new(
				Color(effect.RM, effect.GM, effect.BM, effect.AM), 
				Color(effect.RO, effect.GO, effect.BO, effect.AO)
			)
	
	return out

# -------------------------------------------------------------------
# Main parse methods
# -------------------------------------------------------------------
func parse_unoptimized(input: Dictionary) -> void:
	
	var symbol: Dictionary = input.get("SYMBOL_Instance", {})
	
	name = StringName(symbol.get("SYMBOL_name", ""))
	instance_name = StringName(symbol.get("Instance_Name", ""))
	frame = int(symbol.get("firstFrame", 0))
	filters = _parse_filters(symbol.get("filters", {}))
	color_transform = _parse_color_effect(symbol.get("color", {}))
	super(symbol.get('Matrix3D', {}))



func parse_optimized(input: Dictionary) -> void:
	
	var symbol: Dictionary = input.get("SI", {})
	
	name = StringName(symbol.get("SN", ""))
	instance_name = StringName(symbol.get("IN", ""))
	frame = int(symbol.get("FF", 0))
	filters = _parse_filters(symbol.get("F", {}))
	color_transform = _parse_color_effect(symbol.get("C", {}))
	
	# Small conversion because inheritance yucky
	var m3d: Array = symbol.get('M3D', [])
	var m3d_dict: Dictionary = {}
	for i: int in m3d.size():
		m3d_dict.set(i, m3d[i])
	super(m3d_dict)
