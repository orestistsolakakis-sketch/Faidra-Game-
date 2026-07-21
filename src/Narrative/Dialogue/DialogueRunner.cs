using System;
using System.Collections.Generic;
using System.Linq;
using Lumenfall.Narrative.Events;

namespace Lumenfall.Narrative.Dialogue;

/// <summary>
/// Walks a <see cref="DialogueScene"/> against the live world. It resolves each
/// line's conditional text, filters its choices by their availability conditions,
/// applies the chosen choice's effect, and advances — raising events the
/// presentation layer listens to. It holds no Godot dependency; a Godot presenter
/// drives pacing and (for timed nodes) the countdown.
///
/// Contract:
/// * Call <see cref="Start"/> to begin a scene → raises <see cref="LineEntered"/>,
///   then either <see cref="ChoicesOffered"/> (if the node has available choices)
///   or nothing (auto-advance node — the presenter calls <see cref="Advance"/>).
/// * On a choice node call <see cref="Choose"/> with a *visible* index.
/// * On an auto-advance node call <see cref="Advance"/>.
/// * <see cref="SceneEnded"/> fires when the graph runs out.
/// </summary>
public sealed class DialogueRunner
{
    private readonly ConsequenceContext _context;

    private DialogueScene? _scene;
    private DialogueNode? _node;
    private IReadOnlyList<DialogueChoice> _visibleChoices = Array.Empty<DialogueChoice>();

    public DialogueRunner(ConsequenceContext context) => _context = context;

    /// <summary>True while a scene is in progress.</summary>
    public bool IsRunning => _scene is not null;

    /// <summary>The node currently displayed, or null if not running.</summary>
    public DialogueNode? CurrentNode => _node;

    /// <summary>Raised when a new line becomes current. Args: speaker id, resolved text.</summary>
    public event Action<string, string>? LineEntered;

    /// <summary>Raised when the current line offers choices (already filtered by availability).</summary>
    public event Action<IReadOnlyList<DialogueChoice>>? ChoicesOffered;

    /// <summary>Raised once when the scene finishes.</summary>
    public event Action? SceneEnded;

    /// <summary>Whether the scene's own availability gate currently passes.</summary>
    public bool CanPlay(DialogueScene scene) => scene.Available?.Invoke(_context) ?? true;

    /// <summary>Begin a scene at its start node. No-op (returns false) if it isn't available.</summary>
    public bool Start(DialogueScene scene)
    {
        if (!CanPlay(scene))
            return false;
        _scene = scene;
        EnterNode(scene.StartNodeId);
        return true;
    }

    /// <summary>Advance an auto-advance (choice-less) node to its <see cref="DialogueNode.Next"/>.</summary>
    public void Advance()
    {
        if (_node is null || _visibleChoices.Count > 0)
            return; // choice nodes must be resolved with Choose
        GoTo(_node.Next);
    }

    /// <summary>
    /// Resolve the current choice node by picking the visible choice at
    /// <paramref name="visibleIndex"/>. Applies its effect and moves on.
    /// </summary>
    public void Choose(int visibleIndex)
    {
        if (_node is null || visibleIndex < 0 || visibleIndex >= _visibleChoices.Count)
            return;
        DialogueChoice choice = _visibleChoices[visibleIndex];
        choice.Effect?.Invoke(_context);
        GoTo(choice.Next);
    }

    /// <summary>The index the presenter should auto-select if a timed node times out.</summary>
    public int DefaultChoiceIndex =>
        _node is null ? 0 : Math.Clamp(_node.DefaultChoiceIndex, 0, Math.Max(0, _visibleChoices.Count - 1));

    private void GoTo(string? nextId)
    {
        if (nextId is null)
        {
            End();
            return;
        }
        EnterNode(nextId);
    }

    private void EnterNode(string id)
    {
        _node = _scene!.Node(id);
        _node.OnEnter?.Invoke(_context);

        LineEntered?.Invoke(_node.Speaker, ResolveText(_node));

        _visibleChoices = _node.Choices.Where(c => c.Available?.Invoke(_context) ?? true).ToList();
        if (_visibleChoices.Count > 0)
            ChoicesOffered?.Invoke(_visibleChoices);
    }

    private string ResolveText(DialogueNode node)
    {
        foreach (DialogueTextVariant variant in node.TextVariants)
            if (variant.When(_context))
                return variant.Text;
        return node.Text;
    }

    private void End()
    {
        _scene = null;
        _node = null;
        _visibleChoices = Array.Empty<DialogueChoice>();
        SceneEnded?.Invoke();
    }
}
