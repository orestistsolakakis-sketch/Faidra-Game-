using Lumenfall.Narrative.Events;
using Lumenfall.Narrative.Personality;
using Lumenfall.Narrative.Relationships;

namespace Lumenfall.Narrative.Save;

/// <summary>
/// The complete serializable snapshot of a play-through — literally the
/// <c>Snapshot()</c> of every simulation system bundled together, plus a little
/// metadata for the save/load UI.
///
/// This record is only assemble-able because every system was designed as plain,
/// serializable data from day one (see docs/SYSTEMS_BIBLE.md). Saving is not a
/// bespoke traversal of the game — it is a shallow copy of state that already
/// knows how to describe itself. That up-front discipline is what makes this file
/// tiny.
/// </summary>
public sealed record SaveData(
    int Version,
    string SavedAtIso,
    string WorldTimeDisplay,
    WorldClockData Clock,
    WorldStateData State,
    EventManagerData Events,
    RelationshipModelData Relationships,
    PersonalityData Personality)
{
    /// <summary>Bump when the save shape changes incompatibly; enables migration later.</summary>
    public const int CurrentVersion = 1;
}
