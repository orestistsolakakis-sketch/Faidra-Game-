class_name CinderHollowScenes
## Opening dialogue for Level 01 (Cinder Hollow, Arlen solo). The intro exchange
## with her best friend Bram (working name) — establishes voice, the district's
## trouble (the sickness, the dead lift), and lets the player start shaping Arlen
## (compassionate vs. cynical). See docs/levels/01_CINDER_HOLLOW.md.

const BRAM_INTRO_ID := "CINDER_BRAM_INTRO"
const FEN_MARKET_ID := "CINDER_FEN_MARKET"
const RENNICK_MARKET_ID := "CINDER_RENNICK_MARKET"
const DARA_ID := "CINDER_DARA"


static func register_into(library: DialogueLibrary) -> void:
	library.register(_build_bram_intro())
	library.register(_build_fen())
	library.register(_build_rennick())
	library.register(_build_dara())


# --- Trait/personality effect helpers (single-line lambdas call these) ---

static func _help(ctx) -> void:
	ctx.personality.add(Characters.ARLEN, PersonalityTraits.Arlen.COMPASSIONATE)
	ctx.traits.adjust(Traits.COMPASSION, 6)


static func _selfish(ctx) -> void:
	ctx.personality.add(Characters.ARLEN, PersonalityTraits.Arlen.CYNICAL)
	ctx.traits.adjust(Traits.CUNNING, 5)


static func _brave(ctx) -> void:
	ctx.personality.add(Characters.ARLEN, PersonalityTraits.Arlen.PROTECTIVE)
	ctx.traits.adjust(Traits.COURAGE, 6)


static func _shrewd(ctx) -> void:
	ctx.traits.adjust(Traits.CUNNING, 5)


static func _perceptive(ctx) -> void:
	ctx.traits.adjust(Traits.INSIGHT, 6)


static func _steady(ctx) -> void:
	ctx.traits.adjust(Traits.RESOLVE, 5)


static func _build_fen() -> DialogueScene:
	var scene := DialogueScene.new()
	scene.id = FEN_MARKET_ID
	scene.location = "Cinder Hollow — Market"
	scene.participants = [Characters.ARLEN]
	scene.start_node_id = "open"
	scene.nodes = {
		"open": _fen_open(),
		"info": _line("fen", "Lift's dead three days. No coal up, no medicine down. Someone with hands like yours ought to go below.", ""),
	}
	return scene


static func _fen_open() -> DialogueNode:
	var n := DialogueNode.new()
	n.id = "open"
	n.speaker = "fen"
	n.text = "Steam-bread, hot off the vent! ...You're the Kufstein girl. The one who fixes things. Heard the lower row's coughing black?"
	n.choices = [
		DialogueChoice.make("\"What have you heard?\"", "info", DialogueTone.HONEST,
			func(ctx): CinderHollowScenes._perceptive(ctx)),
		DialogueChoice.make("\"I'm handling it.\"", "info", DialogueTone.DEFENSIVE,
			func(ctx): CinderHollowScenes._steady(ctx)),
	]
	return n


static func _build_rennick() -> DialogueScene:
	var scene := DialogueScene.new()
	scene.id = RENNICK_MARKET_ID
	scene.location = "Cinder Hollow — Market"
	scene.participants = [Characters.ARLEN]
	scene.start_node_id = "open"
	scene.nodes = {
		"open": _rennick_open(),
		"info": _line("rennick", "My father cut the gears for that lift. Now it won't turn and the Drain Sector's gone quiet. That's not rust, girl.", ""),
	}
	return scene


static func _rennick_open() -> DialogueNode:
	var n := DialogueNode.new()
	n.id = "open"
	n.speaker = "rennick"
	n.text = "Parts? Got parts. Half of 'em cursed, all of 'em cheap. ...You're after the lift. Everyone is."
	n.choices = [
		DialogueChoice.make("\"Tell me about the lift.\"", "info", DialogueTone.HONEST,
			func(ctx): CinderHollowScenes._perceptive(ctx)),
		DialogueChoice.make("\"Just looking.\"", "info", DialogueTone.SARCASTIC,
			func(ctx): CinderHollowScenes._shrewd(ctx)),
	]
	return n


static func _build_bram_intro() -> DialogueScene:
	var scene := DialogueScene.new()
	scene.id = BRAM_INTRO_ID
	scene.location = "Cinder Hollow"
	scene.participants = [Characters.ARLEN, Characters.ARLEN_BEST_FRIEND]
	scene.start_node_id = "open"
	scene.nodes = {
		"open": _line(Characters.ARLEN_BEST_FRIEND,
			"There she is. Half the Hollow's coughing up ash and you're fixing a door.", "why"),
		"why": _why_node(),
		"sickness": _line(Characters.ARLEN_BEST_FRIEND,
			"Started three days back. Old Maren first, then the whole lower row. And the lift to the tunnels? Dead. No power up from below.", "care"),
		"care": _care_node(),
		"end_soft": _end_node("Then let's go make it your problem. Careful down there, Arlen."),
		"end_hard": _end_node("...Right. Just parts and trouble. Same as always. Watch yourself."),
	}
	return scene


static func _why_node() -> DialogueNode:
	var n := DialogueNode.new()
	n.id = "why"
	n.speaker = Characters.ARLEN
	n.text = "A door that won't open is a problem I can actually fix. What's wrong with everyone?"
	n.choices = [
		DialogueChoice.make("\"Tell me who's sick. I want to help.\"", "sickness", DialogueTone.HONEST,
			func(ctx): CinderHollowScenes._help(ctx)),
		DialogueChoice.make("\"Not my circus. I hunt parts, not cures.\"", "sickness", DialogueTone.DEFENSIVE,
			func(ctx): CinderHollowScenes._selfish(ctx)),
	]
	return n


static func _care_node() -> DialogueNode:
	var n := DialogueNode.new()
	n.id = "care"
	n.speaker = Characters.ARLEN
	n.text = "A dead lift and a sickness that starts at the bottom of the district. That's not a coincidence."
	n.choices = [
		DialogueChoice.make("\"I'm going down there.\"", "end_soft", DialogueTone.HONEST,
			func(ctx): CinderHollowScenes._brave(ctx)),
		DialogueChoice.make("\"If it pays, I'll look.\"", "end_hard", DialogueTone.SARCASTIC,
			func(ctx): CinderHollowScenes._shrewd(ctx)),
	]
	return n


static func _end_node(text: String) -> DialogueNode:
	var n := DialogueNode.new()
	n.speaker = Characters.ARLEN_BEST_FRIEND
	n.text = text
	n.on_enter = func(ctx): ctx.state.set_flag(WorldFacts.Flags.TALKED_TO_BRAM, true)
	n.next = ""
	return n


static func _build_dara() -> DialogueScene:
	var scene := DialogueScene.new()
	scene.id = DARA_ID
	scene.location = "Cinder Hollow — Residences"
	scene.participants = [Characters.ARLEN]
	scene.start_node_id = "open"
	scene.nodes = {
		"open": _dara_open(),
		"promise": _line("dara", "Bless you. Bring it through the Drain Sector — the low road's faster than the dead lift.", ""),
		"cold": _line("dara", "...No. No, of course not. Nobody can. Go on, then.", ""),
		"insight": _line("dara", "...You see it too. The black in the creases of his hands. That's not fever — that's a Lifeline gone wrong.", ""),
	}
	return scene


static func _dara_open() -> DialogueNode:
	var n := DialogueNode.new()
	n.id = "open"
	n.speaker = "dara"
	n.text = "My littlest won't stop coughing, and the medicine's past the dead lift. I can't leave the little ones. You're the mechanic, aren't you?"
	n.choices = [
		DialogueChoice.make("\"I'll bring your medicine back.\"", "promise", DialogueTone.HONEST,
			func(ctx): CinderHollowScenes._help(ctx)),
		DialogueChoice.make("[Insight] \"Let me see his hands — I can tell how far it's gone.\"", "insight", DialogueTone.CONFRONT,
			func(ctx): CinderHollowScenes._perceptive(ctx),
			func(ctx): return ctx.traits.meets(Traits.INSIGHT, 25)),
		DialogueChoice.make("\"I can't promise anything.\"", "cold", DialogueTone.DEFENSIVE),
	]
	return n


static func _line(speaker: String, text: String, next: String) -> DialogueNode:
	var n := DialogueNode.new()
	n.speaker = speaker
	n.text = text
	n.next = next
	return n
