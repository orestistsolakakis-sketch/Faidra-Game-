class_name ArlenLysandraScenes
## Authored dialogue for Arlen & Lysandra — proof the engine expresses the
## canonical designs (docs/DIALOGUE_SYSTEM_BIBLE.md): intent-tagged choices, a
## timed opening line, relationship + personality + memory effects, an info-gated
## confrontation, and conditional text variants (by Trust and by past memory).

const ARGUMENT_01_ID := "ARLEN_LYSANDRA_ARGUMENT_01"


static func register_into(library: DialogueLibrary) -> void:
	library.register(_build_argument_01())


static func _build_argument_01() -> DialogueScene:
	var scene := DialogueScene.new()
	scene.id = ARGUMENT_01_ID
	scene.location = "On the road"
	scene.participants = [Characters.ARLEN, Characters.LYSANDRA]
	# Trigger: Lysandra found out Arlen hid something, while trust is still low.
	scene.available = func(ctx):
		return ctx.state.get_flag(WorldFacts.Flags.ARLEN_HID_INFO_FROM_LYSANDRA) \
			and ctx.relationships.get_axis(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.TRUST) < 50
	scene.start_node_id = "open"

	scene.nodes = {
		"open": _open_node(),
		"truth": _truth_node(),
		"confront": _line(Characters.LYSANDRA, "...I didn't know about the hospital. I swear to you I didn't.", ""),
		"silence": _silence_node(),
		"lie": _line(Characters.LYSANDRA, "You're lying. I can see it.", "cold"),
		"cold": _cold_node(),
	}
	return scene


static func _open_node() -> DialogueNode:
	var n := DialogueNode.new()
	n.id = "open"
	n.speaker = Characters.LYSANDRA
	n.text = "You knew the entire time."
	n.time_limit_seconds = 6.0
	n.default_choice_index = 3  # hesitation resolves to silence
	n.choices = [
		DialogueChoice.make(
			"\"I knew something was wrong. I didn't know what.\"", "truth",
			DialogueTone.HONEST, func(ctx): ArlenLysandraScenes._truth_effect(ctx)),
		DialogueChoice.make(
			"\"You have a strange way of asking questions.\"", "cold",
			DialogueTone.SARCASTIC, func(ctx): ArlenLysandraScenes._deflect_effect(ctx)),
		DialogueChoice.make(
			"\"I have no idea what you're talking about.\"", "lie",
			DialogueTone.DEFENSIVE, func(ctx): ArlenLysandraScenes._lie_effect(ctx)),
		DialogueChoice.make(
			"(Say nothing.)", "silence",
			DialogueTone.SILENCE, func(ctx): ArlenLysandraScenes._silence_effect(ctx)),
		# Info-gated: only if the player has uncovered the affair.
		DialogueChoice.make(
			"\"Then why did the palace shut down the hospital?\"", "confront",
			DialogueTone.CONFRONT, func(ctx): ArlenLysandraScenes._confront_effect(ctx),
			func(ctx): return ctx.state.get_flag(WorldFacts.Flags.HAS_DISCOVERED_EWALD_AFFAIR)),
	]
	return n


static func _truth_node() -> DialogueNode:
	var n := DialogueNode.new()
	n.id = "truth"
	n.speaker = Characters.LYSANDRA
	n.text = "...Fine. But you tell me everything from now on."
	n.text_variants = [
		{
			"when": func(ctx): return ctx.state.get_flag(WorldFacts.Flags.ARLEN_SAID_PEOPLE_DONT_CHANGE),
			"text": "You told me people don't change. Maybe you were wrong about that, too.",
		},
		{
			"when": func(ctx): return ctx.relationships.get_axis(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.TRUST) >= 40,
			"text": "...Then we start over. Together.",
		},
	]
	return n


static func _silence_node() -> DialogueNode:
	var n := DialogueNode.new()
	n.id = "silence"
	n.speaker = Characters.LYSANDRA
	n.text = "Say something. Please."
	n.on_enter = func(ctx): ctx.relationships.adjust(Characters.LYSANDRA, Characters.ARLEN, RelationshipAxis.VULNERABILITY, 4)
	n.next = "cold"
	return n


static func _cold_node() -> DialogueNode:
	var n := DialogueNode.new()
	n.id = "cold"
	n.speaker = Characters.LYSANDRA
	n.text = "...I thought we were past this."
	# Future consequence: Lysandra stops sharing secrets with Arlen.
	n.on_enter = func(ctx): ctx.state.set_flag(WorldFacts.Flags.LYSANDRA_GUARDS_SECRETS, true)
	n.next = ""
	return n


static func _line(speaker: String, text: String, next: String) -> DialogueNode:
	var n := DialogueNode.new()
	n.speaker = speaker
	n.text = text
	n.next = next
	return n


# --- Choice effects ---

static func _truth_effect(ctx) -> void:
	ctx.relationships.adjust(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.TRUST, 8)
	ctx.relationships.adjust(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.UNDERSTANDING, 6)
	ctx.personality.add(Characters.ARLEN, PersonalityTraits.Arlen.COMPASSIONATE)


static func _deflect_effect(ctx) -> void:
	ctx.relationships.adjust(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.RESENTMENT, 3)
	ctx.personality.add(Characters.ARLEN, PersonalityTraits.Arlen.CYNICAL)


static func _lie_effect(ctx) -> void:
	ctx.relationships.adjust(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.TRUST, -10)
	ctx.relationships.adjust(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.RESENTMENT, 5)
	ctx.personality.add(Characters.ARLEN, PersonalityTraits.Arlen.CYNICAL)


static func _silence_effect(ctx) -> void:
	ctx.relationships.adjust(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.UNDERSTANDING, -5)
	ctx.personality.add(Characters.ARLEN, PersonalityTraits.Arlen.INDEPENDENT)


static func _confront_effect(ctx) -> void:
	ctx.relationships.adjust(Characters.ARLEN, Characters.LYSANDRA, RelationshipAxis.UNDERSTANDING, 4)
	ctx.personality.add(Characters.ARLEN, PersonalityTraits.Arlen.INDEPENDENT)
