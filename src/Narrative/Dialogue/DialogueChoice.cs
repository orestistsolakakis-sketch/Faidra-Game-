using System;
using Lumenfall.Narrative.Events;

namespace Lumenfall.Narrative.Dialogue;

/// <summary>
/// The intent behind a choice (see docs/DIALOGUE_SYSTEM_BIBLE.md). Never
/// good/bad — a flavour tag the UI can show and content can key off. Silence is a
/// first-class option, not a fallback.
/// </summary>
public enum DialogueTone
{
    Neutral,
    Honest,
    Defensive,
    Sarcastic,
    Vulnerable,
    Silence,
    Confront,
}

/// <summary>
/// One player option on a <see cref="DialogueNode"/>. It carries its intent, an
/// optional availability condition (knowledge/relationship gating), the effect it
/// applies to the world (relationships, flags, personality, events — all through
/// <see cref="ConsequenceContext"/>), and where the conversation goes next.
/// </summary>
public sealed class DialogueChoice
{
    /// <summary>The text shown to the player for this option.</summary>
    public required string Label { get; init; }

    /// <summary>Intent tag (for UI styling and content queries).</summary>
    public DialogueTone Tone { get; init; } = DialogueTone.Neutral;

    /// <summary>
    /// Optional gate: return false to hide this choice (e.g. it needs discovered
    /// knowledge, or a relationship threshold). Null means always available.
    /// </summary>
    public Func<ConsequenceContext, bool>? Available { get; init; }

    /// <summary>
    /// The consequence of choosing this option: shift relationships, set memory
    /// flags, add personality weight, unlock events. Null means "no direct effect"
    /// (the choice still steers the conversation).
    /// </summary>
    public Action<ConsequenceContext>? Effect { get; init; }

    /// <summary>Id of the next node, or null to end the scene after this choice.</summary>
    public string? Next { get; init; }
}
