using System;
using System.Collections.Generic;

namespace Lumenfall.Narrative.Relationships;

/// <summary>
/// Owns every <see cref="Relationship"/> in the game, keyed by an
/// order-independent pair of character ids (Arlen↔Lysandra is the same bond as
/// Lysandra↔Arlen). This is the read/write surface event outcomes and dialogue
/// choices use to move Trust, Understanding, Attraction, Resentment and
/// Dependence.
///
/// Pure C# with no Godot dependency; the <see cref="World"/> autoload owns an
/// instance and re-broadcasts <see cref="Changed"/> as a Godot signal. Relations
/// are created lazily on first access, so content never has to pre-declare pairs.
/// </summary>
public sealed class RelationshipModel
{
    private readonly Dictionary<string, Relationship> _relationships = new();

    /// <summary>
    /// Raised when an axis of a pair actually changes. Args: the two character
    /// ids (in their stored, normalized order) and the axis that moved.
    /// </summary>
    public event Action<string, string, RelationshipAxis>? Changed;

    /// <summary>Get (creating if needed) the relationship between two characters.</summary>
    public Relationship Between(string characterA, string characterB) =>
        _relationships.TryGetValue(Key(characterA, characterB, out _, out _), out Relationship? rel)
            ? rel
            : CreatePair(characterA, characterB);

    /// <summary>Read one axis of a pair.</summary>
    public int Get(string characterA, string characterB, RelationshipAxis axis) =>
        Between(characterA, characterB).Get(axis);

    /// <summary>Set one axis of a pair to an absolute value; fires <see cref="Changed"/> if it moved.</summary>
    public void Set(string characterA, string characterB, RelationshipAxis axis, int value)
    {
        if (Between(characterA, characterB).Set(axis, value))
            RaiseChanged(characterA, characterB, axis);
    }

    /// <summary>Adjust one axis of a pair by a delta; fires <see cref="Changed"/> if it moved.</summary>
    public void Adjust(string characterA, string characterB, RelationshipAxis axis, int delta)
    {
        if (Between(characterA, characterB).Adjust(axis, delta))
            RaiseChanged(characterA, characterB, axis);
    }

    // --- Serialization -------------------------------------------------------

    /// <summary>Capture every relationship for a save.</summary>
    public RelationshipModelData Snapshot()
    {
        var data = new Dictionary<string, RelationshipData>();
        foreach ((string key, Relationship rel) in _relationships)
            data[key] = rel.Snapshot();
        return new RelationshipModelData(data);
    }

    /// <summary>Replace all relationships from a save. Fires no events.</summary>
    public void Restore(RelationshipModelData data)
    {
        _relationships.Clear();
        foreach ((string key, RelationshipData relData) in data.Relationships)
        {
            var rel = new Relationship();
            rel.Restore(relData);
            _relationships[key] = rel;
        }
    }

    /// <summary>Clear all relationships (for a new game).</summary>
    public void Reset() => _relationships.Clear();

    // --- Internals -----------------------------------------------------------

    private Relationship CreatePair(string characterA, string characterB)
    {
        string key = Key(characterA, characterB, out _, out _);
        var rel = new Relationship();
        _relationships[key] = rel;
        return rel;
    }

    private void RaiseChanged(string a, string b, RelationshipAxis axis)
    {
        // Report in the normalized (stored) order so listeners get a stable pair.
        Key(a, b, out string first, out string second);
        Changed?.Invoke(first, second, axis);
    }

    /// <summary>
    /// Build the order-independent storage key and expose the normalized order,
    /// so a pair maps to one relationship regardless of argument order.
    /// </summary>
    private static string Key(string a, string b, out string first, out string second)
    {
        if (string.CompareOrdinal(a, b) <= 0)
        {
            first = a;
            second = b;
        }
        else
        {
            first = b;
            second = a;
        }
        return $"{first}|{second}";
    }
}

/// <summary>Serializable snapshot of the whole <see cref="RelationshipModel"/>.</summary>
public sealed record RelationshipModelData(IReadOnlyDictionary<string, RelationshipData> Relationships);
