class_name DialogueScene extends RefCounted
## A whole conversation: identity, participants, when it may play, and the node
## graph it walks (see docs/DIALOGUE_SYSTEM_BIBLE.md). Immutable content; the
## mutable "where are we now" lives in DialogueRunner.

var id: String
var location: String = ""
var participants: Array = []

## func(ctx) -> bool : whether the scene may currently play. Invalid = always.
var available: Callable

var start_node_id: String
var nodes: Dictionary = {}  # id -> DialogueNode


func node(node_id: String) -> DialogueNode:
	assert(nodes.has(node_id), "Dialogue scene '%s' has no node '%s'." % [id, node_id])
	return nodes[node_id]
