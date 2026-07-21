extends Node
## SceneLoader (autoload) — faded, async scene transitions. All menu/area changes
## go through `transition_to()` so we never get a hard cut. Owns a top-most fade
## overlay and drives GameManager through LOADING around the swap. Access as
## `SceneLoader`.

signal transition_finished

const FADE_SECONDS := 0.4

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	# The fade must keep animating even when the tree is paused, and sit above all.
	process_mode = Node.PROCESS_MODE_ALWAYS

	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func transition_to(scene_path: String, state_after: int = GameState.PLAYING) -> void:
	if _busy:
		return
	_busy = true

	GameManager.set_state(GameState.LOADING)
	await _fade_to(1.0)
	get_tree().change_scene_to_file(scene_path)
	# Let the new scene enter the tree before we reveal it.
	await get_tree().process_frame
	await _fade_to(0.0)

	GameManager.set_state(state_after)
	_busy = false
	transition_finished.emit()


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_SECONDS)
	await tween.finished
