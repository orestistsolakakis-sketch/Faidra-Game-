class_name WorldState extends RefCounted
## The authoritative, serializable store of world "facts": boolean `flags` and
## integer `values` (see docs/SYSTEMS_BIBLE.md). The whole game is a simulation,
## not a branching script: systems store facts here and rules react to them.
## Change signals fire only on real changes. Use WorldFacts constants for keys.

signal flag_changed(key: String)
signal value_changed(key: String)

var _flags: Dictionary = {}
var _values: Dictionary = {}


func get_flag(key: String) -> bool:
	return _flags.get(key, false)


func set_flag(key: String, value: bool = true) -> void:
	if get_flag(key) == value:
		return
	_flags[key] = value
	flag_changed.emit(key)


func get_value(key: String) -> int:
	return _values.get(key, 0)


func set_value(key: String, value: int) -> void:
	if get_value(key) == value:
		return
	_values[key] = value
	value_changed.emit(key)


func add_value(key: String, delta: int) -> int:
	var next := get_value(key) + delta
	set_value(key, next)
	return next


func snapshot() -> Dictionary:
	return {"flags": _flags.duplicate(), "values": _values.duplicate()}


func restore(data: Dictionary) -> void:
	_flags.clear()
	_values.clear()
	var flags: Dictionary = data.get("flags", {})
	for k in flags:
		_flags[k] = bool(flags[k])
	var values: Dictionary = data.get("values", {})
	for k in values:
		_values[k] = int(values[k])


func reset() -> void:
	_flags.clear()
	_values.clear()
