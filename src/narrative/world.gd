extends Node
## World (autoload) — the facade over the narrative simulation. Owns every system
## and feeds clock/state changes into the event engine. Scenes reach the systems
## through `World.clock`, `World.state`, `World.events`, `World.relationships`,
## `World.personality`, `World.dialogue`, `World.dialogue_runner`, and connect to
## their signals directly (GDScript RefCounted classes emit their own).

var clock := WorldClock.new()
var state := WorldState.new()
var relationships := RelationshipModel.new()
var personality := PersonalityModel.new()
var events: EventManager
var dialogue := DialogueLibrary.new()
var dialogue_runner: DialogueRunner


func _init() -> void:
	# Every system shares the same clock, state, relationships and personality.
	events = EventManager.new(clock, state, relationships, personality)
	var context := ConsequenceContext.new(clock, state, events, relationships, personality)
	dialogue_runner = DialogueRunner.new(context)


func _ready() -> void:
	# The world reacts to time and facts: any change re-evaluates events.
	# (EventManager guards against re-entrancy when effects change state.)
	clock.advanced.connect(func(_minutes): events.evaluate())
	state.flag_changed.connect(func(_key): events.evaluate())
	state.value_changed.connect(func(_key): events.evaluate())


func new_game() -> void:
	clock.restore({"total_minutes": 0})
	state.reset()
	events.reset()
	relationships.reset()
	personality.reset()
	dialogue.clear()

	_register_content()

	# Seed opening world conditions.
	state.set_value(WorldFacts.Values.HEART_ENGINE_STABILITY, 100)
	state.set_value(WorldFacts.Values.CONTINUANCE_INFLUENCE, 0)
	state.set_flag(WorldFacts.Flags.ELDER_ALIVE, true)
	state.set_flag(WorldFacts.Flags.CINDER_HOSPITAL_OPEN, true)

	# Arlen and Lysandra begin at Phase 1 — Distrust (Character Bible).
	relationships.set_axis(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.TRUST, 10)
	relationships.set_axis(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.UNDERSTANDING, 5)
	relationships.set_axis(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.ATTRACTION, 0)
	relationships.set_axis(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.RESENTMENT, 25)
	relationships.set_axis(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.VULNERABILITY, 0)
	relationships.set_axis(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.DEPENDENCE, 0)

	events.evaluate()
	print("[World] New game. %s" % clock.to_display_string())


## Bundle the whole simulation into a JSON-friendly Dictionary for saving.
func capture_save() -> Dictionary:
	return {
		"version": 1,
		"saved_at": Time.get_datetime_string_from_system(true),
		"world_time": clock.to_display_string(),
		"clock": clock.snapshot(),
		"state": state.snapshot(),
		"events": events.snapshot(),
		"relationships": relationships.snapshot(),
		"personality": personality.snapshot(),
	}


## Restore the simulation from a save. Content is re-registered first (it isn't
## saved), then each system's runtime state is restored. Restores fire no signals,
## so callers should refresh any UI manually.
func load_game(data: Dictionary) -> void:
	events.reset()
	dialogue.clear()
	_register_content()

	clock.restore(data.get("clock", {}))
	state.restore(data.get("state", {}))
	events.restore(data.get("events", {}))
	relationships.restore(data.get("relationships", {}))
	personality.restore(data.get("personality", {}))

	GameManager.set_state(GameState.PLAYING)
	print("[World] Loaded. %s" % clock.to_display_string())


func _register_content() -> void:
	CinderHollowEvents.register_into(events)
	ArlenLysandraScenes.register_into(dialogue)
