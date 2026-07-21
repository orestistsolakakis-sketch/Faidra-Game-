using System.Collections.Generic;

namespace Lumenfall.Narrative.Dialogue;

/// <summary>
/// A simple registry of authored <see cref="DialogueScene"/>s, keyed by id. Kept
/// separate from the <see cref="DialogueRunner"/> (which runs one scene at a time)
/// so content can be registered once at new-game and looked up by triggers, event
/// effects, or interaction points. Definitions are immutable; no runtime state
/// lives here.
/// </summary>
public sealed class DialogueLibrary
{
    private readonly Dictionary<string, DialogueScene> _scenes = new();

    public void Register(DialogueScene scene) => _scenes[scene.Id] = scene;

    public bool TryGet(string id, out DialogueScene scene)
    {
        bool found = _scenes.TryGetValue(id, out DialogueScene? s);
        scene = s!;
        return found;
    }

    /// <summary>Clear all registered scenes (for a new game before re-registering content).</summary>
    public void Clear() => _scenes.Clear();
}
