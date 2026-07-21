using System;
using System.Collections.Generic;
using Lumenfall.Narrative.Events;

namespace Lumenfall.Narrative.Dialogue;

/// <summary>
/// One beat of a conversation: a spoken line plus what follows it. A node either
/// auto-advances (<see cref="Next"/>) or offers <see cref="Choices"/>.
///
/// Two features from the bible are built in:
/// * CONDITIONAL TEXT VARIANTS — the same beat can read differently based on world
///   state (high vs. low Trust), so "the same line means something different
///   later" is authorable. The first variant whose condition matches wins;
///   otherwise <see cref="Text"/> is used.
/// * TIMED CHOICES — <see cref="TimeLimitSeconds"/> plus
///   <see cref="DefaultChoiceIndex"/> let the presenter auto-pick if the player
///   hesitates. Timing out is itself a choice.
/// </summary>
public sealed class DialogueNode
{
    /// <summary>Unique within its scene.</summary>
    public required string Id { get; init; }

    /// <summary>Speaking character id (empty for narration/stage direction).</summary>
    public string Speaker { get; init; } = "";

    /// <summary>Default spoken text (used when no variant matches).</summary>
    public required string Text { get; init; }

    /// <summary>
    /// Optional state-dependent rewrites of this line, tried in order. The first
    /// whose condition returns true replaces <see cref="Text"/>.
    /// </summary>
    public IReadOnlyList<DialogueTextVariant> TextVariants { get; init; } = Array.Empty<DialogueTextVariant>();

    /// <summary>Optional effect applied the moment this line is entered.</summary>
    public Action<ConsequenceContext>? OnEnter { get; init; }

    /// <summary>Player options. If empty, the node auto-advances via <see cref="Next"/>.</summary>
    public IReadOnlyList<DialogueChoice> Choices { get; init; } = Array.Empty<DialogueChoice>();

    /// <summary>Next node id when there are no choices. Null ends the scene.</summary>
    public string? Next { get; init; }

    /// <summary>If set, the choice timer (seconds) before the default is auto-selected.</summary>
    public double? TimeLimitSeconds { get; init; }

    /// <summary>
    /// Index into the *available* choices auto-selected on timeout (default 0).
    /// Point this at a "say nothing / freeze" option for emergencies.
    /// </summary>
    public int DefaultChoiceIndex { get; init; }
}

/// <summary>A conditional rewrite of a node's line.</summary>
public sealed class DialogueTextVariant
{
    /// <summary>When this returns true, <see cref="Text"/> replaces the node's default.</summary>
    public required Func<ConsequenceContext, bool> When { get; init; }

    public required string Text { get; init; }
}
