using Godot;
using Lumenfall.Core;
using Lumenfall.Narrative;
using Lumenfall.Narrative.Events;
using Lumenfall.Narrative.Events.Content;
using Lumenfall.Narrative.Relationships;

namespace Lumenfall.World;

/// <summary>
/// A stand-in "gameplay" scene that doubles as a live harness for the narrative
/// simulation. It exercises the core loop (Menu → Play → Pause → Menu) AND lets
/// you watch the living world react: advance World Time, trigger the Cinder
/// Hollow hospital crisis, and resolve or ignore it — observing the consequence
/// chain and delayed events fire.
///
/// This will be replaced by the first real area (the forest/Cinder Hollow) once
/// the Player Controller and interaction systems exist. Until then it is our
/// window into the systems we've built.
/// </summary>
public partial class PlaceholderArea : Node3D
{
    private Label _hint = null!;
    private Label _readout = null!;

    public override void _Ready()
    {
        // Keep processing input while the tree is paused so [Esc] can un-pause.
        ProcessMode = ProcessModeEnum.Always;

        _hint = GetNode<Label>("%Hint");
        _readout = GetNode<Label>("%Readout");

        GameManager.Instance.StateChanged += OnStateChanged;

        // The World autoload outlives this scene, so subscribe with named handlers
        // and detach them in _ExitTree — otherwise a signal firing after this node
        // is freed would call into a disposed object.
        World world = World.Instance;
        world.TimeAdvanced += OnTimeAdvanced;
        world.FlagChanged += OnWorldFactChanged;
        world.ValueChanged += OnWorldFactChanged;
        world.EventActivated += OnEventActivated;
        world.EventExpired += OnEventExpired;
        world.EventResolved += OnEventResolved;
        world.RelationshipChanged += OnRelationshipChanged;

        UpdateHint(GameManager.Instance.State);
        RefreshReadout();
    }

    public override void _ExitTree()
    {
        if (GameManager.Instance is not null)
            GameManager.Instance.StateChanged -= OnStateChanged;

        if (World.Instance is not null)
        {
            World world = World.Instance;
            world.TimeAdvanced -= OnTimeAdvanced;
            world.FlagChanged -= OnWorldFactChanged;
            world.ValueChanged -= OnWorldFactChanged;
            world.EventActivated -= OnEventActivated;
            world.EventExpired -= OnEventExpired;
            world.EventResolved -= OnEventResolved;
            world.RelationshipChanged -= OnRelationshipChanged;
        }
    }

    private void OnTimeAdvanced(long minutes) => RefreshReadout();
    private void OnWorldFactChanged(string key) => RefreshReadout();
    private void OnEventActivated(string id) => GD.Print($"[Event] ACTIVATED: {id}");
    private void OnEventExpired(string id) => GD.Print($"[Event] EXPIRED (default outcome): {id}");
    private void OnEventResolved(string id, string outcomeId) => GD.Print($"[Event] RESOLVED: {id} → {outcomeId}");
    private void OnRelationshipChanged(string a, string b, string axis) => RefreshReadout();

    public override void _UnhandledInput(InputEvent @event)
    {
        if (@event is not InputEventKey { Pressed: true } key)
            return;

        switch (key.Keycode)
        {
            // --- Core loop controls ---
            case Key.Escape:
                GameManager.Instance.TogglePause();
                break;
            case Key.Backspace:
                SceneLoader.Instance.TransitionTo("res://scenes/UI/MainMenu.tscn", GameState.MainMenu);
                break;

            // --- Simulation demo controls (debug) ---
            case Key.T: // advance one day
                World.Instance.Clock.AdvanceDays(1);
                break;
            case Key.G: // the generator fails → triggers the hospital crisis
                World.Instance.State.SetFlag(WorldFacts.Flags.CinderGeneratorFailed, true);
                break;
            case Key.Key1: // resolve the crisis: repair the generator (the chain)
                World.Instance.Events.Resolve(CinderHollowEvents.HospitalCrisisId, "repair_generator");
                break;
            case Key.Key2: // resolve the crisis: ignore it (sever the chain)
                World.Instance.Events.Resolve(CinderHollowEvents.HospitalCrisisId, "ignore");
                break;
            case Key.L: // the party leaves Cinder Hollow (arms the delayed food shortage)
                World.Instance.State.SetValue(WorldFacts.Values.LeftCinderDay, World.Instance.Clock.Day);
                World.Instance.State.SetFlag(WorldFacts.Flags.LeftCinderHollow, true);
                break;
            case Key.Key3: // a warm moment: Arlen trusts Lysandra a little more
                World.Instance.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Trust, 8);
                World.Instance.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Attraction, 5);
                break;
            case Key.Key4: // a hurt: resentment grows
                World.Instance.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Resentment, 10);
                break;
        }
    }

    private void OnStateChanged(GameState previous, GameState current) => UpdateHint(current);

    private void UpdateHint(GameState state)
    {
        _hint.Text = state == GameState.Paused
            ? "PAUSED\n[Esc] resume   [Backspace] main menu"
            : "Placeholder Area\n[Esc] pause   [Backspace] menu\n\n" +
              "SIM DEMO:  [T] +1 day   [G] generator fails   [1] repair   [2] ignore\n" +
              "           [L] leave district   [3] warm moment   [4] a hurt";
    }

    private void RefreshReadout()
    {
        World w = World.Instance;
        string active = "";
        foreach (WorldEvent evt in w.Events.ActiveEvents)
            active += $"\n  • {evt.Id} (deadline-driven)";
        if (active == "")
            active = "\n  (none)";

        Relationship al = w.Relationships.Between(Characters.Arlen, Characters.Lysandra);

        _readout.Text =
            $"World Time: {w.Clock.ToDisplayString()}\n" +
            $"Engine stability: {w.State.GetValue(WorldFacts.Values.HeartEngineStability)}\n" +
            $"Generator failed: {w.State.GetFlag(WorldFacts.Flags.CinderGeneratorFailed)}\n" +
            $"Power restored: {w.State.GetFlag(WorldFacts.Flags.CinderPowerRestored)}\n" +
            $"Hospital open: {w.State.GetFlag(WorldFacts.Flags.CinderHospitalOpen)}\n" +
            $"Doctor survived: {w.State.GetFlag(WorldFacts.Flags.CinderDoctorSurvived)}\n" +
            $"Arlen learned healing lore: {w.State.GetFlag(WorldFacts.Flags.ArlenLearnedHealingLore)}\n" +
            $"Food shortage: {w.State.GetFlag(WorldFacts.Flags.CinderFoodShortage)}\n\n" +
            $"Arlen ↔ Lysandra —  " +
            $"Trust {al.Get(RelationshipAxis.Trust)}  " +
            $"Underst {al.Get(RelationshipAxis.Understanding)}  " +
            $"Attract {al.Get(RelationshipAxis.Attraction)}  " +
            $"Resent {al.Get(RelationshipAxis.Resentment)}  " +
            $"Depend {al.Get(RelationshipAxis.Dependence)}\n" +
            $"Active events:{active}";
    }
}
