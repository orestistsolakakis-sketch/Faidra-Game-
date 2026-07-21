using System;
using System.Collections.Generic;

namespace Lumenfall.Narrative;

/// <summary>
/// WorldState is the authoritative, serializable store of "facts" about the
/// world — the single source of truth that every narrative system reads and
/// writes (see docs/SYSTEMS_BIBLE.md, "Architectural implications").
///
/// WHY IT EXISTS:
/// The whole game is a simulation, not a branching script. Instead of hand-coded
/// "if you chose X play scene Y" ladders, systems store plain facts here
/// (<c>lift_gearmarket_repaired = false</c>, <c>elder_alive = true</c>,
/// <c>continuance_influence = 3</c>) and RULES react to those facts. That is what
/// makes consequence chains and the living world possible — and, because it is
/// all plain data, it is also what makes saving the game tractable.
///
/// Two kinds of fact:
/// * FLAGS  — booleans ("did this happen?", "is this true?").
/// * VALUES — integers ("how much?", "how many?"): faction influence, counters,
///   reputations, stability sub-scores.
///
/// PURE C# with no Godot dependency, for testability and serialization. The
/// <see cref="World"/> autoload owns an instance and re-broadcasts changes as
/// Godot signals. Use the <see cref="WorldFacts"/> constants for keys — never
/// raw magic strings — so a typo can't silently create a second, dead fact.
/// </summary>
public sealed class WorldState
{
    private readonly Dictionary<string, bool> _flags = new();
    private readonly Dictionary<string, int> _values = new();

    /// <summary>Raised when a flag's value actually changes. Argument is the key.</summary>
    public event Action<string>? FlagChanged;

    /// <summary>Raised when a value actually changes. Argument is the key.</summary>
    public event Action<string>? ValueChanged;

    // --- Flags ---------------------------------------------------------------

    /// <summary>Read a flag. Unknown keys default to <c>false</c> (nothing has happened yet).</summary>
    public bool GetFlag(string key) => _flags.TryGetValue(key, out bool v) && v;

    /// <summary>Set a flag. Fires <see cref="FlagChanged"/> only if it actually changed.</summary>
    public void SetFlag(string key, bool value = true)
    {
        if (GetFlag(key) == value)
            return;
        _flags[key] = value;
        FlagChanged?.Invoke(key);
    }

    // --- Values --------------------------------------------------------------

    /// <summary>Read a value. Unknown keys default to <c>0</c>.</summary>
    public int GetValue(string key) => _values.TryGetValue(key, out int v) ? v : 0;

    /// <summary>Set a value. Fires <see cref="ValueChanged"/> only if it actually changed.</summary>
    public void SetValue(string key, int value)
    {
        if (GetValue(key) == value)
            return;
        _values[key] = value;
        ValueChanged?.Invoke(key);
    }

    /// <summary>Add <paramref name="delta"/> to a value (may be negative). Returns the new total.</summary>
    public int AddValue(string key, int delta)
    {
        int next = GetValue(key) + delta;
        SetValue(key, next);
        return next;
    }

    // --- Serialization -------------------------------------------------------

    /// <summary>Capture the full fact store for a save file (defensive copies).</summary>
    public WorldStateData Snapshot() =>
        new(new Dictionary<string, bool>(_flags), new Dictionary<string, int>(_values));

    /// <summary>Replace the fact store from a loaded save. Fires no change events.</summary>
    public void Restore(WorldStateData data)
    {
        _flags.Clear();
        foreach ((string key, bool value) in data.Flags)
            _flags[key] = value;

        _values.Clear();
        foreach ((string key, int value) in data.Values)
            _values[key] = value;
    }

    /// <summary>Clear all facts (used when starting a new game).</summary>
    public void Reset()
    {
        _flags.Clear();
        _values.Clear();
    }
}

/// <summary>Serializable snapshot of a <see cref="WorldState"/>.</summary>
public sealed record WorldStateData(
    IReadOnlyDictionary<string, bool> Flags,
    IReadOnlyDictionary<string, int> Values);
