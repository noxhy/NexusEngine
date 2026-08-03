@icon("uid://c1o5a7jg5bf85")
@abstract
class_name Note extends Node2D

var length: float = 0.0

var time: float = 0.0
var note_skin: NoteSkin
var lane: int = 0
var tempo: float = 0
var note_type: String

var scroll_speed: float
var grid_size: Vector2 = Vector2(128, 128)

var scroll: float = 1.0

var direction: String = "left"
var animation: StringName = &"left"
