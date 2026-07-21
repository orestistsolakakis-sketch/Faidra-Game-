extends Node
## GameModeManager (autoload) — owns the interaction GameMode within gameplay.
## Anything that needs to know "should I accept movement now?" asks
## `GameModeManager.accepts_movement()`. Resets to EXPLORATION whenever gameplay
## (re)starts so a mode never leaks across a scene change. Access as `GameModeManager`.

signal mode_changed(previous: int, current: int)

var mode: int = GameMode.EXPLORATION


func _ready() -> void:
	GameManager.state_changed.connect(_on_game_state_changed)


func accepts_movement() -> bool:
	return mode == GameMode.EXPLORATION


func set_mode(next: int) -> void:
	if next == mode:
		return
	var previous := mode
	mode = next
	print("[GameMode] %d -> %d" % [previous, next])
	mode_changed.emit(previous, next)


## Enter a conversation: interactive lets the player still act; else pure cinematic.
func enter_dialogue(interactive: bool) -> void:
	set_mode(GameMode.INTERACTIVE_CINEMATIC if interactive else GameMode.CINEMATIC)


func exit_to_exploration() -> void:
	set_mode(GameMode.EXPLORATION)


func _on_game_state_changed(previous: int, current: int) -> void:
	# Entering active play (from menu/loading) resets the interaction mode.
	if current == GameState.PLAYING and previous != GameState.PAUSED:
		set_mode(GameMode.EXPLORATION)
