extends Node3D
## Rotates its children continuously — for fans, gears, turbines. Pure ambient
## motion so the district reads as alive (docs/levels/CINDER_HOLLOW_ENVIRONMENT.md).

@export var speed := 2.0          # radians/second
@export var spin_axis := Vector3(0, 0, 1)


func _process(delta: float) -> void:
	rotate(spin_axis.normalized(), speed * delta)
