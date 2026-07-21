extends CharacterBody3D
## A playable lead (Arlen or Lysandra). Camera-relative third-person movement in
## the physics step, but ONLY when it is the active character AND the game is in
## GameMode.EXPLORATION — so control freezes during dialogue/cutscenes without this
## script knowing anything about them. That gate is the payoff of the GameMode layer.

@export var character_id: String = ""
@export var walk_speed := 4.5
@export var run_speed := 7.5
@export var jump_velocity := 5.0
@export var responsiveness := 12.0  # higher = snappier accel and turning

var is_active := false
var camera_pivot: Node3D  # set each frame by the party controller

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	var v := velocity

	if not is_on_floor():
		v.y -= _gravity * delta

	var controllable := is_active and GameModeManager.accepts_movement()
	var direction := _read_move_direction() if controllable else Vector3.ZERO
	var speed := run_speed if controllable and Input.is_action_pressed(PlayerInput.RUN) else walk_speed

	# Smoothly approach the target horizontal velocity (frame-rate independent).
	var t := 1.0 - exp(-responsiveness * delta)
	var horizontal := Vector3(v.x, 0.0, v.z).lerp(direction * speed, t)
	v.x = horizontal.x
	v.z = horizontal.z

	if controllable and Input.is_action_just_pressed(PlayerInput.JUMP) and is_on_floor():
		v.y = jump_velocity

	velocity = v
	move_and_slide()

	# Face the direction of travel.
	if direction.length_squared() > 0.001:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, t)


func _read_move_direction() -> Vector3:
	var input := Input.get_vector(
		PlayerInput.MOVE_LEFT, PlayerInput.MOVE_RIGHT, PlayerInput.MOVE_FORWARD, PlayerInput.MOVE_BACK)
	if input == Vector2.ZERO or camera_pivot == null:
		return Vector3.ZERO
	# Rotate raw input by the camera's yaw so "forward" tracks the camera.
	var basis := Basis(Vector3.UP, camera_pivot.global_rotation.y)
	return (basis * Vector3(input.x, 0.0, input.y)).normalized()
