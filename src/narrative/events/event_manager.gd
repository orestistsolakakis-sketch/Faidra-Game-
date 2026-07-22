class_name EventManager extends RefCounted
## The living-world engine. Holds every WorldEvent and re-evaluates them whenever
## World Time or a fact changes: dormant events whose condition becomes true
## ACTIVATE; active events past their deadline EXPIRE (applying their default
## outcome); the player RESOLVES an active event by choosing an outcome. Because
## effects can change state (and register further events), one `evaluate` cascades
## until the world settles — how a single choice ripples down a chain in one tick.

signal event_activated(event_id: String)
signal event_resolved(event_id: String, outcome_id: String)
signal event_expired(event_id: String)

const MAX_CASCADE_PASSES := 64

var _events: Dictionary = {}        # id -> WorldEvent
var _status: Dictionary = {}        # id -> EventTypes.Status
var _activated_at: Dictionary = {}  # id -> minutes
var _context: ConsequenceContext
var _evaluating := false


func _init(clock: WorldClock, state: WorldState, relationships: RelationshipModel, personality: PersonalityModel, traits: TraitModel) -> void:
	_context = ConsequenceContext.new(clock, state, self, relationships, personality, traits)


func register(evt: WorldEvent) -> void:
	_events[evt.id] = evt
	if not _status.has(evt.id):
		_status[evt.id] = EventTypes.Status.DORMANT


func status_of(id: String) -> int:
	return _status.get(id, EventTypes.Status.DORMANT)


## All live events awaiting resolution, highest priority first.
func active_events() -> Array:
	var out := []
	for evt in _events.values():
		if status_of(evt.id) == EventTypes.Status.ACTIVE:
			out.append(evt)
	out.sort_custom(func(a, b): return a.priority > b.priority)
	return out


## Re-evaluate all events, looping until the world settles.
func evaluate() -> void:
	if _evaluating:
		return  # an effect triggered another evaluate; the outer loop will catch it
	_evaluating = true
	for _pass in range(MAX_CASCADE_PASSES):
		var changed := false

		# Expire overdue actives first.
		for evt in _events.values():
			if status_of(evt.id) == EventTypes.Status.ACTIVE and evt.deadline_minutes >= 0:
				if _context.clock.total_minutes >= int(_activated_at[evt.id]) + evt.deadline_minutes:
					_expire(evt)
					changed = true

		# Activate anything whose condition is now met.
		for evt in _events.values():
			if status_of(evt.id) == EventTypes.Status.DORMANT and evt.condition.is_valid() and evt.condition.call(_context):
				_activate(evt)
				changed = true

		if not changed:
			_evaluating = false
			return

	_evaluating = false
	push_error("Event evaluation did not settle — likely a content loop.")


## The player picks `outcome_id` on a live event. Applies its effect, marks it
## resolved. No-op if the event isn't active or the outcome doesn't exist.
func resolve(event_id: String, outcome_id: String) -> bool:
	if not _events.has(event_id) or status_of(event_id) != EventTypes.Status.ACTIVE:
		return false
	var evt: WorldEvent = _events[event_id]
	if not evt.outcomes.has(outcome_id):
		return false

	_status[event_id] = EventTypes.Status.RESOLVED
	var apply: Callable = evt.outcomes[outcome_id]["apply"]
	apply.call(_context)
	event_resolved.emit(event_id, outcome_id)

	evaluate()  # the resolution may have unlocked or expired other events
	return true


func snapshot() -> Dictionary:
	return {"status": _status.duplicate(), "activated_at": _activated_at.duplicate()}


func restore(data: Dictionary) -> void:
	_status.clear()
	_activated_at.clear()
	var status: Dictionary = data.get("status", {})
	for k in status:
		_status[k] = int(status[k])
	var activated: Dictionary = data.get("activated_at", {})
	for k in activated:
		_activated_at[k] = int(activated[k])


func reset() -> void:
	_status.clear()
	_activated_at.clear()
	for id in _events:
		_status[id] = EventTypes.Status.DORMANT


func _activate(evt: WorldEvent) -> void:
	_status[evt.id] = EventTypes.Status.ACTIVE
	_activated_at[evt.id] = _context.clock.total_minutes
	if evt.on_activate.is_valid():
		evt.on_activate.call(_context)
	event_activated.emit(evt.id)


func _expire(evt: WorldEvent) -> void:
	_status[evt.id] = EventTypes.Status.EXPIRED
	if evt.on_expire.is_valid():
		evt.on_expire.call(_context)
	event_expired.emit(evt.id)
