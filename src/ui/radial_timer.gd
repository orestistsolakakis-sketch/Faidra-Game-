extends Control
## A small elegant shrinking-arc timer for timed dialogue choices (see
## docs/UI_UX_BIBLE.md §7) — nothing flashy, just a thin gold ring that depletes.

var fraction := 1.0

const RING := Color(1.0, 0.82, 0.45)
const TRACK := Color(1.0, 1.0, 1.0, 0.12)


func set_fraction(f: float) -> void:
	fraction = clampf(f, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 3.0
	draw_arc(center, radius, 0.0, TAU, 48, TRACK, 3.0, true)
	draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * fraction, 48, RING, 3.0, true)
