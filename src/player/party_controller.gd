extends Node3D
## Drives the two-lead party: owns the third-person camera rig, decides which
## character is active, switches between them ([Q]), and handles mouse-look — the
## concrete "dual switchable control" canon. Mouse-look and switching are gated by
## active play in Exploration mode, so the camera locks and the cursor frees during
## dialogue and pauses.

@export var character_paths: Array[NodePath] = []
@export var camera_pivot_path: NodePath
@export var mouse_sensitivity := 0.004
@export var follow_responsiveness := 9.0
@export var eye_height := 1.55

# --- Cinematic feel (applies in every scene using this rig) ---
@export_group("Cinematic")
## Resting field of view; a touch tight for a filmic look.
@export var base_fov := 55.0
## Field of view when moving at speed — a subtle "kick" that adds momentum.
@export var run_fov := 63.0
## How far the camera drifts ahead in the direction of travel (lower-third framing).
@export var lead_amount := 0.9
## Amplitude of the gentle hand-held sway (radians). Keep small.
@export var sway_amount := 0.004

## Emitted when control switches to another lead. Arg: that character's id.
signal active_character_changed(character_id: String)

var _characters: Array = []
var _pivot: Node3D
var _spring: SpringArm3D
var _camera: Camera3D
var _active_index := 0
var _yaw := 0.0
var _pitch := -0.24
var _spring_len := 4.4
var _sway_t := 0.0
var _lead := Vector3.ZERO
var _intro_tween: Tween


func _ready() -> void:
	PlayerInput.ensure_actions()

	_pivot = get_node(camera_pivot_path)
	_spring = _pivot.get_node_or_null("SpringArm3D")
	if _spring != null:
		_spring_len = _spring.spring_length
		_camera = _spring.get_node_or_null("Camera3D")
	if _camera != null:
		_camera.fov = base_fov

	for path in character_paths:
		_characters.append(get_node(path))
	if _characters.size() > 0:
		_set_active(0)


## A directed reveal: start high and wide over the district, then orbit down into
## the normal over-the-shoulder framing and hand control back to the player.
func play_intro() -> void:
	if _characters.is_empty() or _pivot == null:
		return
	# NOTE: we deliberately do NOT lock movement here. The camera drifts on its own,
	# but the moment the player touches a movement key the reveal ends and full control
	# snaps in — so it is impossible to get stranded by the cinematic.
	suspended = true
	var target: Node3D = _characters[_active_index]
	var focus: Vector3 = target.global_position + Vector3.UP * eye_height

	# Establishing pose: raised and swung around, looking back across the Hollow.
	_pivot.global_position = focus + Vector3(9.0, 7.0, 8.0)
	_pivot.rotation = Vector3(0.0, deg_to_rad(155.0), 0.0)
	if _spring != null:
		_spring.spring_length = 11.0
		_spring.rotation.x = -0.5

	_intro_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_intro_tween.tween_property(_pivot, "global_position", focus, 6.0)
	_intro_tween.tween_property(_pivot, "rotation:y", 0.0, 6.0)
	if _spring != null:
		_intro_tween.tween_property(_spring, "spring_length", _spring_len, 6.0)
		_intro_tween.tween_property(_spring, "rotation:x", _pitch, 6.0)
	await _intro_tween.finished
	_end_intro()


func _end_intro() -> void:
	if not suspended:
		return
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_tween = null
	_pivot.rotation.x = 0.0
	_yaw = 0.0
	_pitch = -0.24
	suspended = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _can_control():
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -1.3, 0.4)


func _process(delta: float) -> void:
	if suspended:
		# The intro reveal is playing — let the player skip it the instant they move.
		var wants_control := Input.get_vector(
			PlayerInput.MOVE_LEFT, PlayerInput.MOVE_RIGHT,
			PlayerInput.MOVE_FORWARD, PlayerInput.MOVE_BACK) != Vector2.ZERO
		if wants_control or Input.is_action_just_pressed(PlayerInput.JUMP):
			_end_intro()
		return

	# Free the cursor whenever the player isn't in direct control.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _can_control() else Input.MOUSE_MODE_VISIBLE

	if _can_control() and Input.is_action_just_pressed(PlayerInput.SWITCH_CHARACTER) and _characters.size() > 1:
		_set_active((_active_index + 1) % _characters.size())

	if _characters.is_empty():
		return

	# Smoothly follow the active character with a little lead in the travel direction,
	# so the framing anticipates movement instead of rigidly tracking the character.
	var active: Node3D = _characters[_active_index]
	var t := 1.0 - exp(-follow_responsiveness * delta)
	var vel := Vector3.ZERO
	if active is CharacterBody3D:
		vel = (active as CharacterBody3D).velocity
	var flat := Vector3(vel.x, 0.0, vel.z)
	var speed := flat.length()
	var lead_target: Vector3 = (flat / speed) * lead_amount if speed > 0.5 else Vector3.ZERO
	_lead = _lead.lerp(lead_target, 1.0 - exp(-4.0 * delta))
	var focus := active.global_position + Vector3.UP * eye_height + _lead
	_pivot.global_position = _pivot.global_position.lerp(focus, t)
	_pivot.rotation.y = _yaw
	if _spring != null:
		_spring.rotation.x = _pitch

	# Speed kicks the FOV out slightly; a gentle hand-held sway keeps it alive.
	if _camera != null:
		var target_fov := lerpf(base_fov, run_fov, clampf(speed / 7.5, 0.0, 1.0))
		_camera.fov = lerpf(_camera.fov, target_fov, 1.0 - exp(-5.0 * delta))
		_sway_t += delta * (1.0 + speed * 0.15)
		_camera.rotation = Vector3(
			sin(_sway_t * 1.1) * sway_amount,
			sin(_sway_t * 1.7) * sway_amount,
			sin(_sway_t * 0.7) * sway_amount * 0.5)


func _can_control() -> bool:
	return GameManager.state == GameState.PLAYING and GameModeManager.accepts_movement()


func _set_active(index: int) -> void:
	_active_index = index
	for i in _characters.size():
		_characters[i].is_active = i == index
		_characters[i].camera_pivot = _pivot
	active_character_changed.emit(_characters[index].character_id)
