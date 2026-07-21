class_name WorldEvent extends RefCounted
## A single event definition — a rule about the world that can activate, run on a
## deadline, and resolve into one of several outcomes (see
## docs/EVENT_SYSTEM_BIBLE.md). An event is just a `condition` over existing world
## data plus effects; delayed/hidden consequences need no special machinery.
##
## Callables receive a ConsequenceContext. Outcomes map an id to
## {"label": String, "apply": Callable}.

var id: String
var location: String = ""
var category: int = EventTypes.Category.LOCAL
var level: int = EventTypes.Level.SHORT_TERM
var priority: int = 0

## func(ctx) -> bool : returns true when the event should activate.
var condition: Callable

## Minutes after activation before it self-resolves. -1 = waits indefinitely.
var deadline_minutes: int = -1

var on_activate: Callable  # func(ctx) — optional (check is_valid)
var on_expire: Callable    # func(ctx) — the default "do nothing" outcome

var outcomes: Dictionary = {}  # id -> {"label": String, "apply": Callable}
