extends Node2D
class_name OptionsSubmenu

var BOOL_PRELOAD = load("uid://uj644hsg8thl")
var NUMBER_PRELOAD = load("uid://77c763qfjduu")
var KEYBIND_PRELOAD = load("uid://cx81a4x2e26yh")
var LABEL_PRELOAD = load("uid://7leho7yp6nrt")
var BUTTON_PRELOAD = load("uid://oi2cyiu5cgsq")

const HOLD_THRESHOLD = 0.5
const HOLD_RATE = 50

@export var box_limit: float = 320

var selected: int = 0
var old_selected: int
var elapsed: float

func _process(delta: float) -> void:
	if get_viewport().gui_get_focus_owner():
		if Input.is_action_just_pressed(&"menu_cancel") or Input.is_action_just_pressed(&'mouse_right'):
			get_viewport().gui_release_focus()
	
	if Input.is_action_just_pressed(&"menu_cancel"):
		SoundManager.cancel.play()
		get_tree().paused = false
		self.queue_free()
	
	if Input.is_action_just_pressed(&"menu_up"):
		if get_selected_node() is KeyBindOptionNode:
			old_selected = get_selected_node().selected
		update(selected - 1)
		if get_selected_node() is KeyBindOptionNode:
			get_selected_node().select_button(old_selected)
	
	if Input.is_action_just_pressed(&"menu_down"):
		if get_selected_node() is KeyBindOptionNode:
			old_selected = get_selected_node().selected
		update(selected + 1)
		if get_selected_node() is KeyBindOptionNode:
			get_selected_node().select_button(old_selected)
	
	if (Input.is_action_just_pressed(&"menu_accept")
	or Input.is_action_just_pressed(&"menu_left")
	or Input.is_action_just_pressed(&"menu_right")):
		if get_selected_node() is BoolOptionNode:
			var button: Button = get_selected_node().get_node("%Button")
			button.button_pressed = !button.button_pressed
	
	if Input.is_action_just_pressed(&"menu_accept"):
		if get_selected_node() is KeyBindOptionNode:
			get_selected_node().buttons[get_selected_node().selected]._on_toggled(true)
			get_selected_node().buttons[get_selected_node().selected].button_pressed = true
		elif get_selected_node() is ButtonOptionNode:
			get_selected_node().button.emit_signal(&"pressed")
	
	if Input.is_action_just_pressed(&"menu_left"):
		if get_selected_node() is NumberOptionNode:
			var spin_box: SpinBox = get_selected_node().spin_box
			spin_box.value -= spin_box.step * 5 if Input.is_action_pressed(&"shift") else spin_box.step
		elif get_selected_node() is KeyBindOptionNode:
			get_selected_node().selected = get_selected_node().selected - 1
			get_selected_node().select_button(get_selected_node().selected)
			# get_tree().call_group("buttons", "normal")
	
	if Input.is_action_just_pressed(&"menu_right"):
		if get_selected_node() is NumberOptionNode:
			var spin_box: SpinBox = get_selected_node().spin_box
			spin_box.value += spin_box.step * 5 if Input.is_action_pressed(&"shift") else spin_box.step
		elif get_selected_node() is KeyBindOptionNode:
			get_selected_node().selected = get_selected_node().selected + 1
			get_selected_node().select_button(get_selected_node().selected)
	
	if Input.is_action_pressed(&"menu_left") or Input.is_action_pressed(&"menu_right"):
		elapsed += delta
		if elapsed >= HOLD_THRESHOLD:
			if get_selected_node() is NumberOptionNode:
				var spin_box: SpinBox = get_selected_node().spin_box
				spin_box.value += spin_box.step * -1 if Input.is_action_pressed(&"menu_left") else spin_box.step
	
	if Input.is_action_just_released(&"menu_left") or Input.is_action_just_released(&"menu_right"):
		elapsed = 0
	
	if Input.is_action_just_pressed(&"mouse_scroll_up"):
		if %Options.size.y > box_limit:
			var tween = create_tween()
			tween.set_parallel(true)
			tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			tween.tween_property(%Options, "position",
			Vector2(%Options.position.x, min(64.0, %Options.position.y + 60)), 0.2)
	
	if Input.is_action_just_pressed(&"mouse_scroll_down"):
		if %Options.size.y > box_limit:
			var tween = create_tween()
			tween.set_parallel(true)
			tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			tween.tween_property(%Options, "position",
			Vector2(%Options.position.x, max(64.0 - (%Options.size.y - box_limit), %Options.position.y - 60)), 0.2)

func load_category(category: String, options: Array):
	get_tree().call_group(&"options", &"queue_free")
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	var instance;
	
	for i in options.size():
		var packet = options[i]
		var type: StringName = packet[0]
		var data = packet[1]
		var option_name: String;
		var description: String = ""
		
		if type == &"option":
			option_name = data["id"]
			# No botplay for people without a debug build
			if option_name == "botplay":
				if !OS.is_debug_build():
					continue
			
			var option = SettingsManager._defaults.get(category).get(option_name)
			if (option is float) or (option is int):
				instance = NUMBER_PRELOAD.instantiate()
				instance.minimum = data.get("min", 0)
				instance.maximum = data.get("max", 100)
				instance.step = data.get("snap", 1)
				instance.value_name = data.get("unit", "")
				instance.value_scale = data.get("scale", 1)
			elif (option is bool):
				instance = BOOL_PRELOAD.instantiate()
			elif (category == SettingsManager.SEC_KEY_BINDS):
				instance = KEYBIND_PRELOAD.instantiate()
			elif (category == SettingsManager.SEC_CONTROLLER_BINDS):
				instance = KEYBIND_PRELOAD.instantiate()
				instance.type = 1
			else:
				printerr("Not a valid option type: ", option.get_class())
			
			instance.display_name = option_name.capitalize()
			description = data.get("description", "")
		elif type == &"label":
			instance = LABEL_PRELOAD.instantiate()
			instance.display_name = data
		elif type == &"button":
			instance = BUTTON_PRELOAD.instantiate()
			instance.display_name = data["text"]
		else:
			printerr("Unknown type: ", type)
		
		instance.setting_category = category
		instance.setting_name = option_name
		instance.description = description
		
		%Options.add_child(instance)
		instance.add_to_group(&"options")
		if instance is ButtonOptionNode:
			instance.button.connect(&"pressed", self.pressed_button.bind(data["id"]))
		
		instance.modulate.a = 0
		instance.connect("mouse_entered", self.update.bind(i, true))
		
		tween.tween_method(instance.set_offset_left, 200, 0, 1).set_delay(i * 0.025)
		tween.tween_property(instance, "modulate", Color.WHITE, 1).set_delay(i * 0.025)
	
	update(0)

func _exit_tree() -> void:
	SettingsManager.flush()

func update(i: int, mouse: bool = false):
	var options = get_tree().get_nodes_in_group(&"options")
	selected = wrapi(i, 0, options.size())
	get_tree().call_group(&"options", &"normal")
	get_selected_node().select()
	
	SoundManager.scroll.play()
	get_viewport().gui_release_focus()
	
	set_description(get_selected_node().description)
	
	if !mouse:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		if get_selected_node().position.y >= box_limit:
			tween.tween_property(%Options, "position:y",
			-(get_selected_node().position.y - box_limit) + 64, 0.2)
		else:
			tween.tween_property(%Options, "position:y", 64, 0.2)

func get_selected_node() -> Node:
	var options = get_tree().get_nodes_in_group(&"options")
	return options[selected]

func set_description(text: String = ""):
	%Description.text = text

func pressed_button(id: StringName):
	match id:
		&"offset":
			Global.change_scene_to("uid://cw85perbwjqqy")
			SoundManager.accept.play()
			SoundManager.music.stop()
		
		&"clear_save":
			SaveManager.instance = Save.new()
			SaveManager.flush()
			SoundManager.accept.play()
		
		_:
			printerr("No function assigned to: ", id)
