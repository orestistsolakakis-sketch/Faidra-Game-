# The Heart Engine — Consequence & Event System Bible

> **Canonical design for the living world.** How choices change world state, how
> events run independently of the player, how consequences chain and delay, and
> the rules the system must obey. Builds directly on the data core in
> [`SYSTEMS_BIBLE.md`](SYSTEMS_BIBLE.md) (`WorldClock`, `WorldState`).

---

## Core philosophy

Choices don't just change dialogue — they change the **state of the world**. The
player should feel: *"the world was going to continue whether I was there or
not."* The game does **not** wait for the player. While Arlen and Lysandra are in
one place, events happen elsewhere. Consequences may land immediately, hours,
days, weeks, or months later — even near the end — and some are **never directly
explained.** The player connects the dots themselves.

## The World State (what events read & write)

Everything flows through the shared fact store: political stability, Heart Engine
stability, district conditions, faction power, character relationships, character
health, resources, public opinion, **time**, information discovered, reputation.
Every choice alters one or more. *(Implemented as `WorldState` flags + values and
the `WorldClock`.)*

## Time

Time is a first-class consequence. Actions cost different amounts, and the player
is **not always told how much**:

| Action | Time |
|---|---|
| Conversation | Minutes |
| Explore a location | Hours |
| Repair a small machine | Hours |
| Repair a major system | Days |
| Travel between districts | Hours–Days |
| Search for a relic | Days–Weeks |
| Recover from serious injury | Days |
| Help rebuild a community | Weeks |
| Investigate a major mystery | Weeks–Months |

## Event anatomy

Events exist **independently** of the player. Each has:

```
EVENT
├── ID
├── LOCATION
├── TRIGGER      (the condition that activates it)
├── DEADLINE     (time after activation before it resolves itself)
├── CONDITIONS   (what must be true for outcomes)
├── CONSEQUENCES (effects on World State)
└── ALTERNATE OUTCOMES
```

**Canonical example — `CINDER_HOLLOW_HOSPITAL_CRISIS`:** the district generator
fails (trigger); deadline 3 days; the hospital needs power (condition). Player
options: repair the generator · find a replacement part · find another power
source · ignore it. Outcomes: repaired → hospital stays open; delayed → patients
worsen; ignored → hospital closes. **Long-term effect:** a future character may
live or die.

## Event types

1. **Personal** — one character (sickness, leaving, discovering a secret, injury,
   losing trust). Can happen while the player is elsewhere.
2. **Local** — a location (factory explosion, bridge collapse, power loss, market
   shutdown, disease spread).
3. **Political** — factions/governments (a family gains influence, a rebellion, a
   law, loss of royal support, a district secedes). Player influences these
   *indirectly*.
4. **World** — global, **permanent** (Heart Engine loses stability, magical
   storms, unstable Lifelines, a city destroyed, a relic taken by another
   faction).

## Event dependencies — a branching *web*, not a tree

One event unlocks another. Repairing a factory → power → hospital open → doctor
survives → doctor helps Arlen → Arlen learns about healing → new ability. Ignore
it and that whole chain never happens — a **different story path**, not a wrong
one. Paths may **reconnect** later (everyone may still reach the Heart Engine) but
with different people alive, relics available, relationships, and world condition.

## Consequence levels

| Level | Scope | Example |
|---|---|---|
| **1 — Immediate** | Current scene | Someone gets angry; a door opens; info given. |
| **2 — Short-term** | Next few missions | A character refuses to help; a route opens/closes. |
| **3 — Long-term** | Later chapters | A character survives; a faction rises; a district falls; romance shifts. |
| **4 — Permanent** | The ending | A major character dies; a relic is destroyed; the Engine can't be fully restored; a different future. |

Not every choice needs Level 4. Use the smallest level that fits.

## Hidden & delayed consequences

The game **doesn't always tell the player what they changed.** Leave an injured
stranger; hours later meet someone who says *"my brother died in Cinder Hollow"* —
the player realizes it themselves. **Delayed events** are triggered by time: e.g.
30 days away from Cinder Hollow with food unrestored → shortage begins; return to
find starvation, theft, a new faction in control, someone gone. The game need not
say *"this happened because you left."*

## Relationship & healing consequences

Characters **remember**. Heal Lysandra and Arlen's energy runs low → later she
*can't* heal someone else; Lysandra may say *"you shouldn't have used your power on
me"* or *"you saved me when you didn't have to."* This moves **Trust, Attraction,
Resentment, Guilt** and changes future dialogue and options.

Healing is never free — every heal tracks a **cost**: exhaustion, temporary loss
of ability, pain, memory loss, higher future-injury risk, emotional trauma. The
recurring question: **"Who do I save?"**

## Event priority — simultaneity

When several events are live at once (Day 45: a friend injured · a factory about
to explode · a political meeting · a relic clue), the player can address **one
first**; the others **continue** (and may expire). That simultaneity is what makes
the decisions feel real.

## Success still costs

Succeeding ≠ saving everyone. Save the hospital, but the factory is destroyed, the
district loses jobs, a character is angry, two weeks are spent on repairs. The
question is usually **"which problem do I solve?"** not **"do I solve it?"**

## System rules (the system MUST obey these)

- The world keeps moving when the player is absent; not every event waits.
- Choices can have delayed consequences; the player won't always know the cause.
- Events have multiple possible outcomes; characters remember choices.
- Time matters. Resources matter. Healing has costs.
- Helping one place may make another suffer. There is no single perfect path.
- Failed outcomes create **new story**, not a game-over.
- The player may miss important events; some events happen *only because* the
  player ignored something. Major events change the world **permanently**.

## The core question

Every major event asks: **what did the player choose to prioritize?** The player
cannot save everyone, repair everything, discover every secret, be everywhere, or
prevent every tragedy. The story becomes the consequences of what they chose.

---

## 🏗️ Implementation (engineering)

Built as **pure C#** (no Godot dependency) on top of `WorldClock` + `WorldState`,
owned by the `World` autoload, which re-broadcasts activity as Godot signals.

**Key realization — delayed events need no special machinery.** Because the clock
and fact store already exist, a "30 days after leaving" trigger is *just a
condition* over `Clock.Day` and a stored `left_cinder_day` value. Events are
**rules over existing data**, which keeps the system small.

### Types
- **`WorldEvent`** — a definition: `Id`, `Category` (Personal/Local/Political/
  World), `Level` (Immediate…Permanent), `Priority`, `Location`, a **`Condition`**
  predicate (when it activates), an optional **`DeadlineMinutes`** (self-resolves
  after this long), `OnActivate`, `OnExpire` (the default outcome), and named
  **`Outcomes`** (the player's choices, each an effect).
- **`EventStatus`** — `Dormant → Active → Resolved | Expired`.
- **`EventOutcome`** — a label + an effect applied to the world.
- **`ConsequenceContext`** — passed to every condition/effect; exposes `Clock`,
  `State`, and `Events` so effects can mutate state *and* unlock/schedule further
  events (this is how chains are built).

### `EventManager`
Registers events; re-evaluates on every clock/state change. Dormant events whose
`Condition` becomes true **activate** (stamping the activation time);
`Active` events past their deadline **expire** (applying `OnExpire`). The player
resolves an active event by choosing an outcome. Raises `EventActivated /
Resolved / Expired`. Runtime state (status + activation time per event) is
serialized for saves; definitions are re-registered on load.

### Content
Event *definitions* live in content files (e.g. `CinderHollowEvents`) authored in
C# against this API, registered at new-game. Content can later migrate to data
files without changing the engine.
