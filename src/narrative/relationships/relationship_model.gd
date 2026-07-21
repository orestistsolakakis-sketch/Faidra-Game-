class_name RelationshipModel extends RefCounted
## Owns every Relationship, keyed by an order-independent pair (Arlen<->Lysandra
## is the same bond as Lysandra<->Arlen). The read/write surface event outcomes
## and dialogue choices use to move the axes. Pairs are created lazily.

signal changed(character_a: String, character_b: String, axis: int)

var _relationships: Dictionary = {}  # "a|b" -> Relationship


func between(a: String, b: String) -> Relationship:
	var key := _key(a, b)
	if not _relationships.has(key):
		_relationships[key] = Relationship.new()
	return _relationships[key]


func get_axis(a: String, b: String, axis: int) -> int:
	return between(a, b).get_axis(axis)


func set_axis(a: String, b: String, axis: int, value: int) -> void:
	if between(a, b).set_axis(axis, value):
		var pair := _ordered(a, b)
		changed.emit(pair[0], pair[1], axis)


func adjust(a: String, b: String, axis: int, delta: int) -> void:
	if between(a, b).adjust(axis, delta):
		var pair := _ordered(a, b)
		changed.emit(pair[0], pair[1], axis)


func snapshot() -> Dictionary:
	var out := {}
	for key in _relationships:
		out[key] = _relationships[key].snapshot()
	return out


func restore(data: Dictionary) -> void:
	_relationships.clear()
	for key in data:
		var rel := Relationship.new()
		rel.restore(data[key])
		_relationships[key] = rel


func reset() -> void:
	_relationships.clear()


func _ordered(a: String, b: String) -> Array:
	return [a, b] if a <= b else [b, a]


func _key(a: String, b: String) -> String:
	var pair := _ordered(a, b)
	return pair[0] + "|" + pair[1]
