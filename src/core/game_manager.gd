extends Node
## GameManager (autoload) — the spine of the game. Single source of truth for the
## high-level GameState. Everything reacts to `state_changed` and reads `state`;
## one writer, many readers. Also owns the tree-wide pause. Access globally as
## `GameManager`.

signal state_changed(previous: int, current: int)

var state: int = GameState.BOOT


func set_state(next: int) -> void:
	if next == state:
		return
	var previous := state
	state = next
	# Pause is a tree-wide flag; centralise it so nothing else has to remember.
	get_tree().paused = next == GameState.PAUSED
	print("[GameManager] %d -> %d" % [previous, next])
	state_changed.emit(previous, next)


func toggle_pause() -> void:
	if state == GameState.PLAYING:
		set_state(GameState.PAUSED)
	elif state == GameState.PAUSED:
		set_state(GameState.PLAYING)
