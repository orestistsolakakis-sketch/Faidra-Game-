# Lumenfall — Architecture

*Working title. Engine: **Godot 4** · Language: **C#** (`net8.0`).*

This document is the map of the codebase. It is kept in step with the code as
systems are added. If you read one file before touching the project, read this.

## Guiding principles

1. **One writer, many readers.** High-level state has a single owner
   (`GameManager`). Everything else *reacts* to it via signals and never mutates
   another system's internals.
2. **Scenes describe layout; scripts describe behaviour.** `.tscn` files own the
   node tree and visual layout; C# owns logic. Scripts find nodes by
   `unique_name_in_owner` (`%Name`) so layout can move without breaking code.
3. **Services are autoloads.** Cross-cutting, always-on systems (state, scene
   transitions, later: audio, save, input) are Godot autoload singletons reached
   through a static `Instance`.
4. **Clean seams over cleverness.** Each system should be replaceable without a
   refactor of its neighbours.

## Folder layout

```
/                     Engine + build config (project.godot, .csproj, .sln)
/src/                 All C# source, organised by domain
  Core/               Engine-facing services and the game's spine
  UI/                 Menus, HUD, dialogue UI (behaviour only)
  World/              Areas, level logic, world objects
/scenes/              Godot .tscn scenes, mirroring src/ domains
  Boot/               Entry scene
  UI/                 Menu / HUD scenes
  World/              Area scenes
/assets/              Art, audio, fonts, shaders (source assets)
/docs/                Design + architecture documentation
```

New domains (e.g. `Dialogue/`, `Quests/`, `Save/`) get a folder under **both**
`src/` and `scenes/` so code and content stay parallel.

## Core loop (implemented)

The current backbone, exercisable end to end:

```
Main.tscn (Boot)
   └─ Boot.cs → SceneLoader.TransitionTo(MainMenu, MainMenu)
        └─ MainMenu.tscn: [Play] → SceneLoader.TransitionTo(Placeholder, Playing)
                          [Quit] → exit
             └─ Placeholder.tscn: [Esc] pause/resume · [Backspace] → MainMenu
```

### `GameState` (`src/Core/GameState.cs`)
The coarse, top-level states: `Boot, MainMenu, Loading, Playing, Paused`. Not
movement or quest state — just what decides which subsystems are live.

### `GameManager` (`src/Core/GameManager.cs`) — autoload
The single source of truth for `GameState`. Exposes `Instance`, the current
`State`, `SetState()`, `TogglePause()`, and the `StateChanged(prev, cur)` signal.
Also centralises the tree-wide pause flag. **This is the spine.**

### `SceneLoader` (`src/Core/SceneLoader.cs`) — autoload
Faded, async scene transitions via `TransitionTo(path, stateAfter)`. Owns a
top-most fade overlay and drives `GameManager` through `Loading` around each
swap. All area/menu changes go through here.

### `Boot` (`src/Core/Boot.cs`)
The main scene's script. A deliberate single entry point for future startup work
(settings, save load, splash) before handing off to the menu.

## Narrative core (implemented)

The first two pieces of the simulation from [`SYSTEMS_BIBLE.md`](SYSTEMS_BIBLE.md).
Both data classes are **pure C# (no Godot dependency)** — unit-testable and
directly serializable — with a thin autoload facade bridging them to signals.

### `WorldClock` (`src/Narrative/WorldClock.cs`)
Owns **World Time** as a `long` count of minutes. `Advance()/AdvanceHours()/
AdvanceDays()` push time forward; raises `Advanced` on any change and
`DayElapsed` once per day boundary crossed (the daily "heartbeat" the future
Consequence system will use). `Snapshot()/Restore()` for saves.

### `WorldState` (`src/Narrative/WorldState.cs`)
The authoritative **fact store**: boolean `flags` and integer `values`, with
change events that fire only on real changes. `Snapshot()/Restore()/Reset()`.

### `WorldFacts` (`src/Narrative/WorldFacts.cs`)
Named constants for every fact key — compile-time safety against typos and the
living index of tracked world state.

### Event system (`src/Narrative/Events/`)
The living world (see [`EVENT_SYSTEM_BIBLE.md`](EVENT_SYSTEM_BIBLE.md)). Also pure
C#. A **`WorldEvent`** is a definition — a `Condition` over world data, an optional
post-activation `DeadlineMinutes`, an `OnExpire` default outcome, and named player
`Outcomes`. The **`EventManager`** re-evaluates all events on any clock/state
change: dormant events whose condition is met **activate**; overdue actives
**expire**; the player **resolves** an active event by choosing an outcome. Effects
receive a **`ConsequenceContext`** (`Clock` + `State` + `Events`) so they can mutate
the world *and* unlock further events — that is how consequence **chains** form.
Evaluation loops until the world settles, so one choice ripples fully in a tick.
Runtime state (status + activation time) serializes; definitions re-register on
load. Authored content lives in `Events/Content/` (e.g. `CinderHollowEvents`).

### `World` (`src/Narrative/World.cs`) — autoload
Facade owning `Clock`, `State`, and `Events`, re-broadcasting their changes as
Godot signals (`TimeAdvanced`, `DayElapsed`, `FlagChanged`, `ValueChanged`,
`EventActivated`, `EventResolved`, `EventExpired`) and feeding every clock/state
change into `Events.Evaluate()`. `NewGame()` resets, registers content, and seeds
opening conditions. Reached via `World.Instance`.

## Autoload registration

Declared in `project.godot` under `[autoload]`, constructed top-to-bottom:
`GameManager`, `SceneLoader`, `World`.

## Roadmap (not yet built)

Planned domains, each to be designed → explained → specified → implemented,
with a checkpoint before starting the next. The narrative simulation systems are
specified in [`SYSTEMS_BIBLE.md`](SYSTEMS_BIBLE.md) — read it before building any
of them; it defines World Time, the living world, consequence chains, and the
multi-value relationship model that most of these serve.

**Gameplay:**
- **Player** — dual switchable control (Arlen / Lysandra), third-person
  controller, camera, movement upgrades.
- **Input** — named `InputMap` actions + rebinding + accessibility.
- **Interaction** — inspect / repair / heal targets in the world.
- **Abilities** — Arlen's Repair / Sense / Heal as reusable components.

**Narrative simulation** (recommended build order, per the Systems Bible):
1. **WorldClock** — the single advancing World Time value.
2. **WorldState** — authoritative serializable store of facts/flags.
3. ~~**Consequence/Event system**~~ — **implemented** (`src/Narrative/Events/`):
   data-driven rules over WorldState + WorldClock; the living world and chains.
4. **RelationshipModel** — Trust / Understanding / Attraction / Resentment /
   Dependence as independent values.
5. **Dialogue** — data-driven conversation graph applying effects to state.
6. **GameMode layer** — Cinematic / Exploration / Interactive-Cinematic /
   Decision, including timed choices; extends `GameManager`.
7. **Save/Load** — serialise WorldState + WorldClock + RelationshipModel +
   progress (tractable *because* the above are plain data).

**Later:** Quests/Journal, Inventory/Crafting, Skill Tree, Lore Database,
Achievements.

See `README.md` for how to open and run the project.
