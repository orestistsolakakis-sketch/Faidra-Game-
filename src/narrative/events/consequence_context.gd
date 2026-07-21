class_name ConsequenceContext extends RefCounted
## The handle passed to every event/dialogue condition and effect. It exposes the
## whole simulation so a condition can read facts and an effect can change them —
## and unlock further events through `events`. That is how consequence CHAINS form.
##
## `events` is left untyped to avoid a circular class dependency with EventManager.

var clock: WorldClock
var state: WorldState
var events  # EventManager
var relationships: RelationshipModel
var personality: PersonalityModel


func _init(p_clock: WorldClock, p_state: WorldState, p_events, p_relationships: RelationshipModel, p_personality: PersonalityModel) -> void:
	clock = p_clock
	state = p_state
	events = p_events
	relationships = p_relationships
	personality = p_personality
