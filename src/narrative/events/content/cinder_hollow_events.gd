class_name CinderHollowEvents
## Authored event content for Cinder Hollow — proof the engine expresses the
## canonical designs (docs/EVENT_SYSTEM_BIBLE.md): the hospital-crisis consequence
## chain (repair -> power -> hospital open -> doctor survives -> Arlen learns
## healing lore) with a "do nothing" expiry, and a delayed, hidden food shortage.

const HOSPITAL_CRISIS_ID := "CINDER_HOLLOW_HOSPITAL_CRISIS"
const FOOD_SHORTAGE_ID := "CINDER_HOLLOW_FOOD_SHORTAGE"


static func register_into(events: EventManager) -> void:
	events.register(_build_hospital_crisis())
	events.register(_build_food_shortage())


static func _build_hospital_crisis() -> WorldEvent:
	var e := WorldEvent.new()
	e.id = HOSPITAL_CRISIS_ID
	e.location = "Cinder Hollow"
	e.category = EventTypes.Category.LOCAL
	e.level = EventTypes.Level.LONG_TERM
	e.priority = 80
	e.condition = func(ctx):
		return ctx.state.get_flag(WorldFacts.Flags.CINDER_GENERATOR_FAILED) \
			and not ctx.state.get_flag(WorldFacts.Flags.CINDER_POWER_RESTORED)
	e.deadline_minutes = 3 * WorldClock.MINUTES_PER_DAY
	e.outcomes = {
		"repair_generator": {
			"label": "Repair the generator (2 days, costs materials).",
			"apply": func(ctx): CinderHollowEvents._repair(ctx, 2),
		},
		"find_replacement_part": {
			"label": "Search for a replacement part (1 week; may reveal an old workshop).",
			"apply": func(ctx): CinderHollowEvents._repair(ctx, 7),
		},
		"ignore": {
			"label": "Leave it — there are other priorities.",
			"apply": func(ctx): CinderHollowEvents._close_hospital(ctx),
		},
	}
	# "Do nothing": the deadline passes, the hospital closes on its own.
	e.on_expire = func(ctx): CinderHollowEvents._close_hospital(ctx)
	return e


## Spend `days` on the repair, then restore power and save the hospital.
static func _repair(ctx, days: int) -> void:
	ctx.clock.advance_days(days)
	CinderHollowEvents._restore_power_and_save_hospital(ctx)


## Power restored -> hospital open -> doctor survives -> Arlen learns healing lore.
static func _restore_power_and_save_hospital(ctx) -> void:
	ctx.state.set_flag(WorldFacts.Flags.CINDER_POWER_RESTORED, true)
	ctx.state.set_flag(WorldFacts.Flags.CINDER_HOSPITAL_OPEN, true)
	ctx.state.set_flag(WorldFacts.Flags.CINDER_DOCTOR_SURVIVED, true)
	# Chain payoff: a surviving doctor is the one who first helps Arlen understand
	# what she is.
	ctx.state.set_flag(WorldFacts.Flags.ARLEN_LEARNED_HEALING_LORE, true)


## The hospital closes; the doctor does not survive; the healing-lore chain severs.
static func _close_hospital(ctx) -> void:
	ctx.state.set_flag(WorldFacts.Flags.CINDER_HOSPITAL_OPEN, false)
	ctx.state.set_flag(WorldFacts.Flags.CINDER_DOCTOR_SURVIVED, false)


## Delayed, hidden. Arms when the player leaves Cinder Hollow; fires ~30 days later
## if food was never restored. No player outcomes — activating IS the consequence.
static func _build_food_shortage() -> WorldEvent:
	var e := WorldEvent.new()
	e.id = FOOD_SHORTAGE_ID
	e.location = "Cinder Hollow"
	e.category = EventTypes.Category.LOCAL
	e.level = EventTypes.Level.LONG_TERM
	e.priority = 40
	e.condition = func(ctx):
		if ctx.state.get_flag(WorldFacts.Flags.CINDER_FOOD_RESTORED):
			return false
		var left_day: int = ctx.state.get_value(WorldFacts.Values.LEFT_CINDER_DAY)
		if left_day <= 0:
			return false
		return ctx.clock.day() - left_day >= 30
	e.on_activate = func(ctx): ctx.state.set_flag(WorldFacts.Flags.CINDER_FOOD_SHORTAGE, true)
	return e
