extends Node3D
## The sandbox scene's root — a live harness for everything built so far. Hosts the
## narrative HUD and debug keys while the child nodes (two player characters + a
## party controller) provide real movement and switching. During dialogue, movement
## auto-freezes because the GameMode flips to INTERACTIVE_CINEMATIC.
##
## Throwaway harness/debug UI; it will be replaced by the first real area.

var _hint: Label
var _readout: Label
var _dialogue: Label

var _in_dialogue := false
var _choices: Array = []
var _speaker := ""
var _line := ""
var _time_remaining := 0.0

const _MODE_NAMES := ["Exploration", "Cinematic", "InteractiveCinematic", "Decision"]


func _ready() -> void:
	# Keep processing input while the tree is paused so [Esc] can un-pause.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_hint = get_node("%Hint")
	_readout = get_node("%Readout")
	_dialogue = get_node("%Dialogue")

	GameManager.state_changed.connect(_on_state_changed)

	# GDScript auto-disconnects these when this node is freed.
	World.clock.advanced.connect(_on_sim_changed_int)
	World.state.flag_changed.connect(_on_sim_changed_key)
	World.state.value_changed.connect(_on_sim_changed_key)
	World.relationships.changed.connect(_on_relationship_changed)
	World.personality.changed.connect(_on_personality_changed)
	World.events.event_activated.connect(_on_event_activated)
	World.events.event_expired.connect(_on_event_expired)
	World.events.event_resolved.connect(_on_event_resolved)

	World.dialogue_runner.line_entered.connect(_on_dialogue_line)
	World.dialogue_runner.choices_offered.connect(_on_dialogue_choices)
	World.dialogue_runner.scene_ended.connect(_on_dialogue_ended)

	_update_hint(GameManager.state)
	_refresh_readout()
	_render_dialogue()


func _on_sim_changed_int(_minutes: int) -> void:
	_refresh_readout()


func _on_sim_changed_key(_key: String) -> void:
	_refresh_readout()


func _on_relationship_changed(_a: String, _b: String, _axis: int) -> void:
	_refresh_readout()


func _on_personality_changed(_character: String, _trait_id: String) -> void:
	_refresh_readout()


func _on_event_activated(id: String) -> void:
	print("[Event] ACTIVATED: %s" % id)


func _on_event_expired(id: String) -> void:
	print("[Event] EXPIRED (default outcome): %s" % id)


func _on_event_resolved(id: String, outcome_id: String) -> void:
	print("[Event] RESOLVED: %s -> %s" % [id, outcome_id])


func _process(delta: float) -> void:
	# Drive the countdown on a timed choice; auto-pick the default on timeout.
	if not _in_dialogue or _choices.is_empty() or _time_remaining <= 0.0:
		return
	_time_remaining -= delta
	if _time_remaining <= 0.0:
		World.dialogue_runner.choose(World.dialogue_runner.default_choice_index())
	else:
		_render_dialogue()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	var keycode: int = event.keycode

	# Global controls always available.
	if keycode == KEY_ESCAPE:
		GameManager.toggle_pause()
		return
	if keycode == KEY_BACKSPACE:
		SceneLoader.transition_to("res://scenes/UI/MainMenu.tscn", GameState.MAIN_MENU)
		return

	if _in_dialogue:
		_handle_dialogue_input(keycode)
	else:
		_handle_sim_input(keycode)


func _handle_sim_input(keycode: int) -> void:
	match keycode:
		KEY_T:  # advance one day
			World.clock.advance_days(1)
		KEY_G:  # the generator fails -> triggers the hospital crisis
			World.state.set_flag(WorldFacts.Flags.CINDER_GENERATOR_FAILED, true)
		KEY_1:  # resolve the crisis: repair (the chain)
			World.events.resolve(CinderHollowEvents.HOSPITAL_CRISIS_ID, "repair_generator")
		KEY_2:  # resolve the crisis: ignore (sever the chain)
			World.events.resolve(CinderHollowEvents.HOSPITAL_CRISIS_ID, "ignore")
		KEY_L:  # leave the district (arms the delayed food shortage)
			World.state.set_value(WorldFacts.Values.LEFT_CINDER_DAY, World.clock.day())
			World.state.set_flag(WorldFacts.Flags.LEFT_CINDER_HOLLOW, true)
		KEY_3:  # a warm moment
			World.relationships.adjust(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.TRUST, 8)
			World.relationships.adjust(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.ATTRACTION, 5)
		KEY_4:  # a hurt
			World.relationships.adjust(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.RESENTMENT, 10)
		KEY_K:  # discover the affair (unlocks the confront option)
			World.state.set_flag(WorldFacts.Flags.HAS_DISCOVERED_EWALD_AFFAIR, true)
		KEY_D:  # start the argument dialogue scene
			_start_argument_scene()
		KEY_F5:  # quicksave
			SaveSystem.save_game(World)
		KEY_F9:  # quickload
			if SaveSystem.load_game(World):
				_refresh_readout()


func _start_argument_scene() -> void:
	World.state.set_flag(WorldFacts.Flags.ARLEN_HID_INFO_FROM_LYSANDRA, true)
	var scene := World.dialogue.get_scene(ArlenLysandraScenes.ARGUMENT_01_ID)
	if scene != null and World.dialogue_runner.start(scene):
		_in_dialogue = true
		# A conversation is an interactive cinematic: movement suspends.
		GameModeManager.enter_dialogue(true)


func _handle_dialogue_input(keycode: int) -> void:
	if _choices.is_empty():
		if keycode == KEY_SPACE or keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
			World.dialogue_runner.advance()
		return

	var index := -1
	match keycode:
		KEY_1: index = 0
		KEY_2: index = 1
		KEY_3: index = 2
		KEY_4: index = 3
		KEY_5: index = 4
	if index >= 0 and index < _choices.size():
		World.dialogue_runner.choose(index)


func _on_dialogue_line(speaker: String, text: String) -> void:
	_speaker = speaker
	_line = text
	_choices = []
	_time_remaining = 0.0
	_render_dialogue()


func _on_dialogue_choices(choices: Array) -> void:
	_choices = choices
	var node := World.dialogue_runner.current_node()
	_time_remaining = node.time_limit_seconds if node != null else 0.0
	_render_dialogue()


func _on_dialogue_ended() -> void:
	_in_dialogue = false
	_choices = []
	_line = ""
	_speaker = ""
	GameModeManager.exit_to_exploration()
	_render_dialogue()
	_refresh_readout()


func _render_dialogue() -> void:
	if not _in_dialogue:
		_dialogue.text = ""
		return
	var text := "%s:  %s\n" % [_display_name(_speaker), _line]
	if not _choices.is_empty():
		for i in _choices.size():
			text += "\n  [%d] (%d)  %s" % [i + 1, _choices[i].tone, _choices[i].label]
		if _time_remaining > 0.0:
			text += "\n\n  ⏳ %.1fs" % _time_remaining
	else:
		text += "\n  [Space] continue"
	_dialogue.text = text


func _display_name(character_id: String) -> String:
	match character_id:
		Characters.ARLEN: return "Arlen"
		Characters.LYSANDRA: return "Lysandra"
		_: return character_id


func _on_state_changed(_previous: int, current: int) -> void:
	_update_hint(current)


func _update_hint(state: int) -> void:
	if state == GameState.PAUSED:
		_hint.text = "PAUSED\n[Esc] resume   [Backspace] main menu"
	else:
		_hint.text = "MOVE: WASD  run Shift  jump Space  [Q] switch character  (mouse looks)\n" \
			+ "[Esc] pause   [Backspace] menu\n" \
			+ "SIM:  [T] +1 day  [G] generator  [1] repair  [2] ignore  [L] leave\n" \
			+ "      [3] warm moment  [4] a hurt  [K] discover affair  [D] dialogue\n" \
			+ "      [F5] quicksave   [F9] quickload"


func _refresh_readout() -> void:
	var active := ""
	for evt in World.events.active_events():
		active += "\n  • %s (deadline-driven)" % evt.id
	if active == "":
		active = "\n  (none)"

	var rel := World.relationships.between(Characters.ARLEN, Characters.LYSANDRA)
	var dominant := World.personality.get_dominant(Characters.ARLEN)
	if dominant == "":
		dominant = "(unformed)"

	_readout.text = "Mode: %s\n" % _MODE_NAMES[GameModeManager.mode] \
		+ "World Time: %s\n" % World.clock.to_display_string() \
		+ "Engine stability: %d\n" % World.state.get_value(WorldFacts.Values.HEART_ENGINE_STABILITY) \
		+ "Hospital open: %s   Doctor survived: %s\n" % [World.state.get_flag(WorldFacts.Flags.CINDER_HOSPITAL_OPEN), World.state.get_flag(WorldFacts.Flags.CINDER_DOCTOR_SURVIVED)] \
		+ "Arlen learned healing lore: %s\n" % World.state.get_flag(WorldFacts.Flags.ARLEN_LEARNED_HEALING_LORE) \
		+ "Lysandra guards secrets: %s\n\n" % World.state.get_flag(WorldFacts.Flags.LYSANDRA_GUARDS_SECRETS) \
		+ "Arlen ↔ Lysandra —  Trust %d  Underst %d  Attract %d  Resent %d  Vuln %d  Depend %d\n" % [rel.get_axis(RelationshipAxis.TRUST), rel.get_axis(RelationshipAxis.UNDERSTANDING), rel.get_axis(RelationshipAxis.ATTRACTION), rel.get_axis(RelationshipAxis.RESENTMENT), rel.get_axis(RelationshipAxis.VULNERABILITY), rel.get_axis(RelationshipAxis.DEPENDENCE)] \
		+ "Arlen's emerging self: %s\n" % dominant \
		+ "Active events:%s" % active
