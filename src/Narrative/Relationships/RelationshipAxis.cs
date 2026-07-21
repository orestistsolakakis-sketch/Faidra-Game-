namespace Lumenfall.Narrative.Relationships;

/// <summary>
/// The independent dimensions of a relationship (see docs/SYSTEMS_BIBLE.md,
/// "Relationship system"). They move separately on purpose: two characters can
/// love each other and still have low <see cref="Trust"/> and high
/// <see cref="Resentment"/>. Story and dialogue beats gate on COMBINATIONS of
/// these, never on a single romance meter.
/// </summary>
public enum RelationshipAxis
{
    /// <summary>Do they believe each other?</summary>
    Trust,

    /// <summary>Do they understand each other's history and feelings?</summary>
    Understanding,

    /// <summary>Are romantic feelings developing?</summary>
    Attraction,

    /// <summary>Have they hurt each other?</summary>
    Resentment,

    /// <summary>Do they rely on each other (potentially too much)?</summary>
    Dependence,
}
