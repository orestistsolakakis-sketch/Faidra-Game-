class_name TraitModel extends RefCounted
## Tracks Arlen's journey traits as clamped 0–100 values. Dialogue choices adjust
## them (as +/- percentages the player sees), later content reads them to gate or
## aid options ("Cunning ≥ 40 to try the bluff"). Pure C#-free GDScript;
## serializable; owned by the World autoload.

signal changed(trait_id: String, delta: int)

const MIN := 0
const MAX := 100

var _values: Dictionary = {}  # trait_id -> int


func get_value(trait_id: String) -> int:
	return _values.get(trait_id, 0)


## True if a trait meets a threshold — the standard "does the journey open up?" check.
func meets(trait_id: String, threshold: int) -> bool:
	return get_value(trait_id) >= threshold


func set_value(trait_id: String, value: int) -> void:
	var clamped := clampi(value, MIN, MAX)
	var before := get_value(trait_id)
	if clamped == before:
		return
	_values[trait_id] = clamped
	changed.emit(trait_id, clamped - before)


func adjust(trait_id: String, delta: int) -> void:
	set_value(trait_id, get_value(trait_id) + delta)


func seed_defaults() -> void:
	for trait_id in Traits.ALL:
		_values[trait_id] = Traits.START_VALUE


func snapshot() -> Dictionary:
	return _values.duplicate()


func restore(data: Dictionary) -> void:
	_values.clear()
	for k in data:
		_values[k] = int(data[k])


func reset() -> void:
	_values.clear()
