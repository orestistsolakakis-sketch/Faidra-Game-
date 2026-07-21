class_name GameMode
## Interaction mode within GameState.PLAYING (see docs/SYSTEMS_BIBLE.md).
## Decides who receives input: are we driving a character, watching, or choosing?

enum { EXPLORATION, CINEMATIC, INTERACTIVE_CINEMATIC, DECISION }
