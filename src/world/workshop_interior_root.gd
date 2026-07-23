extends Node3D
## Controller for Arlen's workshop interior: the interaction loop, Arlen's first
## repair (the dead machine), a little flavour, and the door back to the street.

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

	if World.state.get_flag(WorldFacts.Flags.CINDER_WORKSHOP_MACHINE_FIXED):
		_hud.set_objective("Head back out to the street.")
	else:
		_hud.set_objective("Something in here is broken. Find what you can fix.")
	_hud.show_title("THE WORKSHOP", "Home, of a sort. Everything in here has been mended a dozen times.")


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
		"workshop_exit":
			SceneLoader.transition_to("res://scenes/World/CinderHollow.tscn", GameState.PLAYING)
		"workshop_machine":
			_repair_machine()
		"workshop_bench":
			_hud.push_toast("", "Tools laid out just how she likes them. A half-finished gearbox waits.")
		"workshop_diagram":
			_hud.push_toast("", "Schematics in her father's hand. She still can't read half the notations.")
		_:
			_hud.push_toast("", "Just parts and dust.")
	_update_prompt()


func _repair_machine() -> void:
	if World.state.get_flag(WorldFacts.Flags.CINDER_WORKSHOP_MACHINE_FIXED):
		_hud.push_toast("", "It hums steadily now. Warm to the touch.")
		return
	World.state.set_flag(WorldFacts.Flags.CINDER_WORKSHOP_MACHINE_FIXED, true)
	World.state.set_flag(WorldFacts.Flags.SENSE_AWAKENED, true)
	if _env.has_method("set_machine_running"):
		_env.set_machine_running(true)
	# Arlen's power: a small step toward Insight for reading what was wrong.
	if World.traits != null:
		World.traits.adjust(Traits.INSIGHT, 6)
	_hud.push_toast("WORLD UPDATED", "You find the break — a snapped lifeline, not a snapped part. You mend it, and the core lights teal. It remembers how to run.")
	_hud.set_objective("Head back out to the street.")


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
