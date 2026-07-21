using System;
using System.Collections.Generic;

namespace Lumenfall.Narrative.Relationships;

/// <summary>
/// The state of a single relationship between two characters: one clamped 0–100
/// value per <see cref="RelationshipAxis"/>. A plain data holder with no events
/// (the owning <see cref="RelationshipModel"/> raises change notifications) and
/// no Godot dependency, so it is trivially testable and serializable.
///
/// A relationship is symmetric here — it represents the bond between the pair,
/// not one character's private feelings. If we ever need asymmetric feelings
/// (A trusts B more than B trusts A), that becomes two directed relationships;
/// the current design keeps it symmetric because the romance is mutual by nature.
/// </summary>
public sealed class Relationship
{
    public const int Min = 0;
    public const int Max = 100;

    private readonly Dictionary<RelationshipAxis, int> _values = new();

    /// <summary>Read an axis (defaults to <see cref="Min"/> if never set).</summary>
    public int Get(RelationshipAxis axis) => _values.TryGetValue(axis, out int v) ? v : Min;

    /// <summary>
    /// Set an axis to an absolute value (clamped to 0–100). Returns true if the
    /// stored value actually changed.
    /// </summary>
    public bool Set(RelationshipAxis axis, int value)
    {
        int clamped = Math.Clamp(value, Min, Max);
        if (Get(axis) == clamped)
            return false;
        _values[axis] = clamped;
        return true;
    }

    /// <summary>Add <paramref name="delta"/> (may be negative) to an axis. Returns true if it changed.</summary>
    public bool Adjust(RelationshipAxis axis, int delta) => Set(axis, Get(axis) + delta);

    /// <summary>Capture this relationship for a save.</summary>
    public RelationshipData Snapshot() => new(new Dictionary<RelationshipAxis, int>(_values));

    /// <summary>Overwrite from a save.</summary>
    public void Restore(RelationshipData data)
    {
        _values.Clear();
        foreach ((RelationshipAxis axis, int value) in data.Values)
            _values[axis] = value;
    }
}

/// <summary>Serializable snapshot of a single <see cref="Relationship"/>.</summary>
public sealed record RelationshipData(IReadOnlyDictionary<RelationshipAxis, int> Values);
