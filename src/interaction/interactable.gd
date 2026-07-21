extends Area3D
## A world object the player can act on. When a player character is within its
## range it announces itself (entered/exited) so the HUD can show a context prompt
## ("Old Machine — [E] Repair"). The actual effect lives in the game controller,
## keyed by `id`, so this node stays a dumb, reusable trigger (see docs/UI_UX_BIBLE.md).

@export var id := ""
@export var label := "Object"
@export var verb := "Inspect"

signal entered(interactable: Node)
signal exited(interactable: Node)

var _players_inside := 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_players_inside += 1
	if _players_inside == 1:
		entered.emit(self)


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_players_inside = maxi(0, _players_inside - 1)
	if _players_inside == 0:
		exited.emit(self)
