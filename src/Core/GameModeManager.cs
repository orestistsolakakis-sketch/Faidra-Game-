using Godot;

namespace Lumenfall.Core;

/// <summary>
/// Owns the current <see cref="GameMode"/> — the interaction mode within gameplay.
/// A global singleton (autoload) so any system can ask "should I accept movement
/// input right now?" (only in <see cref="GameMode.Exploration"/>) or react to a
/// scene starting/ending. Same "one writer, many readers" pattern as
/// <see cref="GameManager"/>.
///
/// It resets to <see cref="GameMode.Exploration"/> whenever gameplay (re)starts,
/// so a mode can never leak across a scene change or a return to the menu.
/// </summary>
public partial class GameModeManager : Node
{
    public static GameModeManager Instance { get; private set; } = null!;

    /// <summary>Emitted when the interaction mode changes. Args: previous, current.</summary>
    [Signal]
    public delegate void ModeChangedEventHandler(GameMode previous, GameMode current);

    public GameMode Mode { get; private set; } = GameMode.Exploration;

    /// <summary>True only when the player should be driving a character.</summary>
    public bool AcceptsMovement => Mode == GameMode.Exploration;

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
        // When gameplay begins (or the world reloads), always start in Exploration.
        GameManager.Instance.StateChanged += OnGameStateChanged;
    }

    public override void _ExitTree()
    {
        if (GameManager.Instance is not null)
            GameManager.Instance.StateChanged -= OnGameStateChanged;
    }

    /// <summary>Change the interaction mode. No-ops if already in it.</summary>
    public void SetMode(GameMode next)
    {
        if (next == Mode)
            return;
        GameMode previous = Mode;
        Mode = next;
        GD.Print($"[GameMode] {previous} -> {next}");
        EmitSignal(SignalName.ModeChanged, (int)previous, (int)next);
    }

    /// <summary>Enter a conversation: interactive lets the player still act; otherwise pure cinematic.</summary>
    public void EnterDialogue(bool interactive) =>
        SetMode(interactive ? GameMode.InteractiveCinematic : GameMode.Cinematic);

    /// <summary>Return to normal control after a scene/choice.</summary>
    public void ExitToExploration() => SetMode(GameMode.Exploration);

    private void OnGameStateChanged(GameState previous, GameState current)
    {
        // Entering active play (from menu/loading) resets the interaction mode.
        if (current == GameState.Playing && previous != GameState.Paused)
            SetMode(GameMode.Exploration);
    }
}
