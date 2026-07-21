# Lumenfall *(working title)*

A 3D story-driven adventure of ancient magic and forgotten technology —
cinematic storytelling, exploration rewarded with hidden lore, environmental
puzzles, and choices that shape relationships and endings. An original world;
no borrowed characters, lore, or content.

> **Status:** early foundation. The project skeleton and core game loop
> (boot → menu → gameplay → pause → menu) are in place. See
> [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Tech

- **Engine:** Godot 4.3+
- **Language:** C# (`net8.0`) — chosen for a large, multi-system codebase
- **Renderer:** Forward+

## Getting started

1. Install the **.NET (C#) build** of Godot 4.3 or newer, plus the .NET 8 SDK.
2. Open `project.godot` in the Godot editor.
3. Let it build the C# solution (`Lumenfall.sln`) on first open.
4. Press **Play** (F5). You should see the title screen → **Play** drops you into
   a placeholder area; **Esc** pauses, **Backspace** returns to the menu.

## Layout

```
src/     C# source by domain (Core, UI, World, …)
scenes/  Godot scenes mirroring src/
assets/  Art, audio, fonts, shaders
docs/    Design & architecture docs
```

Full detail in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Development approach

Systems are built one at a time: **design → explain → list files → implement →
review**, with a checkpoint before starting the next major system.
