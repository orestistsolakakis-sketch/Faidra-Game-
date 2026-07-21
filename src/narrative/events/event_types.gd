class_name EventTypes
## Enums for the event system (see docs/EVENT_SYSTEM_BIBLE.md). Access as
## EventTypes.Status.ACTIVE etc.

## Scope of an event.
enum Category { PERSONAL, LOCAL, POLITICAL, WORLD }

## How far a consequence reaches. Use the smallest that fits.
enum Level { IMMEDIATE, SHORT_TERM, LONG_TERM, PERMANENT }

## Lifecycle: DORMANT -> ACTIVE -> (RESOLVED by player | EXPIRED by deadline).
enum Status { DORMANT, ACTIVE, RESOLVED, EXPIRED }
