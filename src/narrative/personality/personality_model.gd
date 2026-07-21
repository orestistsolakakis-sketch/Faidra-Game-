class_name PersonalityModel extends RefCounted
## Tracks each character's emergent personality as accumulated trait weights (see
## docs/DIALOGUE_SYSTEM_BIBLE.md). Dialogue choice effects `add` weight; content
## reads `get_dominant`. The archetype is observed, not chosen.

signal changed(character: String, trait_id: String)

var _traits: Dictionary = {}  # character -> {trait -> weight}


func add(character: String, trait_id: String, weight: int = 1) -> void:
	if weight == 0:
		return
	if not _traits.has(character):
		_traits[character] = {}
	var traits: Dictionary = _traits[character]
	traits[trait_id] = traits.get(trait_id, 0) + weight
	changed.emit(character, trait_id)


func get_weight(character: String, trait_id: String) -> int:
	return _traits.get(character, {}).get(trait_id, 0)


## The character's strongest trait id, or "" if none has positive weight yet.
func get_dominant(character: String) -> String:
	if not _traits.has(character):
		return ""
	var best := ""
	var best_weight := -0x7FFFFFFF
	for trait_id in _traits[character]:
		var w: int = _traits[character][trait_id]
		if w > best_weight:
			best = trait_id
			best_weight = w
	return best if best_weight > 0 else ""


func snapshot() -> Dictionary:
	var out := {}
	for character in _traits:
		out[character] = (_traits[character] as Dictionary).duplicate()
	return out


func restore(data: Dictionary) -> void:
	_traits.clear()
	for character in data:
		var traits := {}
		for trait_id in data[character]:
			traits[trait_id] = int(data[character][trait_id])
		_traits[character] = traits


func reset() -> void:
	_traits.clear()
