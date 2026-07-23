extends Node3D
## Controller for the worker's home. Environmental-storytelling interactions (photos,
## a letter, a toy), the resident Marta (whose lines shift once it's warm), and the
## one small thing Arlen can put right — the dead heater.

var _hud: CanvasLayer
var _env: Node3D
var _active_interactables: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hud = get_node("%Hud")
	_env = get_node("Environment")

	var party := get_node("PartyController")
	party.active_character_changed.connect(func(_id): _hud.set_solo_lead("Arlen"))
	_hud.set_solo_lead("Arlen")

	for node in get_tree().get_nodes_in_group("interactable"):
		node.entered.connect(_on_interactable_entered)
		node.exited.connect(_on_interactable_exited)

	_hud.set_objective("Someone lives here. Look around.")
	_hud.show_title("A WORKER'S HOME", "Two rooms and a cold stove. Somebody's whole life.")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_ESCAPE:
			GameManager.toggle_pause()
		KEY_E:
			_try_interact()


func _try_interact() -> void:
	if _active_interactables.is_empty() or _hud.is_dialogue_active():
		return
	var which: Node = _active_interactables.back()
	match which.id:
		"home_exit":
			SceneLoader.transition_to("res://scenes/World/CinderHollow.tscn", GameState.PLAYING)
		"home_heater":
			_repair_heater()
		"home_marta":
			_talk_marta()
		"home_photos":
			_hud.push_toast("", "A wall of faces. A younger her, a man in a foundry apron, three children. Only some of them are in the newer photographs.")
		"home_letter":
			_hud.push_toast("", "\"...they moved his shift to the upper works, so it's the lift or nothing, and the lift is never running. Tell the little one her father will be late again. — E.\"")
		"home_toy":
			_hud.push_toast("", "A carved wooden lift, cage and all. The winder still turns. Someone made this by hand for a child who wanted the real one to work.")
		_:
			_hud.push_toast("", "Nothing to disturb.")
	_update_prompt()


func _repair_heater() -> void:
	if World.state.get_flag(WorldFacts.Flags.CINDER_HOME_HEATER_FIXED):
		_hud.push_toast("", "The heater ticks with warmth now. The cold has gone out of the room.")
		return
	World.state.set_flag(WorldFacts.Flags.CINDER_HOME_HEATER_FIXED, true)
	if _env.has_method("set_heater_running"):
		_env.set_heater_running(true)
	if World.traits != null:
		World.traits.adjust(Traits.COMPASSION, 6)
	_hud.push_toast("WORLD UPDATED", "You find the cracked coil and coax it back. The iron flushes orange; heat rolls off it. Marta stops rubbing her hands.")
	_hud.set_objective("Warmth, for the cost of a few minutes. Some things you can just fix.")


func _talk_marta() -> void:
	if World.state.get_flag(WorldFacts.Flags.CINDER_HOME_HEATER_FIXED):
		_hud.push_toast("MARTA", "\"Bless you. The children can take their coats off for once. You didn't have to — but you did. I won't forget it.\"")
	else:
		_hud.push_toast("MARTA", "\"Mind the cold, love. Heater's been dead a week and the landlord won't send anyone. We manage. We always manage. ...You're handy with machines, they say?\"")


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
