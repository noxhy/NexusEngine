@icon("uid://ca6uggp4ff1q2")
@tool
extends Node
## The main class for characters in a song, such as the player, enemy, or metronome.
class_name Character

## When calling an animation, it is important to also call context with it:
enum AnimContext {
	## Sing poses (ex: left, down, up, right)
	SING,
	## Idle animations
	DANCE,
	## Will not play any other animations until the context is manually set otherwise.
	LOCKED,
	## Will not play any animation until the sing timer is over unless the context is special.
	SPECIAL,
	## Default context, no functionality
	NONE
}

##The actual sprite node that will be used to play the anims. If not assigned, it will fallback to
##[AnimatedSprite2D] or [AnimateSymbol]
@export var animation_player: Node = null:
	set(v):
		animation_player = verify_animation_player(v)
		update_configuration_warnings()
		
		update_ghost()

@export_group("Animation Data")
## Dictionary of given animation id's and their [SpriteFrames] animation.
## [br][br][b]Example:[/b] [code]{"idle": "BF idle dance"}[/code]
@export var animation_names: Dictionary[StringName, StringName] = {}:
	set(v):
		animation_names = v
		update_ghost()

@export var offsets: Dictionary[StringName, Vector2] = {}:
	set(v):
		offsets = v
		update_ghost()

@export var hold_frames: Dictionary[StringName, int] = {}:
	set(v):
		hold_frames = v
		update_ghost()

@export_group("Gameplay")
## The idle animations. Whenever the character "dance's" they will cycle through this list.
@export var dance_animations: Array[StringName] = [&"idle"]:
	set(v):
		dance_animations = v
		update_ghost()
## How often [b](in steps)[/b] the dance will be played.
@export_range(1, 1, 1, "suffix:steps", "or_greater") var dance_rate: int = 8
## When calling an animation, the id will be appended to this value.
## [br][br][b]Example:[/b] [code]"left"[/code] → [code]"mom_left"[/code]
@export var animation_prefix: StringName = &"":
	set(v):
		animation_prefix = v
		update_ghost()
## How many steps an animation can play before being able to revert to idle.
@export_custom(PROPERTY_HINT_NONE, 'suffix:steps') var sing_duration: float = 6



@export_group("UI")
## Icons that are displayed in the ui. Can include [code]default[/code], [code]winning[/code] or [code]losing[/code].
@export var icons: SpriteFrames
@export var color: Color = Color(0.168627, 0.121569, 0.203922)

@export_category("Tools")
@warning_ignore("unused_private_class_variable")
@export_tool_button("Save Offset", "Save") var _save_button: Callable = self._save_offset
@warning_ignore("unused_private_class_variable")
@export_tool_button("Reset Position", "UndoRedo") var _reset_button: Callable = self._reset_position
@export_enum("Back", "Front") var _ghost_ordering: int = 0:
	set(v):
		_ghost_ordering = v
		update_ghost()

var current_dance: int = 0
## The current animation ID.
var current_animation: StringName = dance_animations[0]
## The current [enum AnimContext]
var current_context: AnimContext = AnimContext.NONE
var can_dance: bool = true
## Used to make an animation loop at the given [code]hold_frame[/code] until given another animation.
var holding: bool = false
## Time elapsed since the char has started singing
var sing_time: float = 0

var _ghost_sprite = null

func _ready() -> void:
	animation_player = verify_animation_player(animation_player)
	
	if not animation_player:
		printerr("Character animation player was not set and could not be found.")
		return
	
	if animation_player is AnimateSymbol:
		animation_player.connect(&"animation_finished", self._on_animation_finished)
		if Engine.is_editor_hint():
			animation_player.connect(&"animation_changed", self.update_ghost)
	else:
		animation_player.connect(&"animation_finished", self._on_animation_finished)
		if Engine.is_editor_hint() and not animation_player is AnimationPlayer:
			animation_player.connect(&"animation_changed", self.update_ghost)
	
	if not Engine.is_editor_hint():
		Signals.play_conductor_step_hit.connect(on_step_hit)
	
	dance()


func _on_animation_finished():
	holding = true

## Plays an animation with the given context. Setting [param restart] to [code]true[/code] will replay the animation from the beginning.
## Setting a [param time] will make the animation play within the given time.
## [br][br]See [enum AnimContext] for information of animation contexts.
func play_animation(anim_id: StringName = &"", context: AnimContext = AnimContext.NONE, restart: bool = true, time: float = -1.0):
	if process_mode == Node.PROCESS_MODE_DISABLED or current_context == AnimContext.LOCKED or !animation_player:
		return
	
	anim_id = StringName(animation_prefix + anim_id)
	var animation_name: StringName = get_animation_name(anim_id)
	
	if animation_player is AnimationPlayer and not animation_player.has_animation(anim_id):
		printerr("(Character[", self.name, "]) ",'does not have "', anim_id, '" animation')
		return
	elif animation_name.is_empty():
		printerr("(Character[", self.name, "]) ",'does not have "', anim_id, '" animation')
		return
	
	if context != AnimContext.SPECIAL and current_context == AnimContext.SPECIAL and !holding:
		return
	
	current_animation = anim_id
	current_context = context
	
#region AnimationPlayer Anim playback
	if animation_player is AnimationPlayer: #for anim players we have to ignore a few things
			
		animation_player.play(anim_id)
		if restart:
			animation_player.seek(0, true)
		
		var current_anim = animation_player.get_animation(anim_id)
		
		set_sing_timer(current_anim.length)
		return
#endregion
	
	# Will not run idle animation if you can not run
#region Atlas Anim playback
	if animation_player is AnimateSymbol:
		if offsets.has(animation_name):
			animation_player.position = offsets.get(animation_name, animation_player.offset)
		
		animation_player.symbol = animation_name
		if restart:
			animation_player.frame = 0
		
		animation_player.playing = true
		holding = false
		
		var raw_atlas = animation_player.get_atlas()
		if not raw_atlas:
			return
		
		set_sing_timer(animation_player.get_animation_length() / raw_atlas.get_framerate())
		return
#endregion
	
#region AnimatedSprite Anim playback
	var animation_speed: float = animation_player.sprite_frames.get_animation_speed(animation_name)
	var frame_count: int = animation_player.sprite_frames.get_frame_count(animation_name)
	holding = false
	
	if time >= 0:
		# Calculates the speed it would need to go at the time requested
		animation_player.play(animation_name, animation_speed / (frame_count * time))
		set_sing_timer(time)
	else:
		animation_player.play(animation_name, 1)
		set_sing_timer(frame_count / animation_speed)
	
	if restart:
		animation_player.set_frame_and_progress(0, 0)
	
	if offsets.has(animation_name):
		var offsets_to_use = offsets[animation_name]
		
		if animation_player is AnimatedSprite3D:
			animation_player.offset.x = offsets_to_use.x
			animation_player.offset.y = -offsets_to_use.y
		else:
			animation_player.position.x = offsets_to_use.x
			animation_player.position.y = offsets_to_use.y
#endregion


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_editor_process(delta)
	else:
		if holding:
			hold_animation()
		
		sing_time -= delta
		if sing_time <= 0 and !can_dance:
			can_dance = true

## Gets the [SpriteFrames] animation name of the given [param anim_id] in [member animation_names].
func get_animation_name(anim_id: StringName = &""):
	return animation_names.get(anim_id, &"")


func set_prefix(prefix: StringName):
	animation_prefix = prefix

## Lets an animation loop at the given [code]hold_frame[/code] until given another animation.
func hold_animation():
	if !animation_player: return
	
	if animation_player is AnimationPlayer: ##TODO implement this
		return
	
	var hold_frame: int = 0
	var animation_name: StringName = get_animation_name(current_animation)
	var length: int
	
	if animation_name.is_empty():
		return
	
	if animation_player is AnimateSymbol:
		if animation_player.loop:
			return
		
		length = animation_player.get_animation_length()
		hold_frame = hold_frames.get(animation_name, length - 1)
		
		if (animation_player.frame == length - 1 and animation_player.frame_progress >= 1):
			animation_player.frame = hold_frame
		
		animation_player.playing = true
	else:
		if animation_player.sprite_frames.get_animation_loop_mode(animation_name) != SpriteFrames.LoopMode.LOOP_NONE:
			return
		
		length = animation_player.sprite_frames.get_frame_count(animation_name)
		hold_frame = hold_frames.get(animation_name, length - 1)
		
		if animation_player.frame == length - 1 and animation_player.frame_progress == 1:
			animation_player.frame = hold_frame
		
		animation_player.play()

## Play the current idle animation.
func dance(restart: bool = true, time: float = -1) -> void:
	if !can_dance and !dance_animations.has(current_animation):
		return
	
	var dance_to_play: StringName = dance_animations[current_dance]
	play_animation(dance_to_play, AnimContext.DANCE, restart, time)
	
	current_dance = wrapi(current_dance + 1, 0, dance_animations.size())

## Sets the sing timer, characters cannot return to idle until this timer is finished.
func set_sing_timer(time: float = -1):
	if time == -1:
		time = sing_duration * GameManager.seconds_per_step
	
	sing_time = time
	can_dance = false

## Helper function for [code]basic_song.gd[/code] to call idle whenever possible
func on_step_hit(current_step: int, measure_relative: int):  
	if dance_rate > 0 and measure_relative % dance_rate == 0:
		var restart: bool = true
		var dance_to_play: StringName = get_animation_name(dance_animations[current_dance])
		
		if animation_player is AnimationPlayer:
			if animation_player.has_animation(animation_player.current_animation):
				restart = animation_player.get_animation(animation_player.current_animation).loop_mode != Animation.LOOP_LINEAR
		elif animation_player is AnimateSymbol:
			restart = !animation_player.loop
		else:
			restart = !animation_player.sprite_frames.get_animation_loop(dance_to_play)
		
		dance(restart)

#region Tool funcs
func _editor_process(delta: float) -> void:
	var is_player_added = animation_player != null
	if is_player_added:
		is_player_added = animation_player.get_parent() != null
	
	if not is_player_added and _ghost_sprite:
		_cleanup_ghost()

func _is_character_root():
	if not is_inside_tree():
		return false
		
	var tree = get_tree()
	return tree and tree.edited_scene_root == self

func _cleanup_ghost():
	if _ghost_sprite:
		remove_child(_ghost_sprite)
		_ghost_sprite.queue_free()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if !animation_player:
		warnings.append("Please assign an animation player to this node")
	
	return warnings

## [b]Tool Script[/b] - Used for offsetring.
## [br][br]Updates the position and texture of the ghost sprite. 
func update_ghost():
	if !Engine.is_editor_hint() or not _is_character_root():
		return
	
	_cleanup_ghost()
	
	if animation_player:
		if animation_player is AnimatedSprite2D:
			_ghost_sprite = Sprite2D.new()
			
			if animation_player.sprite_frames:
				if dance_animations.size() > 0:
					var animation_name: StringName = get_animation_name(dance_animations[0])
					_ghost_sprite.texture = animation_player.sprite_frames.get_frame_texture(
						animation_name, animation_player.sprite_frames.get_frame_count(animation_name) - 1)
					_ghost_sprite.offset = offsets.get(animation_name, Vector2.ZERO)
			
			_ghost_sprite.modulate = Color(1.825, 1.825, 1.825, 0.5)
			_ghost_sprite.z_index = animation_player.z_index
			_ghost_sprite.texture_filter = animation_player.texture_filter
		elif animation_player is AnimateSymbol:
			_ghost_sprite = AnimateSymbol.new()
			_ghost_sprite.atlases = animation_player.atlases
			
			if dance_animations.size() > 0:
				var animation_name: StringName = get_animation_name(dance_animations[0])
				_ghost_sprite.symbol = animation_name
				_ghost_sprite.frame = _ghost_sprite.get_animation_length() - 1
				_ghost_sprite.offset = offsets.get(animation_name, Vector2.ZERO)
			
			_ghost_sprite.modulate = Color(1.825, 1.825, 1.825, 0.5)
			_ghost_sprite.z_index = animation_player.z_index
			_ghost_sprite.texture_filter = animation_player.texture_filter
		
		match _ghost_ordering:
			0:
				_ghost_sprite.z_index -= 1
			
			1:
				_ghost_sprite.z_index += 1
		
		self.add_child(_ghost_sprite)

## [b]Tool Script[/b] - Used for offsetring.
## [br][br]Resets the current sprite back to the corresponding offset.
func _reset_position():
	if !Engine.is_editor_hint():
		return
		
	if animation_player:
		if animation_player is AnimatedSprite2D:
			var undo_redo = __get_editor_undo_redo()
			undo_redo.create_action("Reset Position")
			undo_redo.add_do_property(animation_player, &"position", offsets.get(animation_player.animation, Vector2.ZERO))
			undo_redo.add_undo_property(animation_player, &"position", animation_player.position)
			undo_redo.commit_action()
		elif animation_player is AnimateSymbol:
			var undo_redo = __get_editor_undo_redo()
			undo_redo.create_action("Reset Position")
			undo_redo.add_do_property(animation_player, &"position", offsets.get(animation_player.symbol, Vector2.ZERO))
			undo_redo.add_undo_property(animation_player, &"position", animation_player.position)
			undo_redo.commit_action()


## [b]Tool Script[/b] - Used for offsetring.
## [br][br]Saves the offset into the [member offsets] dictionary.
func _save_offset():
	if !Engine.is_editor_hint():
		return
	
	if animation_player:
		if animation_player is AnimatedSprite2D or animation_player is AnimatedSprite3D:
			var undo_redo = __get_editor_undo_redo()
			undo_redo.create_action("Save Offset")
			var temp: Dictionary[StringName, Vector2] = offsets.duplicate(true)
			temp[animation_player.animation] = animation_player.position
			undo_redo.add_do_property(self, &"offsets", temp)
			undo_redo.add_undo_property(self, &"offsets", self.offsets)
			undo_redo.commit_action()
		elif animation_player is AnimateSymbol:
			var undo_redo = __get_editor_undo_redo()
			undo_redo.create_action("Save Offset")
			var temp: Dictionary[StringName, Vector2] = offsets.duplicate(true)
			temp[animation_player.symbol] = animation_player.position
			undo_redo.add_do_property(self, &"offsets", temp)
			undo_redo.add_undo_property(self, &"offsets", self.offsets)
			undo_redo.commit_action()

## helper function to get the editors undo and redo.
## only works in editor dont use this elsewhere
func __get_editor_undo_redo() -> Object:
	var ei: Object = Engine.get_singleton(&"EditorInterface")
	if not ei:
		return null
	var undo_redo: Object = ei.get_editor_undo_redo()
	return undo_redo

func verify_animation_player(node: Node):
	if !node:
		node = $AnimatedSprite2D
		if !node:
			node = $AnimateSymbol
			if !node:
				node = $AnimationPlayer
	
	return node
#endregion
