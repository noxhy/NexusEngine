extends Node2D

@export var dialogue: Dialogue = Dialogue.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	
	$"Dialogue Display".text = dialogue.dialogue

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
