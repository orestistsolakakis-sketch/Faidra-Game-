class_name Relationship extends RefCounted
## One pair's relationship: a clamped 0-100 value per RelationshipAxis. A plain
## data holder (the owning RelationshipModel raises change notifications).
## Symmetric — it represents the bond, not one character's private feelings.

const MIN := 0
const MAX := 100

var _values: Dictionary = {}  # axis:int -> value:int


func get_axis(axis: int) -> int:
	return _values.get(axis, MIN)


## Set an axis to an absolute value (clamped). Returns true if it actually changed.
func set_axis(axis: int, value: int) -> bool:
	var clamped := clampi(value, MIN, MAX)
	if get_axis(axis) == clamped:
		return false
	_values[axis] = clamped
	return true


func adjust(axis: int, delta: int) -> bool:
	return set_axis(axis, get_axis(axis) + delta)


func snapshot() -> Dictionary:
	return _values.duplicate()


func restore(data: Dictionary) -> void:
	_values.clear()
	for k in data:
		_values[int(k)] = int(data[k])
