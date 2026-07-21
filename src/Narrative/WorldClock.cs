using System;

namespace Lumenfall.Narrative;

/// <summary>
/// WorldClock owns "World Time" — the single, advancing measure of how long the
/// journey to the Heart Engine has taken (see docs/SYSTEMS_BIBLE.md). Actions in
/// the game (travelling, repairing, healing, being delayed) push time forward;
/// the world reacts to how much time has passed, not to a fixed chapter number.
///
/// DESIGN NOTES:
/// * This is a PURE C# class with NO Godot dependency. That makes it
///   unit-testable without the engine and trivial to serialize for saves. The
///   <see cref="World"/> autoload owns an instance and re-broadcasts its events
///   as Godot signals for scenes to consume.
/// * Time is stored as a <see cref="long"/> count of MINUTES. Using an integer
///   base unit avoids floating-point drift accumulating over a year of in-game
///   time; days/hours are derived views on top of it.
/// * <see cref="DayElapsed"/> is the "heartbeat" the future Consequence/Event
///   system hangs the living world off of (daily ticks that let districts
///   change, factions move, emergencies fire).
/// </summary>
public sealed class WorldClock
{
    public const int MinutesPerHour = 60;
    public const int HoursPerDay = 24;
    public const int MinutesPerDay = MinutesPerHour * HoursPerDay; // 1440

    /// <summary>Total elapsed World Time, in minutes. The single source of truth.</summary>
    public long TotalMinutes { get; private set; }

    /// <summary>Elapsed time as a fractional number of days (e.g. 3.5 = day 4, midday).</summary>
    public double TotalDays => TotalMinutes / (double)MinutesPerDay;

    /// <summary>The current day, 1-based (World Time starts on Day 1).</summary>
    public int Day => (int)(TotalMinutes / MinutesPerDay) + 1;

    /// <summary>Hour of the current day, 0–23.</summary>
    public int Hour => (int)(TotalMinutes % MinutesPerDay / MinutesPerHour);

    /// <summary>Minute of the current hour, 0–59.</summary>
    public int Minute => (int)(TotalMinutes % MinutesPerHour);

    /// <summary>Raised on any advance. Argument is the number of minutes added.</summary>
    public event Action<long>? Advanced;

    /// <summary>
    /// Raised once for EACH day boundary crossed during an advance. Argument is
    /// the newly-entered day number. A single large advance that skips several
    /// days raises this once per day so no daily tick is ever missed.
    /// </summary>
    public event Action<int>? DayElapsed;

    /// <summary>
    /// Advance World Time by <paramref name="minutes"/> (must be &gt;= 0).
    /// Fires <see cref="Advanced"/> once, then <see cref="DayElapsed"/> for every
    /// day boundary crossed.
    /// </summary>
    public void Advance(long minutes)
    {
        if (minutes < 0)
            throw new ArgumentOutOfRangeException(nameof(minutes), "World Time cannot move backwards.");
        if (minutes == 0)
            return;

        int previousDay = Day;
        TotalMinutes += minutes;
        int currentDay = Day;

        Advanced?.Invoke(minutes);

        for (int day = previousDay + 1; day <= currentDay; day++)
            DayElapsed?.Invoke(day);
    }

    /// <summary>Advance by whole/fractional hours (rounded to the nearest minute).</summary>
    public void AdvanceHours(double hours) => Advance((long)Math.Round(hours * MinutesPerHour));

    /// <summary>Advance by whole/fractional days (rounded to the nearest minute).</summary>
    public void AdvanceDays(double days) => Advance((long)Math.Round(days * MinutesPerDay));

    /// <summary>Human-readable form, e.g. "Day 12 · 14:05". For debug/UI/journal.</summary>
    public string ToDisplayString() => $"Day {Day} · {Hour:D2}:{Minute:D2}";

    // --- Serialization -------------------------------------------------------
    // The clock's entire state is a single number, so saving/loading is a copy.
    // Kept as explicit methods (rather than exposing a setter) so restoring from
    // a save is an obvious, intentional operation, distinct from advancing time.

    /// <summary>Capture the clock's state for a save file.</summary>
    public WorldClockData Snapshot() => new(TotalMinutes);

    /// <summary>Overwrite the clock from a loaded save. Fires no events.</summary>
    public void Restore(WorldClockData data) => TotalMinutes = data.TotalMinutes;
}

/// <summary>Serializable snapshot of a <see cref="WorldClock"/>.</summary>
public readonly record struct WorldClockData(long TotalMinutes);
