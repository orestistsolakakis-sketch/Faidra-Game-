# Cinder Hollow — Environment & Level Design Bible

> **Canonical environment vision** for the opening district. The goal, above all:
> when the player first enters, they think **"this city existed long before I
> arrived."** Lived-in, believable, emotionally memorable — never a "video game
> level." Complements the gameplay beats in
> [`01_CINDER_HOLLOW.md`](01_CINDER_HOLLOW.md), the look in
> [`ART_DIRECTION.md`](../ART_DIRECTION.md), and the interface in
> [`UI_UX_BIBLE.md`](../UI_UX_BIBLE.md).

## Reference cluster (feel, never copied)

Dishonored · Arcane's Zaun · Lies of P · FFVII Midgar slums. Take the *lived-in,
hand-repaired, vertical industrial decay* — but Cinder Hollow must feel **unique**.

## Core principle

An old industrial district **repaired and rebuilt by generations of mechanics,
not architects.** Everything looks **hand-built**; nothing modern; everything has
history. Buildings grew over older buildings; every surface has been patched.

## Scale & exploration

Large enough for **30–60 minutes** of exploration. **No empty streets** — every
path rewards curiosity, and every route eventually **reconnects** (a branching
web, never dead ends). Must include: a main street, multiple narrow alleys,
rooftops, underground tunnels, steam pipes, bridges, catwalks, hidden shortcuts,
secret rooms, and constant **vertical** discovery.

## Architecture & materials

Old brick, iron, copper, weathered steel, stone foundations, reclaimed machinery,
wooden repairs, broken windows patched with metal, roofs joined by bridges, large
exposed pipes, **rust everywhere**, steam vents, dripping water, visible gears,
large chimneys. **Nothing appears clean.**

## Environmental storytelling (every building tells a story)

A bakery with steam-powered ovens; a mechanic shop inside an abandoned boiler
room; children playing beside broken machines; someone growing plants on steam
heat; homes built atop factories; broken statues repaired with metal; graffiti
against the crown ("Kaufstein doesn't care about us"); worker memorials; old
propaganda posters; handmade signs; abandoned workshops.

## Lighting

Warm orange street lamps; steam catching light; blue moonlight at night;
volumetric fog; industrial smoke; moving shadows from machinery. **Interiors glow
warm; exterior streets feel colder** — the warm/cold tension of the art bible.

## Ambient life (nothing static)

Steam escaping pipes, rotating fans, moving gears, loose chains, birds, cats,
running water, smoke stacks, distant machinery, people working, wind moving hung
fabric, occasional sparks.

## Vertical gameplay

Multiple elevations — ground level, raised walkways, rooftops, factory interiors,
water canals, underground maintenance tunnels. The player is **constantly moving
up and down.**

## Traversal toolkit

Jump routes, ladders, broken elevators, moving platforms, collapsed bridges, pipe
climbing, shortcut doors, hidden passages. Every path reconnects.

## Named gameplay spaces

Mechanic Workshop · Marketplace · Scrapyard · Public Square · Steam Lift · Water
Pump Station · Hospital · Clock Tower · Old Factory · Machine Graveyard ·
Abandoned Rail Station · Residential District · Underground Boiler Network ·
**Secret Healer Shrine** · **Hidden Relic Vault**.

*(The Healer Shrine and Relic Vault tie directly into the world's hidden healer
bloodline and the Seven Relics — prime secret-reward content.)*

## NPC activity (believable tasks)

Repairing machines, selling food, arguing, children playing, cleaning streets,
delivering supplies, fixing pipes, cooking, talking, playing music, walking pets.

## Interactive density

Every few meters, something to discover: a broken machine, collectable parts, a
hidden journal, a steam valve, a locked door, a repair opportunity, a hidden
relic, a conversation, an animal, a workbench, a secret switch, a movable crate.

## Audio (alive without music)

Distant machinery, steam pressure, creaking metal, footsteps on metal, whistling
pipes, dripping water, market chatter, factory noise, wind, birds, mechanical hum.

## Performance / engine note

The original brief specified UE5 (Nanite / Lumen / Level Streaming). **The project
is currently Godot 4 (GDScript), chosen for web export.** This is an open
engine decision (see the working notes / project lead). Whatever the engine:
**modular, reused, intelligently-instanced assets**, streamed/occluded by area,
smooth performance. In Godot the equivalents are GPUParticles for steam/sparks,
SDFGI/VoxelGI + volumetric fog for lighting, MultiMesh for repeated props, and
scene/area streaming.

## Production reality (honest)

This is a **AAA-scale, months-of-art-team** environment. It is built in stages:
1. **Greybox / blockout** — full layout, scale, verticality, traversal,
   interactable placement, ambient *motion* (fans, steam, platforms). Playable,
   ugly. *(This is the stage the project can reach now, in engine, for free.)*
2. **Concept art** — key locations painted to this brief (needs image budget or
   an artist).
3. **Modular asset kit** — brick/iron/pipe/machinery modules modeled & textured.
4. **Set dressing, lighting, audio, ambient VFX** — the pass that makes it look
   like the references.

The greybox is not a lesser version — it is the **correct first stage** every
studio builds, and it locks the level design this document specifies.
