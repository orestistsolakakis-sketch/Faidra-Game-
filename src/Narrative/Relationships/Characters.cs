namespace Lumenfall.Narrative.Relationships;

/// <summary>
/// The registry of character ids used as relationship endpoints (and, later, as
/// dialogue speakers and event participants). Same rationale as
/// <see cref="Lumenfall.Narrative.WorldFacts"/>: funnelling ids through named
/// constants gives compile-time safety and one authoritative list, so a typo
/// can't silently create a relationship with a character who doesn't exist.
///
/// Ids are stable snake_case strings — they appear in save files, so renaming a
/// display name never has to touch them. Supporting cast are seeded as their
/// roles until named (see docs/CHARACTER_BIBLE.md open threads).
/// </summary>
public static class Characters
{
    /// <summary>Arlen Naomi Kufstein — protagonist (healer bloodline).</summary>
    public const string Arlen = "arlen";

    /// <summary>Lysandra Kufstein — co-lead / romance (royal branch).</summary>
    public const string Lysandra = "lysandra";

    /// <summary>Arlen's best friend from Cinder Hollow (name TBD).</summary>
    public const string ArlenBestFriend = "arlen_best_friend";

    /// <summary>Lysandra's childhood friend from the Crownspire (name TBD).</summary>
    public const string LysandraChildhoodFriend = "lysandra_childhood_friend";

    /// <summary>Arlen's former lover (name TBD) — understands her better than most.</summary>
    public const string ArlenFormerLover = "arlen_former_lover";

    /// <summary>Lysandra's former expected partner from the royal world (name TBD).</summary>
    public const string LysandraFormerMatch = "lysandra_former_match";
}
