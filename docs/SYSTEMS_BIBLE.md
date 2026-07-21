# The Heart Engine — Player, Narrative & Systems Bible

> **Canonical systems document.** Defines how the game plays and how its
> narrative simulation works: the three gameplay modes, World Time, the living
> world, abilities-as-choices, the relationship model, dialogue philosophy, and
> consequence chains. This is the primary reference for gameplay/systems
> engineering. Consistent with [`WORLD_BIBLE.md`](WORLD_BIBLE.md) and
> [`CHARACTER_BIBLE.md`](CHARACTER_BIBLE.md).

---

## Core structure — three gameplay modes

The game interleaves three modes. The `GameManager` state machine will grow to
model these (see [`ARCHITECTURE.md`](ARCHITECTURE.md)).

### 1. Cinematic Mode
The player watches a scene unfold, like a cinematic TV episode — but may still
make story-affecting choices: dialogue, whether to interrupt, whether to stay
silent, whether to look at something, whether to help, whether to trust.

### 2. Exploration Mode
The player directly controls the current character: walk, run, explore, talk,
inspect, find secrets, choose where to go, repair, heal, discover optional
events. **The player is not always told where to go** — objectives can be broad
("find a way to reach the lower city") and the *how* is theirs.

### 3. Decision Mode
Major decisions surface during conversations, exploration, emergencies,
investigations, combat, healing, repairs. Some are **time-limited**. Choices
should **not** carry obvious "good"/"bad" labels.

---

## ⏳ World Time — the story is time-based

There is **no single fixed timeline.** A hidden variable, **World Time**, tracks
how long the journey to the Heart Engine takes — potentially **weeks, months, or
nearly a year** depending on the player.

World Time advances from:
- Time spent exploring
- Missions completed vs. ignored
- How long repairs take
- How long healing takes
- Travel time and delays
- Whether characters are injured
- Whether the player stops to help people

The player does **not** move through `Chapter 1 → 2 → 3`. They move through a
**simulated span of time** that the world reacts to.

---

## 🌍 The world continues without the player

One of the most important systems. The player **cannot do everything.** While
Arlen and Lysandra help one group, elsewhere: another district may suffer, a
machine may break, a person may leave, a faction may gain power, a character may
die, a location may become inaccessible.

The player is **not expected to save everyone.** The real question they answer,
constantly, is: **"What deserves my time?"**

---

## 🗺️ Broad objectives, multiple paths

Objectives are broad, not quest-marker-narrow. E.g. **"Reach the Heart Engine"**
can be pursued as:

| Path | Approach | Consequence |
|---|---|---|
| **A — Direct** | Travel fast through danger | Arrive in weeks; miss side stories; fewer relationships; reach the Engine before the world destabilizes badly. |
| **B — Help the City** | Stop and repair major systems | Takes months; more people survive; Arlen's healing grows; more discovered. |
| **C — Follow the Mystery** | Investigate relics & history | Takes even longer; hidden history; unlocks different Heart Engine *options*. |
| **D — Focus the Relationship** | Spend time together | Romance deepens; deeper mutual understanding; some political opportunities missed. |

These are not menu picks — they're **emergent from how the player spends time.**

---

## 🔧 Arlen's abilities (unlock through story)

- **Early — Mechanic.** Repair machinery, open damaged doors, restore power, fix
  vehicles, build tools. Player believes she's simply a gifted mechanic.
- **Middle — Resonance.** Sense what is wrong in living and mechanical systems;
  inspect machines, animals, people, magical objects. The game may show a broken
  **connection**; the player must work out how to repair it.
- **Late — Healing.** Heal animals, people, magical damage, machines, ancient
  technology — but healing costs **time, energy, materials, sometimes personal
  sacrifice.** *"Do I heal this person now, or save my strength for later?"*

(Ability tiers correspond to Arlen's L1–L6 progression in the Character Bible.)

## 🩹 Healing as a choice system

Healing is **never** "press button → healed." Each serious case is a decision
with real costs. Example — a badly injured character:

| Choice | Cost / consequence |
|---|---|
| **Heal immediately** | Arlen loses energy; journey delayed; another mission may become unavailable. |
| **Take them to a doctor** | Slower; costs money; possible complications. |
| **Leave them** | They may die; their storyline ends. |
| **Experimental healing** | Might save them; might permanently change their body; might cause Arlen to lose control of her ability. |

Consequences are **real and often irreversible.**

---

## 👑 Lysandra's abilities (no magic — grown by choice)

- **Observation** — identify political connections, lies, social tension, hidden
  motives.
- **Leadership** — negotiate, organize communities, convince, forge alliances.
- **Royal Authority** — her identity can open doors, cause fear, create loyalty,
  or create danger. *The player chooses how she uses it.*

Example — a guard blocks the group:

| Choice | Consequence |
|---|---|
| **Reveal she's a princess** | Guard lets them through; news spreads that she's alive. |
| **Lie about her identity** | Stay hidden; must find another way through. |
| **Let Arlen handle it** | Arlen forms a different relationship with the guard. |

---

## ❤️ Relationship system — multi-value, not a meter

The Arlen ↔ Lysandra relationship is **not** a single romance bar. Track several
**hidden** values that move independently:

| Value | Question |
|---|---|
| **Trust** | Do they believe each other? |
| **Understanding** | Do they understand each other's history and feelings? |
| **Attraction** | Are romantic feelings developing? |
| **Resentment** | Have they hurt each other? |
| **Dependence** | Do they rely on each other too much? |

Two people can **love each other and still** have low trust, resentment, and
unresolved anger. That contradiction is the point — it makes the relationship
feel real. Story beats gate on **combinations** of these values, never one bar.

---

## 💬 Dialogue system — personality, not morality

Choices are **never** labeled good/bad. They express **personality**, and change
how the *other* character understands the speaker.

Example — Lysandra: *"Why do you hate the palace?"* Arlen may answer:

- **Honest** — *"Because people like me built it, and people like you get to live
  in it."*
- **Defensive** — *"I don't."*
- **Sarcastic** — *"I don't hate it. I just enjoy breaking things inside it."*
- **Vulnerable** — *"Because I used to believe it would help people."*

Each shifts the **Understanding** (and other) relationship values differently and
colors future dialogue.

---

## 🎬 Cinematic presentation

The game constantly moves between:
- **Playable** — the player controls the character.
- **Cinematic** — the player watches.
- **Interactive Cinematic** — the player watches but can look around, choose
  dialogue, interrupt, reach for something, make a timed choice, decide whether
  to help.

---

## ⏱️ Example mission — The Broken Lift

An old lift connects Gearmarket and Cinder Hollow. It's broken.

| Option | Time | Result |
|---|---|---|
| **Repair now** | 2 days | Districts reconnect. |
| **Find the missing part** | 1 week | Discover an abandoned workshop (bonus content). |
| **Leave it broken** | 0 days | Districts stay separated. *Later:* a medical emergency the lift could have served — people may die. |

Crucially: **the player may never learn exactly what they prevented or caused.**
That uncertainty is what makes the world feel alive.

---

## 🧭 The journey to the Heart Engine

The Engine is **not** reached at a fixed story point. A tracked value,
**Heart Engine Stability**, degrades as World Time passes. But taking longer also
means: more people helped, more relics found, Arlen more powerful, Lysandra a
better leader, romance deeper, more truth uncovered.

**The central question of the entire game:**
> *Do we hurry to save the world, or stop to save the people in front of us?*

---

## 🧠 The most important system — Consequence Chains

Choices don't just affect the next scene; they **propagate**. A single decision
should be able to ripple through many later states.

**Chain A (repair the machine):**
repair → district gets power → hospital stays open → a character survives → that
character later gives information → player finds a hidden route → reaches the
Engine faster.

**Chain B (don't repair):**
no repair → hospital loses power → the character dies → the information is never
found → player takes a different route → reaches the Engine later.

**Both stories are valid. Neither is the "wrong" story.** The engine must support
long causal chains where early choices silently reshape late content.

---

## 🎮 The core game loop

```
EXPLORE
  ↓
DISCOVER A PROBLEM
  ↓
DECIDE WHETHER TO HELP
  ↓
SPEND TIME / RESOURCES
  ↓
BUILD OR DAMAGE RELATIONSHIPS
  ↓
UNLOCK OR LOSE INFORMATION
  ↓
THE WORLD CHANGES
  ↓
CONTINUE TOWARD THE HEART ENGINE
```

---

## 🏗️ Architectural implications (engineering notes)

*This section is the bridge from design to code. It names the systems this
design demands and the order to build them.*

This is a **simulation with a narrative layer**, not a branching script. The
whole thing rests on one idea: **game state is data, and everything reacts to
data changes.** Concretely, we will need:

1. **WorldClock** — owns World Time; a single advancing value that actions add to
   (travel, repair, heal, delay). Emits ticks. *Foundational — build first.*
2. **WorldState / Blackboard** — the authoritative store of facts and flags
   ("Gearmarket lift repaired", "Elder alive", "Whisper Coin rumor known"). One
   serializable source of truth. Everything reads/writes here; nothing stores
   narrative state privately.
3. **Consequence / Event system** — rules that watch WorldState + WorldClock and
   fire effects ("if lift not repaired by day N and emergency triggers → people
   die → set flags"). This is how chains and the living world are implemented:
   data-driven rules, not hand-coded `if` ladders. *The heart of the design.*
4. **RelationshipModel** — the five independent values (Trust, Understanding,
   Attraction, Resentment, Dependence) as data; beats gate on combinations.
5. **DialogueSystem** — a data-driven conversation graph whose choices apply
   effects to WorldState + RelationshipModel; no good/bad labels.
6. **GameMode layer** — extends `GameManager` to model Cinematic / Exploration /
   Interactive-Cinematic / Decision, including timed choices.
7. **SaveSystem** — because *all* of the above is data, saving is
   "serialize WorldState + WorldClock + RelationshipModel + progress." Designing
   these as plain serializable data from day one is what makes saving tractable.

**Guiding constraint:** every system above communicates through **shared data +
signals**, never by calling into each other directly. That decoupling is the only
way a five-value relationship, a ticking world clock, and long consequence chains
can coexist without becoming unmaintainable. It's also exactly the pattern the
existing `GameManager` (one writer, many readers) already establishes.

**Recommended build order:** WorldClock → WorldState → Consequence/Event system →
RelationshipModel → Dialogue → GameMode layer → Save. Each is small on its own;
the power is emergent from their interaction — which is the whole point.
