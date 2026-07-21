using Godot;

namespace Lumenfall.Core;

/// <summary>
/// GameManager is the spine of the game: a global singleton (Godot autoload)
/// that owns the single source of truth for the high-level <see cref="GameState"/>.
///
/// WHY IT EXISTS:
/// In a large game, dozens of systems care about "are we playing, paused, in a
/// menu, or loading?" (input, audio ducking, world simulation, save-lockout...).
/// If each of those queried or mutated each other we'd get a tangle. Instead
/// every system reacts to <see cref="StateChanged"/> and reads
/// <see cref="State"/>. One writer, many readers.
///
/// It also owns pausing, since pause is a whole-tree concern in Godot.
///
/// Access from anywhere via <c>GameManager.Instance</c>.
/// </summary>
public partial class GameManager : Node
{
    /// <summary>Global access point, set on <see cref="_EnterTree"/>.</summary>
    public static GameManager Instance { get; private set; } = null!;

    /// <summary>
    /// Emitted whenever the high-level state changes. Args are the previous
    /// and new state, so listeners can handle transitions (e.g. Playing->Paused).
    /// </summary>
    [Signal]
    public delegate void StateChangedEventHandler(GameState previous, GameState current);

    /// <summary>The current high-level game state. Change it via <see cref="SetState"/>.</summary>
    public GameState State { get; private set; } = GameState.Boot;

    public override void _EnterTree()
    {
        // Autoloads are unique; guard against duplicate instances just in case
        // (e.g. a scene accidentally instancing this script).
        if (Instance is not null && Instance != this)
        {
            QueueFree();
            return;
        }
        Instance = this;
    }

    /// <summary>
    /// Transition to a new high-level state. No-ops if already in that state so
    /// listeners never receive spurious events.
    /// </summary>
    public void SetState(GameState next)
    {
        if (next == State)
            return;

        GameState previous = State;
        State = next;

        // Pause is a tree-wide flag in Godot. We centralise it here so no other
        // system has to remember to set it. Only Paused freezes the SceneTree.
        GetTree().Paused = next == GameState.Paused;

        GD.Print($"[GameManager] {previous} -> {next}");
        EmitSignal(SignalName.StateChanged, (int)previous, (int)next);
    }

    /// <summary>Convenience: toggle between Playing and Paused. Ignored elsewhere.</summary>
    public void TogglePause()
    {
        if (State == GameState.Playing)
            SetState(GameState.Paused);
        else if (State == GameState.Paused)
            SetState(GameState.Playing);
    }
}
