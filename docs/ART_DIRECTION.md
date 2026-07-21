# The Heart Engine — Art Direction / Visual Identity

> **Canonical visual bible.** The look everything is built toward. Original —
> never copying any existing franchise. Consistent with
> [`WORLD_BIBLE.md`](WORLD_BIBLE.md), [`UI_UX_BIBLE.md`](UI_UX_BIBLE.md), and the
> levels.

## Fidelity target (updated)

**Stylized realism (cinematic middle ground)** — the atmosphere, mood and
lighting of the reference feel (Detroit: Become Human-class presentation), but
proportions/materials **slightly stylized** rather than fully photoreal. This is
the chosen target: it keeps the cinematic weight while staying **achievable for a
small team** (photoreal is the costliest thing to execute well; a stylized-real
hybrid is far more attainable and ages better). Executed **originally**. It is the
North Star for concept art and final assets, reached via a real pipeline (concept
art → modeled/textured assets → PBR + volumetric lighting → post), not achievable
with the current greybox blockouts — which hold the *composition, palette and
lighting* until real assets exist.

## One-line identity

**Warm amber lamplight and cold magical glow sharing every frame** — brass and
worn copper machinery threaded with living currents of light, in a lived-in,
grimy, verticality-stacked capital, under low-key cinematic lighting and haze.

## The core visual tension (our signature)

Every important image should hold **two light sources in opposition**:

- **Warm amber / firelight** — lamps, forges, windows, human warmth, the surface
  world. `#F4B860` → `#E8823C`.
- **Cold magical glow** — the **Lifelines** (magic currents), crystals, the Heart
  Engine, the deep places. **Teal** `#4FD6C3` and **violet** `#A98BFF`.

Where they meet is where the story lives (magic + machinery, poverty + power).
Neutrals are **desaturated cool** so the two accents pop.

## Palette

| Role | Color | Hex |
|---|---|---|
| Deep base / shadow | near-black blue | `#0D1017` |
| Cool neutral (stone, metal) | slate | `#242A33` / `#3A424E` |
| Warm light (key) | amber | `#F4B860` |
| Warm accent (rust, copper) | burnt orange | `#E8823C` |
| Magic — Life/stability | teal | `#4FD6C3` |
| Magic — Memory/fate | violet | `#A98BFF` |
| Warning / instability | hot magenta-red | `#FF5C7A` |
| Highlight / spark | pale gold | `#FFD27A` |

## Lighting model

- **Low-key, high-contrast.** Darkness is the default; light is precious and
  motivated (a lamp, a crystal, an open furnace).
- **Bloom/glow on all magical emission** — Lifelines and crystals *radiate*.
- **Volumetric haze / light fog** in interiors and tunnels for depth and mood.
- **Rim lighting** on characters from the cold source so they read against dark
  backgrounds — the painterly, cinematic separation.
- Filmic tone mapping; slightly crushed blacks; warm-cool color grading.

## Material language

Everything is **repaired, aged, hand-made** (WB §14) — nothing pristine:

- **Brass & copper**, oxidised to green-blue at the edges; visible rivets, seams,
  patched plating.
- **Iron & cast steel**, scratched, oil-streaked.
- **Crystal & glass** — the conductive magic material; internally lit, faceted.
- **Living Lifeline matter** — glowing veins that run *through* stone, wood, metal,
  and flesh; teal when healthy, magenta when unstable.
- **Cloth & leather** — worn workwear for the lower city; finer brocade for the
  Crownspire.

## Style rules (the painterly look, originally)

- **Stylized, not photoreal.** Simplified, confident shapes; texture that reads as
  *painted*, not scanned. Soft edges, visible "brushwork" in surfaces and skies.
- **Strong silhouettes first.** Every character and prop must read as a black
  shape. Shape language carries identity before detail.
- **Exaggerated, expressive proportions** for characters (see below) — appeal over
  realism.
- **Cinematic vistas**: big scale contrast — tiny figures against vast machinery,
  floating islands, cavern-cathedrals.
- **Distinct architecture**: verticality, additive/patched construction (buildings
  grown over older buildings), pipework as ornament.

## Character silhouette direction

Proportions: grounded-heroic, slightly stylized (larger hands/features than
strict realism, for expressiveness). Each lead owns **one color** so they read
instantly, even as blockouts:

- **Arlen** — tall (6'1"), practical, layered mechanic's workwear; tool-belt,
  rolled sleeves, goggles pushed up. **Warm amber/copper** identity. Silhouette:
  broad, capable, asymmetric (tools, satchel).
- **Lysandra** — poised, deliberate; refined lines corrupted by travel wear (royal
  cut, but dusty and practical now). **Cool blue/violet** identity. Silhouette:
  upright, clean, a deliberate contrast to Arlen.

The **color opposition between the two leads** (warm vs cool) mirrors the whole
game's light tension — put them in frame together and they *are* the theme.

## Creatures & magic FX

- Creatures: original, not-quite-natural — bioluminescent Lifeline markings,
  asymmetric, uncanny but not gory (light-horror). Read as *made of the same
  magic* as the world.
- Magic FX: flowing, particulate, light-based — currents, motes, faceted shards;
  teal/violet by default, magenta when unstable.

## How this maps to the current build (blockout stage)

The in-engine sandbox is a **stylized greybox**: proportioned humanoid blockouts
in each lead's signature color, a lamplit Cinder-Hollow street with warm lamps,
cold Lifeline glow, haze, and glow/bloom — the *lighting identity* is real even
though the models are placeholder. Concept art and final models replace the
blockouts later; the palette, lighting, and silhouettes defined here do not change.
