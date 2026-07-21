namespace Lumenfall.Narrative.Events;

/// <summary>
/// The scope of an event (see docs/EVENT_SYSTEM_BIBLE.md, "Event types").
/// Used for filtering, journal grouping, and tuning how loudly the world reacts.
/// </summary>
public enum EventCategory
{
    /// <summary>Involves an individual character (sickness, injury, leaving, betrayal).</summary>
    Personal,

    /// <summary>Affects a specific location (power loss, collapse, disease, closure).</summary>
    Local,

    /// <summary>Factions and governments; the player usually influences these indirectly.</summary>
    Political,

    /// <summary>Global and permanent (Heart Engine stability, magical storms, a lost relic).</summary>
    World,
}

/// <summary>
/// How far a consequence reaches (see docs/EVENT_SYSTEM_BIBLE.md, "Consequence
/// levels"). Not every choice needs to be Permanent — use the smallest that fits.
/// </summary>
public enum ConsequenceLevel
{
    /// <summary>Changes the current scene only.</summary>
    Immediate,

    /// <summary>Changes the next few missions.</summary>
    ShortTerm,

    /// <summary>Changes later chapters.</summary>
    LongTerm,

    /// <summary>Changes the ending; permanently alters the world.</summary>
    Permanent,
}

/// <summary>
/// Lifecycle of a <see cref="WorldEvent"/>:
/// Dormant → Active → (Resolved by the player | Expired by its deadline).
/// </summary>
public enum EventStatus
{
    /// <summary>Waiting; its activation condition is not yet met.</summary>
    Dormant,

    /// <summary>Live and awaiting resolution; its deadline (if any) is counting down.</summary>
    Active,

    /// <summary>The player chose one of its outcomes.</summary>
    Resolved,

    /// <summary>Its deadline passed unresolved; the default outcome was applied.</summary>
    Expired,
}
