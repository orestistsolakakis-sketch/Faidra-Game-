class_name WorldClock extends RefCounted
## Owns "World Time" — how long the journey to the Heart Engine has taken (see
## docs/SYSTEMS_BIBLE.md). Actions push time forward; the world reacts to elapsed
## time, not a fixed chapter. Stored as an integer minute count to avoid drift.
## `day_elapsed` is the daily "heartbeat" the event system hangs the living world off.

signal advanced(minutes: int)
signal day_elapsed(day: int)

const MINUTES_PER_HOUR := 60
const HOURS_PER_DAY := 24
const MINUTES_PER_DAY := 1440  # 60 * 24

var total_minutes: int = 0


func total_days() -> float:
	return float(total_minutes) / MINUTES_PER_DAY


func day() -> int:
	return total_minutes / MINUTES_PER_DAY + 1  # 1-based


func hour() -> int:
	return (total_minutes % MINUTES_PER_DAY) / MINUTES_PER_HOUR


func minute() -> int:
	return total_minutes % MINUTES_PER_HOUR


## Advance by `minutes` (>= 0). Fires `advanced` once, then `day_elapsed` for each
## day boundary crossed so a large jump never skips a daily tick.
func advance(minutes: int) -> void:
	assert(minutes >= 0, "World Time cannot move backwards.")
	if minutes == 0:
		return
	var previous_day := day()
	total_minutes += minutes
	var current_day := day()
	advanced.emit(minutes)
	for d in range(previous_day + 1, current_day + 1):
		day_elapsed.emit(d)


func advance_hours(hours: float) -> void:
	advance(int(round(hours * MINUTES_PER_HOUR)))


func advance_days(days: float) -> void:
	advance(int(round(days * MINUTES_PER_DAY)))


## Coarse time-of-day band the world dresses itself by (routines, tavern activity…).
func part_of_day() -> String:
	var h := hour()
	if h < 6:
		return "night"
	elif h < 11:
		return "morning"
	elif h < 17:
		return "afternoon"
	elif h < 22:
		return "evening"
	return "night"


func to_display_string() -> String:
	return "Day %d · %02d:%02d" % [day(), hour(), minute()]


func snapshot() -> Dictionary:
	return {"total_minutes": total_minutes}


func restore(data: Dictionary) -> void:
	total_minutes = int(data.get("total_minutes", 0))
