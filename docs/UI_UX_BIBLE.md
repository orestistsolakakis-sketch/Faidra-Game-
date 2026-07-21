# The Heart Engine — UI / UX & Presentation Bible

> **Canonical interface & feel design.** The game is cinematic and diegetic —
> the UI stays out of the way and the *world* communicates state. The player
> should feel like they're **directing a film**, not reading an RPG dashboard.
> Numbers are hidden; feeling is shown. Consistent with
> [`ART_DIRECTION.md`](ART_DIRECTION.md) and [`SYSTEMS_BIBLE.md`](SYSTEMS_BIBLE.md).

## Fidelity & tone target

**Cinematic realism** — atmospheric, painterly-realistic, moody (reference feel:
Detroit: Become Human-class presentation), executed **originally**. Restrained,
elegant, gold-on-dark chrome; serif display type for headers; thin rules and
small caps. The HUD in key art is a *maximum* (menus/status screens); normal
play shows **far less**.

---

## 1. Normal exploration HUD (≈90% of play)

Almost nothing is always visible:

- a small **interaction reticle** (center dot),
- the **current playable character** name (corner),
- the **current day / season** (corner),
- optionally a **tiny objective** line (toggleable).

**No** giant minimap, quest list, or health bar during exploration.

```
┌──────────────────────────────────────────────┐
│                                              │
│                        ○                     │
│                                              │
│ Arlen & Lysandra                     Day 42  │
└──────────────────────────────────────────────┘
```

## 2. Context interaction

Prompts appear **only while looking directly at** an interactable, next to it in
the world — never a permanent button bar.

```
Old Steam Lift
○ Inspect   △ Repair   □ Leave
```
```
Broken Toy
○ Pick Up   △ Heal   □ Ignore
```

Verbs are contextual (Repair vs Heal vs Pick Up) and driven by what Arlen can
currently do.

## 3. Relationship pop-ups (never numbers)

No `+10 Romance`. Instead, small text that fades:

> *Lysandra noticed.*  ·  *Trust deepened.*
> *Arlen remembered.*
> *She didn't answer.*

The player never sees a meter. (Backed by the six-axis RelationshipModel, but
surfaced only as feeling.)

## 4. World-change notifications

When the world changes elsewhere (the living world / event system), a brief
top-left card appears — enough to make the player *wonder*, never a full
explanation:

```
WORLD UPDATED
Gearmarket — Power Restored
```
```
WORLD UPDATED
Crownspire — Political Tension Increased
```

## 5. Arlen — Healing / Mechanic Vision (the signature feature)

Ability level is **shown in the world, never as "Level 5."** Activating
perception recolors the scene:

- machines show **glowing veins**, steam pressure, power lines, leaks, hidden
  wiring; broken parts glow **crimson**, healthy parts **gold**;
- people show glowing nerves; plants glow green; animals pulse softly.

**It evolves as she grows** — the clearest expression of her arc:
- early: she perceives **only machines**;
- later: tiny **plants** glow around her;
- then **injured animals**;
- then **people**;
- by the end, walking through a town she instinctively sees **every damaged
  living thing and broken machine linked by faint golden Lifelines.**

The player never reads a progress bar — they *see* that Arlen has changed, and it
reinforces the theme: she's learning to **mend a broken world**, not just growing
more powerful. **This is the game's defining UI/mechanic idea.**

## 6. Lysandra — Observation Mode

Not magic. On activation, **time slows** and the world annotates the details
other people miss: micro-expressions, shaking hands, royal jewelry, hidden
insignias, bloodstains, scratches, footprints, political symbols. Her power is
*perception of systems and people*, made visible.

## 7. Dialogue UI

Minimal — no giant boxes. Speaker name + line; choices listed beside them.
Timed choices show a small, elegant **shrinking circle**, nothing flashy.

```
Lysandra
"...why didn't you tell me?"

  Tell the truth
  Lie
  Stay silent
  Walk away
```

## 8. Time passing

Never `+3 Days`. The camera lingers — leaves fall, people work, clouds move,
street lamps light, steam rises — then fade to:

> *Three Days Later*

## 9. Journal (Arlen's notebook)

Not a quest log — Arlen **sketches**. Contains machine diagrams, maps, pressed
flowers, relic drawings, letters, photos, notes, recipes, people, rumors. Reads
like her personal notebook.

## 10. World map

Text-forward, not icon soup. Districts with a one-line state; the player chooses
where to travel:

```
Crownspire     ▲ Political unrest
Gearmarket       Power stable
Cinder Hollow    Food shortage
Ash Fields       Unknown
```

## 11. Relationship page

Not `Romance: 74%` — a list of **memories**:

> Shared an umbrella during the rain. · Stayed beside Arlen after the collapse. ·
> First dance. · First argument. · She trusted you with the royal seal.

The relationship reads as *actual remembered moments*.

## 12. Inventory / Relics

Not a grid — each of the **Seven Relics** displayed like a **museum collection**:
description, history, who owned it, known abilities, unknown abilities, sketches,
lore. (Maps directly to the relics in `WORLD_BIBLE.md`.)

## 13. Rumor board

As the player helps people, the journal fills with rumors — **some true, some
not**:

> A healer was seen... · Someone found another relic. · The palace is searching
> for someone. · A bridge collapsed. · The Continuance recruited new members.

## 14. Choice recap

After important scenes, a subtle card — **and sometimes nothing at all** (the
game never tells you the consequence):

```
CHOICE RECORDED
You repaired the East Lift.
Cinder Hollow can now reach Gearmarket.
```

## 15. Emotional music layer (adaptive)

Music responds to **hidden** relationship values: as Arlen and Lysandra grow
closer, extra instruments enter; as they drift, it thins out. No dialogue needed —
the player *feels* the relationship shifting.

## 16. Cinematic camera (a key differentiator)

The camera is **directed**, not just a follow-cam:
- Crownspire boulevard → wide establishing shot;
- rooftops → low angle;
- entering the Heart Engine → massive zoom-out;
- conversation → close-up faces;
- rain / tension → follow-behind with slight handheld shake.

The player experiences scenes like a film.

---

## 🏗️ Implementation notes (engineering)

Every element above is backed by data we already have, so the UI is a *view*:

- **Exploration HUD, popups, toasts** — a `Hud` CanvasLayer with small `Control`
  widgets that subscribe to existing signals: `World.clock` (day), `RelationshipModel.
  changed` → fading "noticed/remembered" lines, `EventManager.event_activated/
  resolved` → "WORLD UPDATED" cards, `DialogueRunner` → the dialogue panel.
- **Context interaction** — an Interaction system (raycast from camera / reticle)
  that shows verb prompts for the looked-at object; verbs come from Arlen's
  current ability tier.
- **Healing/Mechanic Vision & Observation Mode** — full-screen post-process
  **shaders** (screen-space recolor + highlight of tagged objects), gated by
  ability tier / GameMode. The evolving perception is driven by a "vision tier"
  value in WorldState.
- **Time-passing & cinematic camera** — a camera director that swaps virtual
  camera rigs per context; time-skips play a short montage then a title card.
- **Journal / Map / Relationships / Inventory / Rumors** — menu screens reading
  WorldState, RelationshipModel, event history, and a lore/relic database.

**Build order (proposed):** minimal exploration HUD → context interaction →
subtle relationship/world toasts → cinematic dialogue panel → time-skip cards →
(later, bigger) menu screens, healing-vision shader, camera director.

The **look** (photoreal fidelity) is a separate art-production track; this UI
layer makes the game *feel* like the target while that art matures.
