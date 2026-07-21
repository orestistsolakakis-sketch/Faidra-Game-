using System;
using System.Collections.Generic;
using Lumenfall.Narrative.Events;

namespace Lumenfall.Narrative.Dialogue;

/// <summary>
/// A whole conversation: its identity, who is in it, when it may play, and the
/// graph of nodes it walks (see docs/DIALOGUE_SYSTEM_BIBLE.md, "Data structure").
///
/// The scene is immutable content; the mutable "where are we now" lives in the
/// <see cref="DialogueRunner"/>. Availability is a single condition over world
/// state, which subsumes "required flags" and "optional flags".
/// </summary>
public sealed class DialogueScene
{
    public required string Id { get; init; }
    public string Location { get; init; } = "";
    public IReadOnlyList<string> Participants { get; init; } = Array.Empty<string>();

    /// <summary>
    /// Optional gate deciding whether the scene may currently play (its trigger /
    /// required knowledge / relationship thresholds). Null means always available.
    /// </summary>
    public Func<ConsequenceContext, bool>? Available { get; init; }

    /// <summary>Node the conversation starts on.</summary>
    public required string StartNodeId { get; init; }

    /// <summary>All nodes, keyed by <see cref="DialogueNode.Id"/>.</summary>
    public required IReadOnlyDictionary<string, DialogueNode> Nodes { get; init; }

    /// <summary>Look up a node by id (throws if the graph references a missing node).</summary>
    public DialogueNode Node(string id) =>
        Nodes.TryGetValue(id, out DialogueNode? node)
            ? node
            : throw new KeyNotFoundException($"Dialogue scene '{Id}' has no node '{id}'.");
}
