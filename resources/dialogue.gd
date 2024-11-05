@icon( "res://assets/sprites/nodes/dialogue.png" )

extends Resource
class_name Dialogue

@export_multiline var dialogue: String

# Dialogue resource that holds dialogue linds and functions.
# Supports function calls, all paramters are strings and separated by commas.
# 
# Formats:
#
# Dialogue Line - <character_name>: <dialogue_line>
# Function - func <function_name> <function_paramaters>
