class_name DialogueNode extends RefCounted
## One beat of a conversation: a spoken line plus what follows. A node either
## auto-advances (`next`) or offers `choices`. Two bible features are built in:
## conditional TEXT VARIANTS (same beat, different words by state) and TIMED
## CHOICES (`time_limit_seconds` + `default_choice_index`).

var id: String
var speaker: String = ""       # character id, or "" for narration
var text: String = ""          # default line

## Array of {"when": Callable(ctx)->bool, "text": String}; first match replaces text.
var text_variants: Array = []

var on_enter: Callable         # func(ctx) — optional
var choices: Array = []        # DialogueChoice; empty = auto-advance
var next: String = ""          # next node id when no choices; "" ends the scene
var time_limit_seconds: float = 0.0  # 0 = untimed
var default_choice_index: int = 0    # auto-picked on timeout (index into visible choices)
