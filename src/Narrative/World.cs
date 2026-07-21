using Godot;

namespace Lumenfall.Narrative;

/// <summary>
/// World is the Godot autoload facade over the narrative simulation. It OWNS the
/// pure-C# data systems (<see cref="Clock"/> and <see cref="State"/>) and
/// re-broadcasts their changes as Godot signals so scenes, UI, and future
/// systems (Consequence/Event, Dialogue, Save) can react without depending on
/// each other — the same "one writer, many readers" pattern as GameManager.
///
/// WHY A THIN FACADE:
/// The data classes stay engine-free (testable, serializable); this node is the
/// only place that knows about both the simulation and Godot. Scenes talk to the
/// simulation through <c>World.Instance</c>; they never construct or own it.
///
/// Access from anywhere via <c>World.Instance</c>.
/// </summary>
public partial class World : Node
{
    public static World Instance { get; private set; } = null!;

    /// <summary>World Time. Advance it through gameplay actions (travel, repair, heal).</summary>
    public WorldClock Clock { get; } = new();

    /// <summary>The authoritative fact store (flags + values).</summary>
    public WorldState State { get; } = new();

    /// <summary>Mirror of <see cref="WorldClock.Advanced"/>. Arg: minutes added.</summary>
    [Signal]
    public delegate void TimeAdvancedEventHandler(long minutes);

    /// <summary>Mirror of <see cref="WorldClock.DayElapsed"/>. Arg: new day number.</summary>
    [Signal]
    public delegate void DayElapsedEventHandler(int day);

    /// <summary>Mirror of <see cref="WorldState.FlagChanged"/>. Arg: fact key.</summary>
    [Signal]
    public delegate void FlagChangedEventHandler(string key);

    /// <summary>Mirror of <see cref="WorldState.ValueChanged"/>. Arg: fact key.</summary>
    [Signal]
    public delegate void ValueChangedEventHandler(string key);

    public override void _EnterTree()
    {
        if (Instance is not null && Instance != this)
        {
            QueueFree();
            return;
        }
        Instance = this;

        // Bridge the engine-free data events to Godot signals.
        Clock.Advanced += minutes => EmitSignal(SignalName.TimeAdvanced, minutes);
        Clock.DayElapsed += day => EmitSignal(SignalName.DayElapsed, day);
        State.FlagChanged += key => EmitSignal(SignalName.FlagChanged, key);
        State.ValueChanged += key => EmitSignal(SignalName.ValueChanged, key);
    }

    /// <summary>
    /// Reset the simulation to its game-start condition. Call when beginning a
    /// new game. (Loading a save uses the Restore paths instead — added with the
    /// Save system.)
    /// </summary>
    public void NewGame()
    {
        Clock.Restore(new WorldClockData(0));
        State.Reset();

        // Seed opening world conditions.
        State.SetValue(WorldFacts.Values.HeartEngineStability, 100);
        State.SetValue(WorldFacts.Values.ContinuanceInfluence, 0);
        State.SetFlag(WorldFacts.Flags.ElderAlive, true);

        GD.Print($"[World] New game. {Clock.ToDisplayString()}");
    }
}
