extends Node3D
## Controller for the hospital interior. The interaction loop; the reception, pharmacy
## and records flavour; and the pivot of the whole level — Arlen's first healing of a
## person, which awakens her power a step further and teaches her it takes something
## out of her.

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

	_hud.set_objective("The Hollow's hospital. Old, underfunded, still open. Look around.")
	_hud.show_title("THE HOSPITAL", "Abandoned by the palace decades ago. It keeps its doors open on stubbornness alone.")


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
		"hospital_exit":
			SceneLoader.transition_to("res://scenes/World/CinderHollow.tscn", GameState.PLAYING)
		"hospital_worker":
			_heal_worker()
		"hospital_records":
			_read_records()
		"hospital_pharmacy":
			_hud.push_toast("APOTHECARY", "\"Half these shelves are gaps. Palace cut the supply line years back. We ration what comes up from the market — when anything comes up at all.\"")
		"hospital_clerk":
			_hud.push_toast("CLERK", "\"Sit and wait like everyone else, love. One doctor, forty patients. If you're not bleeding, you're not urgent.\"")
		"hospital_stair":
			_hud.push_toast("", "A barred stair down to the old basement wards. Locked, and rusted into its frame. Whatever's filed down there has been down there a long time.")
		_:
			_hud.push_toast("", "Bandages, ledgers, the smell of carbolic.")
	_update_prompt()


func _heal_worker() -> void:
	if World.state.get_flag(WorldFacts.Flags.CINDER_HEALED_WORKER):
		_hud.push_toast("", "He's sleeping easy now, colour back in his face. The wound closed clean — cleaner than it should have.")
		return
	World.state.set_flag(WorldFacts.Flags.CINDER_HEALED_WORKER, true)
	World.state.set_flag(WorldFacts.Flags.SENSE_AWAKENED, true)
	if _env.has_method("set_worker_healed"):
		_env.set_worker_healed(true)
	if World.traits != null:
		World.traits.adjust(Traits.COMPASSION, 8)
	_hud.push_toast("WORLD UPDATED", "You don't decide to. Your hand finds the wound and something in you reaches — the same reach as a snapped machine, but warmer, and it answers. The bleeding stops. He breathes. And the cold rushes into you where the warmth left. You have to sit down.")
	_hud.set_objective("You healed a person. It was real. It took something out of you.")


func _read_records() -> void:
	if not World.state.get_flag(WorldFacts.Flags.ARLEN_LEARNED_HEALING_LORE):
		World.state.set_flag(WorldFacts.Flags.ARLEN_LEARNED_HEALING_LORE, true)
		if World.traits != null:
			World.traits.adjust(Traits.INSIGHT, 5)
		_hud.push_toast("OLD RECORDS", "Case ledgers, decades old. A recurring note in the same careful hand: 'recovery inconsistent with injury.' A family of physicians — the same surname across three generations — then a gap. They stop appearing. No deaths recorded. They simply... aren't listed again.")
	else:
		_hud.push_toast("", "The same impossible recoveries. The same vanished family. You keep coming back to the surname, and to the gap where it stops.")


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
