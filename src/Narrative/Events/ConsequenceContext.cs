namespace Lumenfall.Narrative.Events;

/// <summary>
/// The handle passed to every event <see cref="WorldEvent.Condition"/> and every
/// effect. It exposes the whole narrative simulation so a condition can *read*
/// world facts and an effect can *change* them — and, crucially, unlock or
/// schedule further events through <see cref="Events"/>.
///
/// That last part is how consequence CHAINS are built: an effect doesn't just set
/// a flag, it can register or enable the next event, which the manager then picks
/// up. (See docs/EVENT_SYSTEM_BIBLE.md, "Event dependencies".)
/// </summary>
public sealed class ConsequenceContext
{
    /// <summary>World Time — read it in conditions, advance it in effects (e.g. a repair costs days).</summary>
    public WorldClock Clock { get; }

    /// <summary>The authoritative fact store — the substrate events react to and mutate.</summary>
    public WorldState State { get; }

    /// <summary>The event system itself, so effects can unlock/schedule further events.</summary>
    public EventManager Events { get; }

    public ConsequenceContext(WorldClock clock, WorldState state, EventManager events)
    {
        Clock = clock;
        State = state;
        Events = events;
    }
}
