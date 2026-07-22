extends CanvasLayer
## The diegetic, cinematic HUD (see docs/UI_UX_BIBLE.md). Built in code and wired
## to the live systems. During exploration it shows almost nothing — a reticle, the
## controlled character, the day, a small objective. It surfaces subtle,
## number-free relationship/world toasts, a context-interaction prompt, and the
## cinematic dialogue panel. A hidden debug overlay (F3) keeps the old readout.

const RadialTimer := preload("res://src/ui/radial_timer.gd")

const GOLD := Color(0.86, 0.72, 0.42)
const TEXT := Color(0.90, 0.91, 0.93)
const DIM := Color(0.62, 0.66, 0.72)
const WARN := Color(1.0, 0.44, 0.48)
const PANEL_BG := Color(0.03, 0.04, 0.06, 0.86)
const PANEL_BORDER := Color(0.86, 0.72, 0.42, 0.35)

var _reticle: Label
var _party: Label
var _day: Label
var _objective: Label
var _interact: PanelContainer
var _interact_label: Label
var _toasts: VBoxContainer
var _debug: Label

var _root: Control
var _dialogue: PanelContainer
var _dlg_speaker: Label
var _dlg_text: Label
var _dlg_choices: VBoxContainer
var _dlg_timer

var _in_dialogue := false
var _choices: Array = []
var _time_remaining := 0.0
var _time_limit := 0.0


func _ready() -> void:
	_build()

	World.clock.advanced.connect(func(_m): _update_day())
	World.clock.day_elapsed.connect(func(_d): _update_day())
	World.state.flag_changed.connect(_on_flag_changed)
	World.relationships.changed.connect(_on_relationship_changed)

	World.dialogue_runner.line_entered.connect(_on_dialogue_line)
	World.dialogue_runner.choices_offered.connect(_on_dialogue_choices)
	World.dialogue_runner.scene_ended.connect(_on_dialogue_ended)

	_update_day()


# --- Public API (called by the game controller) --------------------------------

func set_active_character(id: String) -> void:
	_party.text = "▸ %s   /   %s" % [_display(id), _other(id)]


## Show a single lead's name (opening chapters, before the party forms).
func set_solo_lead(name: String) -> void:
	_party.text = name


## A cinematic area/chapter title card that fades in and out.
func show_title(title: String, subtitle: String) -> void:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position += Vector2(-260, -60)
	box.custom_minimum_size = Vector2(520, 0)
	var t := _make_label(title, 46, GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	if subtitle != "":
		var s := _make_label(subtitle, 18, DIM)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(s)
	box.modulate.a = 0.0
	_root.add_child(box)

	var tween := create_tween()
	tween.tween_property(box, "modulate:a", 1.0, 1.2)
	tween.tween_interval(2.6)
	tween.tween_property(box, "modulate:a", 0.0, 1.4)
	tween.tween_callback(box.queue_free)


func show_interaction(label: String, verb: String) -> void:
	_interact_label.text = "%s\n[E]  %s" % [label, verb]
	_interact.visible = true


func hide_interaction() -> void:
	_interact.visible = false


func set_objective(text: String) -> void:
	_objective.text = "CURRENT OBJECTIVE\n%s" % text


func is_dialogue_active() -> bool:
	return _in_dialogue


func set_debug_text(text: String) -> void:
	_debug.text = text


func toggle_debug() -> void:
	_debug.visible = not _debug.visible


# --- Toasts --------------------------------------------------------------------

func push_toast(title: String, body: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _stylebox(PANEL_BG, PANEL_BORDER))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	var box := VBoxContainer.new()
	if title != "":
		box.add_child(_make_label(title, 13, GOLD))
	if body != "":
		box.add_child(_make_label(body, 17, TEXT))
	margin.add_child(box)
	card.add_child(margin)
	card.modulate.a = 0.0
	_toasts.add_child(card)

	var tween := create_tween()
	tween.tween_property(card, "modulate:a", 1.0, 0.35)
	tween.tween_interval(3.2)
	tween.tween_property(card, "modulate:a", 0.0, 0.8)
	tween.tween_callback(card.queue_free)


# --- Dialogue ------------------------------------------------------------------

func _on_dialogue_line(speaker: String, text: String) -> void:
	if not _in_dialogue:
		_in_dialogue = true
		GameModeManager.enter_dialogue(true)
		_dialogue.visible = true
	_dlg_speaker.text = _display(speaker)
	_dlg_text.text = text
	_choices = []
	_time_remaining = 0.0
	_time_limit = 0.0
	_dlg_timer.visible = false
	_clear_choices()
	_add_choice_hint("[Space] continue")


func _on_dialogue_choices(choices: Array) -> void:
	_choices = choices
	_clear_choices()
	for i in choices.size():
		_dlg_choices.add_child(_make_label("%d.  %s" % [i + 1, choices[i].label], 17, TEXT))
	var node := World.dialogue_runner.current_node()
	_time_limit = node.time_limit_seconds if node != null else 0.0
	_time_remaining = _time_limit
	_dlg_timer.visible = _time_limit > 0.0
	if _time_limit > 0.0:
		_dlg_timer.set_fraction(1.0)


func _on_dialogue_ended() -> void:
	_in_dialogue = false
	GameModeManager.exit_to_exploration()
	_dialogue.visible = false
	_choices = []


func _process(delta: float) -> void:
	if not _in_dialogue or _choices.is_empty() or _time_remaining <= 0.0:
		return
	_time_remaining -= delta
	if _time_remaining <= 0.0:
		World.dialogue_runner.choose(World.dialogue_runner.default_choice_index())
	else:
		_dlg_timer.set_fraction(_time_remaining / _time_limit)


func _input(event: InputEvent) -> void:
	if not _in_dialogue or not (event is InputEventKey and event.pressed):
		return
	var key: int = event.keycode
	if _choices.is_empty():
		if key == KEY_SPACE or key == KEY_ENTER or key == KEY_KP_ENTER:
			World.dialogue_runner.advance()
			get_viewport().set_input_as_handled()
		return
	var index := key - KEY_1
	if index >= 0 and index < _choices.size():
		World.dialogue_runner.choose(index)
		get_viewport().set_input_as_handled()


# --- System reactions ----------------------------------------------------------

func _update_day() -> void:
	_day.text = "Day %d   ·   %02d:%02d" % [World.clock.day(), World.clock.hour(), World.clock.minute()]


func _on_flag_changed(key: String) -> void:
	var on := World.state.get_flag(key)
	match key:
		WorldFacts.Flags.CINDER_POWER_RESTORED:
			if on: push_toast("WORLD UPDATED", "Cinder Hollow — Power Restored")
		WorldFacts.Flags.CINDER_HOSPITAL_OPEN:
			if not on: push_toast("WORLD UPDATED", "Cinder Hollow — The hospital went dark")
		WorldFacts.Flags.CINDER_FOOD_SHORTAGE:
			if on: push_toast("WORLD UPDATED", "Cinder Hollow — Food is running short")
		WorldFacts.Flags.LYSANDRA_GUARDS_SECRETS:
			if on: push_toast("", "Lysandra keeps something back now.")


func _on_relationship_changed(a: String, b: String, axis: int, delta: int) -> void:
	# Only surface the emotionally legible axes, as feeling — never numbers.
	var phrase := ""
	match axis:
		RelationshipAxis.TRUST:
			phrase = "Trust deepened." if delta > 0 else "Something between them cooled."
		RelationshipAxis.ATTRACTION:
			if delta > 0: phrase = "A glance held a little too long."
		RelationshipAxis.RESENTMENT:
			if delta > 0: phrase = "That landed wrong."
		RelationshipAxis.VULNERABILITY:
			if delta > 0: phrase = "A guard lowered, just slightly."
	if phrase != "":
		push_toast("", phrase)


# --- Build ---------------------------------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_root = root

	_reticle = _make_label("○", 16, Color(1, 1, 1, 0.55))
	_reticle.set_anchors_preset(Control.PRESET_CENTER)
	root.add_child(_reticle)

	_objective = _make_label("CURRENT OBJECTIVE\nFind a way into the deep tunnels", 15, DIM)
	_objective.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_objective.position = Vector2(28, 22)
	root.add_child(_objective)

	_day = _make_label("Day 1", 16, GOLD)
	_day.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_day.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_day.offset_top = 22
	_day.offset_right = -28
	root.add_child(_day)

	_party = _make_label("▸ Arlen   /   Lysandra", 16, TEXT)
	_party.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_party.position = Vector2(28, -44)
	root.add_child(_party)

	_toasts = VBoxContainer.new()
	_toasts.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_toasts.position = Vector2(28, 92)
	_toasts.add_theme_constant_override("separation", 8)
	root.add_child(_toasts)

	_interact = PanelContainer.new()
	_interact.add_theme_stylebox_override("panel", _stylebox(PANEL_BG, PANEL_BORDER))
	_interact.set_anchors_preset(Control.PRESET_CENTER)
	_interact.position += Vector2(-90, 90)
	_interact.visible = false
	var im := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		im.add_theme_constant_override("margin_" + side, 12)
	_interact_label = _make_label("", 17, TEXT)
	_interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	im.add_child(_interact_label)
	_interact.add_child(im)
	root.add_child(_interact)

	_debug = _make_label("", 15, DIM)
	_debug.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_debug.position = Vector2(28, 300)
	_debug.visible = false
	root.add_child(_debug)

	_build_dialogue(root)


func _build_dialogue(root: Control) -> void:
	_dialogue = PanelContainer.new()
	_dialogue.add_theme_stylebox_override("panel", _stylebox(PANEL_BG, PANEL_BORDER))
	_dialogue.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue.offset_left = 40
	_dialogue.offset_right = -40
	_dialogue.offset_top = -250
	_dialogue.offset_bottom = -30
	_dialogue.visible = false

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)

	var header := HBoxContainer.new()
	_dlg_speaker = _make_label("", 20, GOLD)
	_dlg_speaker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_dlg_speaker)
	_dlg_timer = RadialTimer.new()
	_dlg_timer.custom_minimum_size = Vector2(30, 30)
	_dlg_timer.visible = false
	header.add_child(_dlg_timer)
	col.add_child(header)

	_dlg_text = _make_label("", 19, TEXT)
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_dlg_text)

	_dlg_choices = VBoxContainer.new()
	_dlg_choices.add_theme_constant_override("separation", 6)
	col.add_child(_dlg_choices)

	margin.add_child(col)
	_dialogue.add_child(margin)
	root.add_child(_dialogue)


func _clear_choices() -> void:
	for child in _dlg_choices.get_children():
		child.queue_free()


func _add_choice_hint(text: String) -> void:
	_dlg_choices.add_child(_make_label(text, 15, DIM))


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(1)
	sb.border_color = border
	return sb


func _display(id: String) -> String:
	match id:
		"arlen": return "Arlen"
		"lysandra": return "Lysandra"
		"arlen_best_friend": return "Bram"
		"fen": return "Fen · Steam-bread"
		"rennick": return "Old Rennick · Scrap"
		"": return ""
		_: return id


func _other(id: String) -> String:
	return "Lysandra" if id == "arlen" else "Arlen"
