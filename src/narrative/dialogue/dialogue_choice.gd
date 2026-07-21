class_name DialogueChoice extends RefCounted
## One player option on a DialogueNode: its intent, an optional availability
## condition (knowledge/relationship gating), the effect it applies to the world
## (relationships + flags + personality + events via ConsequenceContext), and
## where the conversation goes next. Callables receive a ConsequenceContext.

var label: String
var tone: int = DialogueTone.NEUTRAL

## func(ctx) -> bool : return false to hide this choice. Invalid Callable = always shown.
var available: Callable

## func(ctx) : the consequence of choosing this option. Invalid = no direct effect.
var effect: Callable

## Id of the next node, or "" to end the scene after this choice.
var next: String = ""


static func make(p_label: String, p_next: String, p_tone: int = DialogueTone.NEUTRAL, p_effect: Callable = Callable(), p_available: Callable = Callable()) -> DialogueChoice:
	var c := DialogueChoice.new()
	c.label = p_label
	c.next = p_next
	c.tone = p_tone
	c.effect = p_effect
	c.available = p_available
	return c
