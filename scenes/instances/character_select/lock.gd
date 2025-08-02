extends Node2D

@export_enum("Idle", "Selected", "Open") var state = 0:
	set(v):
		
		state = v
		match v:
			
			1:
				
				$Lock.loop_frame = 8
				$Lock.loop_end_frame = 19
				$Lock.frame = $Lock.loop_frame
				$Lock.visible = true
				$Icon.visible = false
			
			2:
				$Lock.visible = false
				$Icon.visible = true
			
			_:
				
				$Lock.loop_frame = 0
				$Lock.loop_end_frame = 2
				$Lock.frame = $Lock.loop_frame
				$Lock.visible = true
				$Icon.visible = false

@export_color_no_alpha var color:
	set(v):
		
		color = v
		$Lock.material.set("shader_parameter/replace_color", v)

@export var icon: Texture2D:
	set(v):
		
		icon = v
		$Icon.texture = v
