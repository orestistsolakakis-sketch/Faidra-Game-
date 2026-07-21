class_name PlayerInput
## Registers gameplay input actions in code (physical keycodes, so bindings follow
## key position across layouts). Called once by the party controller; idempotent.
## A real rebinding UI will later edit these same actions.

const MOVE_FORWARD := "move_forward"
const MOVE_BACK := "move_back"
const MOVE_LEFT := "move_left"
const MOVE_RIGHT := "move_right"
const RUN := "run"
const JUMP := "jump"
const INTERACT := "interact"
const SWITCH_CHARACTER := "switch_character"

static var _registered := false


static func ensure_actions() -> void:
	if _registered:
		return
	_registered = true

	_bind(MOVE_FORWARD, [KEY_W, KEY_UP])
	_bind(MOVE_BACK, [KEY_S, KEY_DOWN])
	_bind(MOVE_LEFT, [KEY_A, KEY_LEFT])
	_bind(MOVE_RIGHT, [KEY_D, KEY_RIGHT])
	_bind(RUN, [KEY_SHIFT])
	_bind(JUMP, [KEY_SPACE])
	_bind(INTERACT, [KEY_E])
	_bind(SWITCH_CHARACTER, [KEY_Q])


static func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
