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

## Autoload registration

Declared in `project.godot` under `[autoload]`, in dependency order:
`GameManager` then `SceneLoader`.

## Roadmap (not yet built)

Planned domains, each to be designed → explained → specified → implemented,
with a checkpoint before starting the next:

- **Player** — third-person controller, camera, movement upgrades.
- **Input** — named `InputMap` actions + rebinding + accessibility.
- **Dialogue** — data-driven conversation graph + UI.
- **Quests** — quest/objective tracking + journal.
- **Relationships** — character affinity affected by choices.
- **Save/Load** — serialisation of world + progress state.
- **Inventory / Crafting**, **Skill Tree**, **Lore Database**, **Achievements**.

See `README.md` for how to open and run the project.
