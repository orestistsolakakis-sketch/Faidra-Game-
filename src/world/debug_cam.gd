extends Camera3D
## TEMPORARY diagnostic: a fixed camera that hard-looks at the spawn area, bypassing
## the third-person spring-arm rig. If the town/cube render through THIS camera but
## not the normal one, the camera rig is the problem, not 3D rendering. Removed once
## the render issue is understood.


func _ready() -> void:
	# Win the "current camera" race against the rig's camera.
	current = true
	global_position = Vector3(0.0, 6.0, 18.0)
	look_at(Vector3(0.0, 1.0, 2.0), Vector3.UP)
	call_deferred("_force_current")


func _force_current() -> void:
	current = true
