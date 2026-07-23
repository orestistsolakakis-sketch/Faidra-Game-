extends Node3D
## Controller for the Level 01 opening (Cinder Hollow, Arlen solo). Shows the area
## title card, drives the objective, and runs the context-interaction loop against
## the district's objects. Single lead — Lysandra joins only at the level's climax
## (docs/levels/01_CINDER_HOLLOW.md). [F3] toggles a small dev overlay.

var _hud: CanvasLayer
var _active_interactables: Array = []
var _debug_visible := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hud = get_node("%Hud")

	var party := get_node("PartyController")
	party.active_character_changed.connect(func(_id): _hud.set_solo_lead("Arlen"))
	_hud.set_solo_lead("Arlen")

	for node in get_tree().get_nodes_in_group("interactable"):
		node.entered.connect(_on_interactable_entered)
		node.exited.connect(_on_interactable_exited)

	World.state.flag_changed.connect(_on_flag_changed)

	# Opening beat (no cinematic — that's deferred to the end of development).
	_hud.set_objective("Find out what's making the Hollow sick.")
	_hud.show_title("CINDER HOLLOW", "The lowest district of the capital. Built on the bones of the old world.")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_ESCAPE:
			GameManager.toggle_pause()
		KEY_BACKSPACE:
			SceneLoader.transition_to("res://scenes/UI/MainMenu.tscn", GameState.MAIN_MENU)
		KEY_F3:
			_debug_visible = not _debug_visible
			_hud.toggle_debug()
			_refresh_debug()
		KEY_E:
			_try_interact()


func _try_interact() -> void:
	if _active_interactables.is_empty() or _hud.is_dialogue_active():
		return
	_interact(_active_interactables.back())


func _interact(which: Node) -> void:
	match which.id:
		"workshop_door":
			SceneLoader.transition_to("res://scenes/World/WorkshopInterior.tscn", GameState.PLAYING)
		"bram":
			if World.state.get_flag(WorldFacts.Flags.TALKED_TO_BRAM):
				_hud.push_toast("", "Bram: \"Go on, then. The tunnels won't wait.\"")
			else:
				var scene := World.dialogue.get_scene(CinderHollowScenes.BRAM_INTRO_ID)
				if scene != null:
					World.dialogue_runner.start(scene)
		"merchant_fen":
			_start_scene(CinderHollowScenes.FEN_MARKET_ID)
		"merchant_rennick":
			_start_scene(CinderHollowScenes.RENNICK_MARKET_ID)
		"resident_dara":
			_start_scene(CinderHollowScenes.DARA_ID)
		"rail_station":
			SceneLoader.transition_to("res://scenes/World/CinderUnderground.tscn", GameState.PLAYING)
		"copper_kettle_door":
			SceneLoader.transition_to("res://scenes/World/CopperKettle.tscn", GameState.PLAYING)
		"home_door":
			SceneLoader.transition_to("res://scenes/World/CinderHome.tscn", GameState.PLAYING)
		"hospital_door":
			SceneLoader.transition_to("res://scenes/World/Hospital.tscn", GameState.PLAYING)
		"steam_lift":
			_repair_steam_lift()
		"workshop_generator":
			_repair_generator()
		"scrap_exchange_door":
			_hud.push_toast("", "Shuttered — Old Rennick trades out on the street for now. The Exchange opens later.")
		"broken_bell_door":
			_hud.push_toast("", "Locked this early. The Bell keeps its own hours, and its own secrets.")
		"neighbor":
			_hud.push_toast("", "A wet, rattling cough behind the door. It started three days ago.")
		"lift":
			if not World.state.get_flag(WorldFacts.Flags.CINDER_LIFT_INSPECTED):
				World.state.set_flag(WorldFacts.Flags.CINDER_LIFT_INSPECTED, true)
			_hud.push_toast("WORLD UPDATED", "The freight lift is dead — no power from the tunnels below.")
		_:
			_hud.push_toast("", "Nothing to do here.")
	_update_prompt()


func _repair_steam_lift() -> void:
	if World.state.get_flag(WorldFacts.Flags.CINDER_STEAM_LIFT_REPAIRED):
		_hud.push_toast("", "The lift runs steady now. The cage climbs and falls, and steam pours off the gears.")
		return
	World.state.set_flag(WorldFacts.Flags.CINDER_STEAM_LIFT_REPAIRED, true)
	var district := get_node_or_null("District")
	if district != null and district.has_method("set_steam_lift_running"):
		district.set_steam_lift_running(true)
	if World.traits != null:
		World.traits.adjust(Traits.RESOLVE, 6)
	_hud.push_toast("WORLD UPDATED", "The seized coupling gives. Steam screams through the pipes and the great cage shudders into motion. Half the Hollow just got its shortcut back — and a foundryman his easier shift.")
	_hud.set_objective("The Steam Lift runs again. The district feels a little more connected.")


func _repair_generator() -> void:
	if World.state.get_flag(WorldFacts.Flags.CINDER_WORKSHOP_ROW_POWERED):
		_hud.push_toast("", "The generator hums. Down the lane, the lamps burn steady.")
		return
	World.state.set_flag(WorldFacts.Flags.CINDER_WORKSHOP_ROW_POWERED, true)
	var district := get_node_or_null("District")
	if district != null and district.has_method("set_workshop_row_powered"):
		district.set_workshop_row_powered(true)
	if World.traits != null:
		World.traits.adjust(Traits.INSIGHT, 5)
	_hud.push_toast("WORLD UPDATED", "You trace the fault to a shorted feed, not a dead core. One reconnection and the row's lamps stutter, then hold. Work can go on after dark now.")
	_hud.set_objective("Workshop Row has its light back.")


func _start_scene(scene_id: String) -> void:
	var scene := World.dialogue.get_scene(scene_id)
	if scene != null:
		World.dialogue_runner.start(scene)


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


func _on_flag_changed(key: String) -> void:
	match key:
		WorldFacts.Flags.TALKED_TO_BRAM:
			if World.state.get_flag(key):
				_hud.set_objective("Reach the dead freight lift at the end of the street.")
		WorldFacts.Flags.CINDER_LIFT_INSPECTED:
			if World.state.get_flag(key):
				_hud.set_objective("Find another way down into the tunnels.")
	if _debug_visible:
		_refresh_debug()


func _refresh_debug() -> void:
	if not _debug_visible:
		return
	var dominant := World.personality.get_dominant(Characters.ARLEN)
	if dominant == "":
		dominant = "(unformed)"
	_hud.set_debug_text("[F3]  Door:%s  Bram:%s  Lift:%s  Arlen:%s" % [
		World.state.get_flag(WorldFacts.Flags.CINDER_WORKSHOP_DOOR_FIXED),
		World.state.get_flag(WorldFacts.Flags.TALKED_TO_BRAM),
		World.state.get_flag(WorldFacts.Flags.CINDER_LIFT_INSPECTED),
		dominant,
	])
