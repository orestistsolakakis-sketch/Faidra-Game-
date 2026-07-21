using Godot;

namespace Lumenfall.Core;

/// <summary>
/// SceneLoader performs smooth, faded transitions between scenes (menu ->
/// gameplay, area -> area). It is a global singleton (Godot autoload).
///
/// WHY IT EXISTS:
/// A raw <c>GetTree().ChangeSceneToFile()</c> is a hard cut and gives callers
/// no hook for "fade out, unload, load, fade in". Every future area transition,
/// death-and-respawn, and menu flow wants that polish. Centralising it means
/// gameplay code just says <c>SceneLoader.Instance.TransitionTo(path)</c> and
/// never touches the SceneTree or the fade overlay directly.
///
/// It owns a full-screen fade overlay (a CanvasLayer above everything) and
/// drives the GameManager into/out of the <see cref="GameState.Loading"/> state
/// around each transition.
/// </summary>
public partial class SceneLoader : Node
{
    public static SceneLoader Instance { get; private set; } = null!;

    /// <summary>Emitted once the new scene is live and the fade-in has finished.</summary>
    [Signal]
    public delegate void TransitionFinishedEventHandler();

    private const float FadeSeconds = 0.4f;

    private CanvasLayer _overlayLayer = null!;
    private ColorRect _fade = null!;
    private bool _busy;

    public override void _EnterTree()
    {
        if (Instance is not null && Instance != this)
        {
            QueueFree();
            return;
        }
        Instance = this;
    }

    public override void _Ready()
    {
        // The fade must keep animating even when the tree is paused, and must
        // sit above every game/UI element.
        ProcessMode = ProcessModeEnum.Always;

        _overlayLayer = new CanvasLayer { Layer = 128 };
        AddChild(_overlayLayer);

        _fade = new ColorRect
        {
            Color = new Color(0, 0, 0, 0),
            // Transparent overlay must never eat input while idle.
            MouseFilter = Control.MouseFilterEnum.Ignore,
        };
        _fade.SetAnchorsPreset(Control.LayoutPreset.FullRect);
        _overlayLayer.AddChild(_fade);
    }

    /// <summary>
    /// Fade out, swap to the scene at <paramref name="scenePath"/>, then fade
    /// back in. Sets <see cref="GameState.Loading"/> during the swap and leaves
    /// the game in <paramref name="stateAfter"/> once done. Ignored if a
    /// transition is already running.
    /// </summary>
    public async void TransitionTo(string scenePath, GameState stateAfter = GameState.Playing)
    {
        if (_busy)
            return;
        _busy = true;

        GameManager.Instance.SetState(GameState.Loading);

        await FadeTo(1f);
        GetTree().ChangeSceneToFile(scenePath);
        // Let the new scene enter the tree before we reveal it.
        await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
        await FadeTo(0f);

        GameManager.Instance.SetState(stateAfter);
        _busy = false;
        EmitSignal(SignalName.TransitionFinished);
    }

    /// <summary>Tween the fade overlay's alpha and await its completion.</summary>
    private async System.Threading.Tasks.Task FadeTo(float alpha)
    {
        Tween tween = CreateTween();
        tween.TweenProperty(_fade, "color:a", alpha, FadeSeconds);
        await ToSignal(tween, Tween.SignalName.Finished);
    }
}
