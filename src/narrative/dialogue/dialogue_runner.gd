class_name DialogueRunner extends RefCounted
## Walks a DialogueScene against the live world: resolves conditional text, filters
## choices by their conditions, applies a chosen choice's effect, advances, ends.
## Raises signals the presentation layer listens to; the presenter drives pacing
## and (for timed nodes) the countdown.

signal line_entered(speaker: String, text: String)
signal choices_offered(choices: Array)
signal scene_ended

var _context: ConsequenceContext
var _scene: DialogueScene
var _node: DialogueNode
var _visible_choices: Array = []


func _init(context: ConsequenceContext) -> void:
	_context = context


func is_running() -> bool:
	return _scene != null


func current_node() -> DialogueNode:
	return _node


func can_play(scene: DialogueScene) -> bool:
	return not scene.available.is_valid() or scene.available.call(_context)


func start(scene: DialogueScene) -> bool:
	if not can_play(scene):
		return false
	_scene = scene
	_enter_node(scene.start_node_id)
	return true


## Advance an auto-advance (choice-less) node to its next.
func advance() -> void:
	if _node == null or _visible_choices.size() > 0:
		return
	_go_to(_node.next)


## Resolve the current choice node by picking the visible choice at `visible_index`.
func choose(visible_index: int) -> void:
	if _node == null or visible_index < 0 or visible_index >= _visible_choices.size():
		return
	var choice: DialogueChoice = _visible_choices[visible_index]
	if choice.effect.is_valid():
		choice.effect.call(_context)
	_go_to(choice.next)


## The index the presenter auto-selects if a timed node times out.
func default_choice_index() -> int:
	if _node == null:
		return 0
	return clampi(_node.default_choice_index, 0, max(0, _visible_choices.size() - 1))


func _go_to(next_id: String) -> void:
	if next_id == "":
		_end()
	else:
		_enter_node(next_id)


func _enter_node(node_id: String) -> void:
	_node = _scene.node(node_id)
	if _node.on_enter.is_valid():
		_node.on_enter.call(_context)

	line_entered.emit(_node.speaker, _resolve_text(_node))

	_visible_choices = []
	for c in _node.choices:
		if not c.available.is_valid() or c.available.call(_context):
			_visible_choices.append(c)
	if _visible_choices.size() > 0:
		choices_offered.emit(_visible_choices)


func _resolve_text(node: DialogueNode) -> String:
	for variant in node.text_variants:
		if (variant["when"] as Callable).call(_context):
			return variant["text"]
	return node.text


func _end() -> void:
	_scene = null
	_node = null
	_visible_choices = []
	scene_ended.emit()
