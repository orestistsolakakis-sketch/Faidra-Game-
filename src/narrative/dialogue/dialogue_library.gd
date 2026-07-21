class_name DialogueLibrary extends RefCounted
## A registry of authored DialogueScenes, keyed by id. Separate from the runner
## (which runs one scene at a time) so content is registered once at new-game and
## looked up by triggers, event effects, or interaction points.

var _scenes: Dictionary = {}


func register(scene: DialogueScene) -> void:
	_scenes[scene.id] = scene


func has(id: String) -> bool:
	return _scenes.has(id)


func get_scene(id: String) -> DialogueScene:
	return _scenes.get(id, null)


func clear() -> void:
	_scenes.clear()
