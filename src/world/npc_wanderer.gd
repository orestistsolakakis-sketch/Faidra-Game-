extends "res://src/player/character_blockout.gd"
## A blockout NPC that strolls between random points inside a home region, pausing
## now and then, so the streets and parks read as lived-in rather than staged.
## Cheap by design: straight-line moves + gentle turn-to-face, no pathfinding or
## collision. Purely cosmetic life on top of the greybox (docs/ART_DIRECTION.md).

var home := Vector3.ZERO
var roam_radius := 6.0
var speed := 1.1

var _target := Vector3.ZERO
var _pause := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super._ready()
	_rng.randomize()
	home = position
	_pick_target()
	_pause = _rng.randf_range(0.0, 3.0)


func _pick_target() -> void:
	var a := _rng.randf() * TAU
	var r := sqrt(_rng.randf()) * roam_radius
	_target = home + Vector3(cos(a) * r, 0.0, sin(a) * r)


func _process(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		return
	var to := _target - position
	to.y = 0.0
	var dist := to.length()
	if dist < 0.2:
		_pause = _rng.randf_range(1.5, 5.0)
		_pick_target()
		return
	var dir := to / dist
	position += dir * speed * delta
	# The blockout faces -Z; turn that toward the direction of travel.
	var yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, minf(1.0, delta * 6.0))
