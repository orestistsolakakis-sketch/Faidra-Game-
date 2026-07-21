extends Node3D
## The sandbox scene root — now a slim game controller. Movement/camera live in the
## child nodes; dialogue UI, toasts and the day counter live in the HUD
## (game_hud.gd). This script wires the two together, runs the context-interaction
## loop (walk up to an object → prompt → [E]), and keeps the old debug harness
## behind [F3]. Throwaway harness; replaced by real areas/HUD flows later.

var _hud: CanvasLayer
var _party: Node
var _active_interactables: Array = []
var _debug_visible := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_hud = get_node("%Hud")
	_party = get_node("PartyController")
	_party.active_character_changed.connect(_hud.set_active_character)
	_hud.set_active_character("arlen")

	# Context interaction: track every interactable the player steps into.
	for node in get_tree().get_nodes_in_group("interactable"):
		node.entered.connect(_on_interactable_entered)
		node.exited.connect(_on_interactable_exited)

	# Debug readout stays in sync but hidden until [F3].
	GameManager.state_changed.connect(func(_p, _c): _refresh_debug())
	World.clock.advanced.connect(func(_m): _refresh_debug())
	World.state.flag_changed.connect(func(_k): _refresh_debug())
	World.state.value_changed.connect(func(_k): _refresh_debug())
	World.relationships.changed.connect(func(_a, _b, _ax, _d): _refresh_debug())
	World.personality.changed.connect(func(_c, _t): _refresh_debug())
	_refresh_debug()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	var key: int = event.keycode

	# Always-on controls.
	match key:
		KEY_ESCAPE:
			GameManager.toggle_pause()
			return
		KEY_BACKSPACE:
			SceneLoader.transition_to("res://scenes/UI/MainMenu.tscn", GameState.MAIN_MENU)
			return
		KEY_F3:
			_debug_visible = not _debug_visible
			_hud.toggle_debug()
			return
		KEY_E:
			_try_interact()
			return

	if _debug_visible:
		_handle_debug_keys(key)


func _try_interact() -> void:
	if _active_interactables.is_empty() or _hud.is_dialogue_active():
		return
	_interact(_active_interactables.back())


func _interact(which: Node) -> void:
	match which.id:
		"generator":
			World.state.set_flag(WorldFacts.Flags.CINDER_POWER_RESTORED, true)
		"notice":
			_hud.push_toast("", "Scratched into the wall: \"Kaufstein doesn't care about us.\"")
		"talk":
			World.state.set_flag(WorldFacts.Flags.ARLEN_HID_INFO_FROM_LYSANDRA, true)
			var scene := World.dialogue.get_scene(ArlenLysandraScenes.ARGUMENT_01_ID)
			if scene != null:
				World.dialogue_runner.start(scene)
		_:
			_hud.push_toast("", "Nothing happens.")
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


# --- Debug harness (behind F3) -------------------------------------------------

func _handle_debug_keys(key: int) -> void:
	match key:
		KEY_T:
			World.clock.advance_days(1)
		KEY_G:
			World.state.set_flag(WorldFacts.Flags.CINDER_GENERATOR_FAILED, true)
		KEY_1:
			World.events.resolve(CinderHollowEvents.HOSPITAL_CRISIS_ID, "repair_generator")
		KEY_2:
			World.events.resolve(CinderHollowEvents.HOSPITAL_CRISIS_ID, "ignore")
		KEY_K:
			World.state.set_flag(WorldFacts.Flags.HAS_DISCOVERED_EWALD_AFFAIR, true)
		KEY_F5:
			SaveSystem.save_game(World)
		KEY_F9:
			if SaveSystem.load_game(World):
				_refresh_debug()


func _refresh_debug() -> void:
	if _hud == null:
		return
	var rel := World.relationships.between(Characters.ARLEN, Characters.LYSANDRA)
	var dominant := World.personality.get_dominant(Characters.ARLEN)
	if dominant == "":
		dominant = "(unformed)"
	var text := "[F3 DEBUG]  keys: T +day  G generator  1 repair  2 ignore  K affair  F5/F9 save\n"
	text += "World Time: %s   Engine: %d\n" % [World.clock.to_display_string(), World.state.get_value(WorldFacts.Values.HEART_ENGINE_STABILITY)]
	text += "Hospital open: %s   Doctor: %s   Lore: %s\n" % [World.state.get_flag(WorldFacts.Flags.CINDER_HOSPITAL_OPEN), World.state.get_flag(WorldFacts.Flags.CINDER_DOCTOR_SURVIVED), World.state.get_flag(WorldFacts.Flags.ARLEN_LEARNED_HEALING_LORE)]
	text += "Arlen↔Lysandra Trust %d / Attract %d / Resent %d   Arlen self: %s" % [rel.get_axis(RelationshipAxis.TRUST), rel.get_axis(RelationshipAxis.ATTRACTION), rel.get_axis(RelationshipAxis.RESENTMENT), dominant]
	_hud.set_debug_text(text)
