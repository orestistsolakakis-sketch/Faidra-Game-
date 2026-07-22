extends Node3D
## Controller for the underground rail level. Minimal: title card, single-lead
## setup, the interaction loop, and a way back up to Cinder Hollow.

var _hud: CanvasLayer
var _active_interactables: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hud = get_node("%Hud")

	var party := get_node("PartyController")
	party.active_character_changed.connect(func(_id): _hud.set_solo_lead("Arlen"))
	_hud.set_solo_lead("Arlen")

	for node in get_tree().get_nodes_in_group("interactable"):
		node.entered.connect(_on_interactable_entered)
		node.exited.connect(_on_interactable_exited)

	_hud.set_objective("Follow the rails into the Drain Sector.")
	_hud.show_title("THE DRAIN SECTOR", "Beneath Cinder Hollow — where the rails run into the dark.")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_ESCAPE:
			GameManager.toggle_pause()
		KEY_BACKSPACE:
			SceneLoader.transition_to("res://scenes/UI/MainMenu.tscn", GameState.MAIN_MENU)
		KEY_E:
			_try_interact()


func _try_interact() -> void:
	if _active_interactables.is_empty() or _hud.is_dialogue_active():
		return
	var which: Node = _active_interactables.back()
	match which.id:
		"stairs_up":
			SceneLoader.transition_to("res://scenes/World/CinderHollow.tscn", GameState.PLAYING)
		"rail_car":
			_hud.push_toast("", "A dead rail car. The controls are cold — no power reaching them from anywhere.")
		_:
			_hud.push_toast("", "Nothing here but rust and dark.")
	_update_prompt()


func _on_interactable_entered(which: Node) -> void:
	if not _active_interactables.has(which):
		_active_interactables.append(which)
	_update_prompt()


func _on_interactable_exited(which: Node) -> void:
	_active_interactables.erase(which)
	_update_prompt()


func _update_prompt() -> void:
	if _active_interactables.is_empty() or _hud.is_dialogue_active():
		_hud.hide_interaction()
		return
	var current: Node = _active_interactables.back()
	_hud.show_interaction(current.label, current.verb)
