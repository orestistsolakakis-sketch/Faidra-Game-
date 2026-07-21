using Godot;
using Lumenfall.Narrative.Events;
using Lumenfall.Narrative.Events.Content;
using Lumenfall.Narrative.Relationships;

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

    /// <summary>Character relationships (Trust/Understanding/Attraction/Resentment/Dependence).</summary>
    public RelationshipModel Relationships { get; } = new();

    /// <summary>The living-world engine: events that activate, expire, and chain.</summary>
    public EventManager Events { get; }

    public World()
    {
        // Events read and mutate the same clock, state, and relationships.
        Events = new EventManager(Clock, State, Relationships);
    }

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

    /// <summary>An event became live. Arg: event id.</summary>
    [Signal]
    public delegate void EventActivatedEventHandler(string id);

    /// <summary>The player resolved an event. Args: event id, chosen outcome id.</summary>
    [Signal]
    public delegate void EventResolvedEventHandler(string id, string outcomeId);

    /// <summary>An event's deadline passed unresolved. Arg: event id.</summary>
    [Signal]
    public delegate void EventExpiredEventHandler(string id);

    /// <summary>A relationship axis changed. Args: character A, character B, axis name.</summary>
    [Signal]
    public delegate void RelationshipChangedEventHandler(string characterA, string characterB, string axis);

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

        // Re-broadcast the living-world engine's activity.
        Events.EventActivated += evt => EmitSignal(SignalName.EventActivated, evt.Id);
        Events.EventResolved += (evt, outcomeId) => EmitSignal(SignalName.EventResolved, evt.Id, outcomeId);
        Events.EventExpired += evt => EmitSignal(SignalName.EventExpired, evt.Id);

        // Re-broadcast relationship changes.
        Relationships.Changed += (a, b, axis) => EmitSignal(SignalName.RelationshipChanged, a, b, axis.ToString());

        // The world reacts to time and facts: any change re-evaluates events.
        // (EventManager guards against re-entrancy when effects change state.)
        Clock.Advanced += _ => Events.Evaluate();
        State.FlagChanged += _ => Events.Evaluate();
        State.ValueChanged += _ => Events.Evaluate();
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
        Events.Reset();
        Relationships.Reset();

        // Register authored event content. (Later this can be data-driven.)
        CinderHollowEvents.RegisterInto(Events);

        // Seed opening world conditions.
        State.SetValue(WorldFacts.Values.HeartEngineStability, 100);
        State.SetValue(WorldFacts.Values.ContinuanceInfluence, 0);
        State.SetFlag(WorldFacts.Flags.ElderAlive, true);
        State.SetFlag(WorldFacts.Flags.CinderHospitalOpen, true);

        // Arlen and Lysandra begin at Phase 1 — Distrust (Character Bible):
        // no romance yet, little trust or understanding, some early resentment.
        Relationships.Set(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Trust, 10);
        Relationships.Set(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Understanding, 5);
        Relationships.Set(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Attraction, 0);
        Relationships.Set(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Resentment, 25);
        Relationships.Set(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Dependence, 0);

        Events.Evaluate();
        GD.Print($"[World] New game. {Clock.ToDisplayString()}");
    }
}
