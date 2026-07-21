using System;
using System.Collections.Generic;

namespace Lumenfall.Narrative.Events;

/// <summary>
/// A single event definition — a rule about the world that can activate, run on a
/// deadline, and resolve into one of several outcomes (see
/// docs/EVENT_SYSTEM_BIBLE.md, "Event anatomy"). Definitions are authored as data
/// (in content files) and are immutable; their live runtime state (status,
/// activation time) is tracked by the <see cref="EventManager"/>.
///
/// The design principle: an event is just a <see cref="Condition"/> over existing
/// world data plus a set of effects. Delayed and hidden consequences need no
/// special machinery — they are conditions over the clock and fact store.
/// </summary>
public sealed class WorldEvent
{
    /// <summary>Stable unique identifier (also the save key). Use SCREAMING_SNAKE_CASE.</summary>
    public required string Id { get; init; }

    /// <summary>Where the event happens (district/region name). Free text for now.</summary>
    public string Location { get; init; } = "";

    public EventCategory Category { get; init; } = EventCategory.Local;
    public ConsequenceLevel Level { get; init; } = ConsequenceLevel.ShortTerm;

    /// <summary>Higher priority surfaces first when several events are live at once.</summary>
    public int Priority { get; init; }

    /// <summary>
    /// Returns true when the event should activate. Evaluated against current
    /// world data on every clock/state change. Required — an event with no
    /// trigger can never fire.
    /// </summary>
    public required Func<ConsequenceContext, bool> Condition { get; init; }

    /// <summary>
    /// Optional self-resolve deadline, in minutes AFTER activation. When the clock
    /// passes this, the event expires and <see cref="OnExpire"/> is applied.
    /// Null means the event waits indefinitely for the player.
    /// </summary>
    public long? DeadlineMinutes { get; init; }

    /// <summary>Optional effect run the moment the event activates (e.g. seed sub-state).</summary>
    public Action<ConsequenceContext>? OnActivate { get; init; }

    /// <summary>
    /// The default outcome applied if the deadline passes without the player
    /// resolving it — "what happens if you do nothing." This is where the living
    /// world bites.
    /// </summary>
    public Action<ConsequenceContext>? OnExpire { get; init; }

    /// <summary>
    /// The player's available outcomes, keyed by a stable outcome id. Chosen via
    /// <see cref="EventManager.Resolve"/>. May be empty for purely ambient events
    /// that only ever activate/expire on their own.
    /// </summary>
    public IReadOnlyDictionary<string, EventOutcome> Outcomes { get; init; }
        = new Dictionary<string, EventOutcome>();
}

/// <summary>One resolvable outcome of a <see cref="WorldEvent"/>: a label + its effect.</summary>
public sealed class EventOutcome
{
    /// <summary>Player-facing description of the choice (personality/consequence, never "good"/"bad").</summary>
    public required string Label { get; init; }

    /// <summary>The effect applied to the world when this outcome is chosen.</summary>
    public required Action<ConsequenceContext> Apply { get; init; }
}
