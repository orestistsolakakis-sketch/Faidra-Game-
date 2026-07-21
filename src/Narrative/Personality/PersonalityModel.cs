using System;
using System.Collections.Generic;
using System.Linq;

namespace Lumenfall.Narrative.Personality;

/// <summary>
/// Tracks the emergent personality of each character as accumulated trait weights
/// (see docs/DIALOGUE_SYSTEM_BIBLE.md). Dialogue choice effects call
/// <see cref="Add"/> to nudge traits; later content reads <see cref="GetDominant"/>
/// or a specific trait to colour lines and behaviour. The player never sets these
/// directly — the archetype is observed, not chosen.
///
/// Pure C# with no Godot dependency; owned by the <see cref="World"/> autoload,
/// which re-broadcasts <see cref="Changed"/>. Serializable for saves.
/// </summary>
public sealed class PersonalityModel
{
    // character id -> (trait id -> weight)
    private readonly Dictionary<string, Dictionary<string, int>> _traits = new();

    /// <summary>Raised when a trait weight changes. Args: character id, trait id.</summary>
    public event Action<string, string>? Changed;

    /// <summary>Add <paramref name="weight"/> (may be negative) to a character's trait.</summary>
    public void Add(string character, string trait, int weight = 1)
    {
        if (weight == 0)
            return;
        Dictionary<string, int> traits = _traits.TryGetValue(character, out Dictionary<string, int>? t)
            ? t
            : _traits[character] = new Dictionary<string, int>();

        traits[trait] = (traits.TryGetValue(trait, out int current) ? current : 0) + weight;
        Changed?.Invoke(character, trait);
    }

    /// <summary>Current weight of one trait (0 if never touched).</summary>
    public int Get(string character, string trait) =>
        _traits.TryGetValue(character, out Dictionary<string, int>? t) && t.TryGetValue(trait, out int w) ? w : 0;

    /// <summary>
    /// The character's strongest trait id, or null if none has any weight yet.
    /// Ties resolve to the first-seen trait — deliberate: a tie means the
    /// personality hasn't committed, and content should treat it as unformed.
    /// </summary>
    public string? GetDominant(string character)
    {
        if (!_traits.TryGetValue(character, out Dictionary<string, int>? t) || t.Count == 0)
            return null;
        string? best = null;
        int bestWeight = int.MinValue;
        foreach ((string trait, int weight) in t)
        {
            if (weight > bestWeight)
            {
                best = trait;
                bestWeight = weight;
            }
        }
        return bestWeight > 0 ? best : null;
    }

    // --- Serialization -------------------------------------------------------

    /// <summary>Capture every character's traits for a save.</summary>
    public PersonalityData Snapshot()
    {
        var copy = new Dictionary<string, IReadOnlyDictionary<string, int>>();
        foreach ((string character, Dictionary<string, int> traits) in _traits)
            copy[character] = new Dictionary<string, int>(traits);
        return new PersonalityData(copy);
    }

    /// <summary>Replace all traits from a save. Fires no events.</summary>
    public void Restore(PersonalityData data)
    {
        _traits.Clear();
        foreach ((string character, IReadOnlyDictionary<string, int> traits) in data.Traits)
            _traits[character] = traits.ToDictionary(kv => kv.Key, kv => kv.Value);
    }

    /// <summary>Clear all traits (for a new game).</summary>
    public void Reset() => _traits.Clear();
}

/// <summary>Serializable snapshot of a <see cref="PersonalityModel"/>.</summary>
public sealed record PersonalityData(IReadOnlyDictionary<string, IReadOnlyDictionary<string, int>> Traits);
