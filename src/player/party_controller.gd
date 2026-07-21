extends Node3D
## Drives the two-lead party: owns the third-person camera rig, decides which
## character is active, switches between them ([Q]), and handles mouse-look — the
## concrete "dual switchable control" canon. Mouse-look and switching are gated by
## active play in Exploration mode, so the camera locks and the cursor frees during
## dialogue and pauses.

@export var character_paths: Array[NodePath] = []
@export var camera_pivot_path: NodePath
@export var mouse_sensitivity := 0.004
@export var follow_responsiveness := 12.0
@export var eye_height := 1.4

## Emitted when control switches to another lead. Arg: that character's id.
signal active_character_changed(character_id: String)

var _characters: Array = []
var _pivot: Node3D
var _spring: SpringArm3D
var _active_index := 0
var _yaw := 0.0
var _pitch := -0.3


func _ready() -> void:
	PlayerInput.ensure_actions()

	_pivot = get_node(camera_pivot_path)
	_spring = _pivot.get_node_or_null("SpringArm3D")

	for path in character_paths:
		_characters.append(get_node(path))
	if _characters.size() > 0:
		_set_active(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _can_control():
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -1.3, 0.4)


func _process(delta: float) -> void:
	# Free the cursor whenever the player isn't in direct control.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _can_control() else Input.MOUSE_MODE_VISIBLE

	if _can_control() and Input.is_action_just_pressed(PlayerInput.SWITCH_CHARACTER) and _characters.size() > 1:
		_set_active((_active_index + 1) % _characters.size())

	if _characters.is_empty():
		return

	# Smoothly follow the active character and apply look rotation.
	var active: Node3D = _characters[_active_index]
	var t := 1.0 - exp(-follow_responsiveness * delta)
	_pivot.global_position = _pivot.global_position.lerp(active.global_position + Vector3.UP * eye_height, t)
	_pivot.rotation.y = _yaw
	if _spring != null:
		_spring.rotation.x = _pitch


func _can_control() -> bool:
	return GameManager.state == GameState.PLAYING and GameModeManager.accepts_movement()


func _set_active(index: int) -> void:
	_active_index = index
	for i in _characters.size():
		_characters[i].is_active = i == index
		_characters[i].camera_pivot = _pivot
	active_character_changed.emit(_characters[index].character_id)
