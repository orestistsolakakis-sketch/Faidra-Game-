# The Heart Engine — Dialogue System Bible

> **Canonical dialogue design.** Dialogue is gameplay: choices decide what a
> character believes, reveals, hides, and becomes. Builds on `WorldState`
> (flags/memory), `RelationshipModel`, `EventManager`, and the new
> `PersonalityModel`. Consistent with
> [`SYSTEMS_BIBLE.md`](SYSTEMS_BIBLE.md) and [`CHARACTER_BIBLE.md`](CHARACTER_BIBLE.md).

---

## Core philosophy

The player isn't just choosing what a character *says* — they're deciding what
the character believes, reveals, hides, who they trust, how they respond under
pressure, and **what kind of person they are becoming.** Every important
conversation can change the future.

## Dialogue modes

1. **Cinematic dialogue** — the player watches; the camera moves; occasional
   (often timed) choices punctuate it.
2. **Exploration dialogue** — the player controls a character and chooses who to
   talk to; may walk away, interrupt, eavesdrop, return later, ask optional
   questions, or investigate objects first. Some lines unlock only with prior
   knowledge.
3. **Interactive conversations** — mid-conversation the player may look at the
   person/objects, notice details, interrupt, stay silent, leave, change the
   subject. Noticing a detail (a symbol on a ring) can open a clue that is
   otherwise lost forever.

## Choices are intent, never good/bad

No choice is labelled Good/Evil/Correct/Wrong. Choices express **intent** —
Honest, Defensive, Sarcastic, Vulnerable, Silence — and each tells the player
something about who the character is.

## Personality system (the game observes)

The player never selects "make Arlen compassionate." Choices **accumulate** into
emergent archetypes:

- **Arlen:** Protective · Cynical · Compassionate · Self-Sacrificing · Independent
- **Lysandra:** Diplomatic · Idealistic · Political · Rebellious · Compassionate ·
  Authoritarian

The dominant trait(s) colour later dialogue and behaviour. Different players end
up with genuinely different Arlens and Lysandras.

## Relationship dialogue

Conversations read and move the relationship axes (now six):
**Trust · Understanding · Attraction · Resentment · Vulnerability · Dependence.**
These are **never shown as numbers** — they change what lines appear and how they
read. High Trust: *"You don't have to tell me." / "I know."* (ends warmly). Low
Trust: same prompt, *"Then stop asking."* (turns tense). **High Attraction + Low
Trust** is a deliberate, rich state: they clearly care yet argue, protect each
other, get jealous, refuse to communicate. Love can coexist with serious problems.

## Romance built through moments

Not "complete 5 romance quests → kiss." Romance accretes from small behaviours —
sitting beside each other, checking on the other after injury, remembering a
detail, defending them, choosing honesty, staying during an argument, comforting
instead of leaving. The player may only notice the shift when the characters
suddenly behave differently.

## Timed choices

Some choices have a few-second limit — emergencies, arguments, confessions,
betrayals, combat, fear. *(Lysandra falls — [CATCH HER] / [GRAB THE RELIC] /
[CALL FOR HELP] / [FREEZE].)* Timing out is itself a choice (a default). Use
sparingly so they feel important.

## Knowledge as a mechanic

The player's discovered information unlocks or removes lines. If evidence that the
monarchy abandoned Cinder Hollow is known, a **[CONFRONT]** option appears; the
player may also **[PRETEND NOT TO KNOW]** to draw out more. Tracked via
**dialogue flags** (e.g. `HAS_DISCOVERED_EWALD_AFFAIR`,
`KNOWS_HEALER_BLOODLINE_EXISTS`) — ordinary `WorldState` facts.

## Dialogue memory

Characters remember what the player said. Answer *"Do you believe people can
change?"* with *"No"* early, and much later Lysandra recalls *"You told me people
don't change,"* letting the player affirm or recant. Implemented as flags/values
set by choice effects and read by later conditions — no separate system needed.

## Silence is a choice

Saying nothing can mean fear, anger, disagreement, vulnerability, distrust, or
respect — never merely neutral. Sometimes it is the most powerful answer.

## Optional & quest-changing dialogue

Not every conversation is required; some optional topics (a past, the city, the
Heart Engine, a fear) happen once — miss them and the info is lost. A single
conversation can fork the mission: Agree / Ask Why / Refuse / Lie / Expose — each
a different story path. There is no simple correct answer.

## Meaning shifts with development

The same line changes meaning over time. Early Arlen: *"I don't need anyone."*
Later Arlen says it identically — but the player now knows she's lying. The text
is authored once; the *understanding* is earned.

---

## Data structure (the authoring shape)

```
DIALOGUE_SCENE
├── SCENE_ID · LOCATION · PARTICIPANTS
├── TRIGGER / AVAILABILITY (required + optional flags)
├── DIALOGUE_NODES  (speaker lines, with conditional text variants)
│     └── PLAYER_CHOICES (intent-tagged, condition-gated, timed)
│           ├── RELATIONSHIP_EFFECTS
│           ├── INFORMATION_EFFECTS (flags)
│           ├── PERSONALITY_EFFECTS (trait weights)
│           ├── EVENT_EFFECTS (unlock/schedule events)
│           └── NEXT (node id | end) + FUTURE_CONSEQUENCES
```

Canonical example — `ARLEN_LYSANDRA_ARGUMENT_01`: triggers when Lysandra learns
Arlen hid information (required `Trust < 50`); a timed opening line with Tell the
Truth (+Trust +Understanding) / Lie (−Trust, +short-term safety) / Blame
(+Resentment) / Walk Away (+Independence −Understanding); future consequence:
whether Lysandra shares later secrets.

## The most important rule

Dialogue choices reveal **who the player is making the characters become.** The
player should look at Arlen and Lysandra and think *"this is the version of them
that I created."* Not every player gets the same characters, romance, or secrets —
that is what makes this an interactive story, not a normal RPG.

---

## 🏗️ Implementation (engineering)

Pure C# engine (testable, serializable) over the existing simulation.

- **`PersonalityModel`** (`src/Narrative/Personality/`) — per-character trait
  weights; choices `Add` to traits; `GetDominant` reports the emergent archetype.
  Trait ids come from a `PersonalityTraits` registry. Exposed on
  `ConsequenceContext`.
- **`DialogueChoice`** — Label, intent `Tone`, an optional `Available` condition
  (knowledge/relationship gating), an `Effect` (relationship + flag + personality
  + event changes, all via `ConsequenceContext`), and a `Next` node id.
- **`DialogueNode`** — a speaker line with optional **conditional text variants**
  (same line, different words by state), either auto-advancing (`Next`) or
  offering `Choices`; optional `OnEnter` effect; optional `TimeLimitSeconds` +
  `DefaultChoiceIndex` for timed choices.
- **`DialogueScene`** — id, location, participants, an `Available` entry
  condition, a start node, and the node graph.
- **`DialogueRunner`** — walks a scene against a `ConsequenceContext`: resolves
  the current line's text variant, filters choices by their conditions, applies a
  chosen choice's effect, advances, and ends. Raises `LineEntered`,
  `ChoicesOffered`, `SceneEnded`. Timing is driven by the presenter, which calls
  the default choice on timeout.
- **Memory & knowledge** need no new system — they are `WorldState` flags set by
  choice effects and read by later conditions.

Content lives in `Dialogue/Content/`. The cinematic presentation layer (camera,
portraits, animated choice UI) is deferred to the GameMode/UI pass; the harness
plays scenes as text to prove the engine.
