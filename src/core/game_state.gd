class_name GameState
## The coarse, top-level states of the whole game (see docs/ARCHITECTURE.md).
## Not movement or quest state — just what decides which subsystems are active.
## Used as GameState.PLAYING etc.

enum { BOOT, MAIN_MENU, LOADING, PLAYING, PAUSED }
