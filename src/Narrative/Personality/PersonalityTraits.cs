namespace Lumenfall.Narrative.Personality;

/// <summary>
/// The registry of personality trait ids each character can accrue through the
/// player's dialogue choices (see docs/DIALOGUE_SYSTEM_BIBLE.md). The game never
/// lets the player pick a personality — choices add weight to these traits and
/// the dominant one(s) emerge. Same typo-safety rationale as
/// <see cref="Lumenfall.Narrative.WorldFacts"/>.
///
/// Trait ids are namespaced by character so the model can store all characters in
/// one map without collisions.
/// </summary>
public static class PersonalityTraits
{
    /// <summary>Arlen's emergent archetypes (Character Bible).</summary>
    public static class Arlen
    {
        public const string Protective = "arlen_protective";
        public const string Cynical = "arlen_cynical";
        public const string Compassionate = "arlen_compassionate";
        public const string SelfSacrificing = "arlen_self_sacrificing";
        public const string Independent = "arlen_independent";
    }

    /// <summary>Lysandra's emergent archetypes (kinds of leader she becomes).</summary>
    public static class Lysandra
    {
        public const string Diplomatic = "lysandra_diplomatic";
        public const string Idealistic = "lysandra_idealistic";
        public const string Political = "lysandra_political";
        public const string Rebellious = "lysandra_rebellious";
        public const string Compassionate = "lysandra_compassionate";
        public const string Authoritarian = "lysandra_authoritarian";
    }
}
