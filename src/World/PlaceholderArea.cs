using System.Collections.Generic;
using Godot;
using Lumenfall.Core;
using Lumenfall.Narrative;
using Lumenfall.Narrative.Dialogue;
using Lumenfall.Narrative.Dialogue.Content;
using Lumenfall.Narrative.Events;
using Lumenfall.Narrative.Events.Content;
using Lumenfall.Narrative.Relationships;

namespace Lumenfall.World;

/// <summary>
/// A stand-in "gameplay" scene that doubles as a live harness for the narrative
/// simulation. It exercises the core loop (Menu → Play → Pause → Menu) AND lets
/// you watch the systems react: advance World Time, trigger the Cinder Hollow
/// hospital-crisis chain, nudge the relationship, and play a real dialogue scene
/// (with a timed opening choice) that moves relationships, personality and memory.
///
/// This will be replaced by the first real area once the Player Controller and
/// interaction systems exist. Until then it is our window into what we've built.
/// </summary>
public partial class PlaceholderArea : Node3D
{
    private Label _hint = null!;
    private Label _readout = null!;
    private Label _dialogue = null!;

    private bool _inDialogue;
    private IReadOnlyList<DialogueChoice> _choices = new List<DialogueChoice>();
    private string _speaker = "";
    private string _line = "";
    private double _timeRemaining;

    public override void _Ready()
    {
        // Keep processing input while the tree is paused so [Esc] can un-pause.
        ProcessMode = ProcessModeEnum.Always;

        _hint = GetNode<Label>("%Hint");
        _readout = GetNode<Label>("%Readout");
        _dialogue = GetNode<Label>("%Dialogue");

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
        world.PersonalityChanged += OnPersonalityChanged;

        world.DialogueRunner.LineEntered += OnDialogueLine;
        world.DialogueRunner.ChoicesOffered += OnDialogueChoices;
        world.DialogueRunner.SceneEnded += OnDialogueEnded;

        UpdateHint(GameManager.Instance.State);
        RefreshReadout();
        RenderDialogue();
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
            world.PersonalityChanged -= OnPersonalityChanged;

            world.DialogueRunner.LineEntered -= OnDialogueLine;
            world.DialogueRunner.ChoicesOffered -= OnDialogueChoices;
            world.DialogueRunner.SceneEnded -= OnDialogueEnded;
        }
    }

    private void OnTimeAdvanced(long minutes) => RefreshReadout();
    private void OnWorldFactChanged(string key) => RefreshReadout();
    private void OnEventActivated(string id) => GD.Print($"[Event] ACTIVATED: {id}");
    private void OnEventExpired(string id) => GD.Print($"[Event] EXPIRED (default outcome): {id}");
    private void OnEventResolved(string id, string outcomeId) => GD.Print($"[Event] RESOLVED: {id} → {outcomeId}");
    private void OnRelationshipChanged(string a, string b, string axis) => RefreshReadout();
    private void OnPersonalityChanged(string character, string trait) => RefreshReadout();

    public override void _Process(double delta)
    {
        // Drive the countdown on a timed choice; auto-pick the default on timeout.
        if (!_inDialogue || _choices.Count == 0 || _timeRemaining <= 0)
            return;
        _timeRemaining -= delta;
        if (_timeRemaining <= 0)
            World.Instance.DialogueRunner.Choose(World.Instance.DialogueRunner.DefaultChoiceIndex);
        else
            RenderDialogue();
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        if (@event is not InputEventKey { Pressed: true } key)
            return;

        // Global controls always available.
        switch (key.Keycode)
        {
            case Key.Escape:
                GameManager.Instance.TogglePause();
                return;
            case Key.Backspace:
                SceneLoader.Instance.TransitionTo("res://scenes/UI/MainMenu.tscn", GameState.MainMenu);
                return;
        }

        if (_inDialogue)
        {
            HandleDialogueInput(key.Keycode);
            return;
        }

        HandleSimInput(key.Keycode);
    }

    private void HandleSimInput(Key keycode)
    {
        World w = World.Instance;
        switch (keycode)
        {
            case Key.T: // advance one day
                w.Clock.AdvanceDays(1);
                break;
            case Key.G: // the generator fails → triggers the hospital crisis
                w.State.SetFlag(WorldFacts.Flags.CinderGeneratorFailed, true);
                break;
            case Key.Key1: // resolve the crisis: repair the generator (the chain)
                w.Events.Resolve(CinderHollowEvents.HospitalCrisisId, "repair_generator");
                break;
            case Key.Key2: // resolve the crisis: ignore it (sever the chain)
                w.Events.Resolve(CinderHollowEvents.HospitalCrisisId, "ignore");
                break;
            case Key.L: // the party leaves Cinder Hollow (arms the delayed food shortage)
                w.State.SetValue(WorldFacts.Values.LeftCinderDay, w.Clock.Day);
                w.State.SetFlag(WorldFacts.Flags.LeftCinderHollow, true);
                break;
            case Key.Key3: // a warm moment
                w.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Trust, 8);
                w.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Attraction, 5);
                break;
            case Key.Key4: // a hurt
                w.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Resentment, 10);
                break;
            case Key.K: // discover the affair (unlocks the confront option in dialogue)
                w.State.SetFlag(WorldFacts.Flags.HasDiscoveredEwaldAffair, true);
                break;
            case Key.D: // start the argument dialogue scene
                StartArgumentScene();
                break;
            case Key.F5: // quicksave
                Lumenfall.Narrative.Save.SaveSystem.Save(w);
                break;
            case Key.F9: // quickload
                if (Lumenfall.Narrative.Save.SaveSystem.Load(w))
                    RefreshReadout(); // restores fire no signals, so refresh manually
                break;
        }
    }

    private void StartArgumentScene()
    {
        World w = World.Instance;
        // Set the trigger fact, then play the scene if its availability gate passes.
        w.State.SetFlag(WorldFacts.Flags.ArlenHidInfoFromLysandra, true);
        if (w.Dialogue.TryGet(ArlenLysandraScenes.Argument01Id, out DialogueScene scene) &&
            w.DialogueRunner.Start(scene))
        {
            _inDialogue = true;
        }
    }

    private void HandleDialogueInput(Key keycode)
    {
        DialogueRunner runner = World.Instance.DialogueRunner;

        if (_choices.Count == 0)
        {
            // Auto-advance line: any of Space/Enter continues.
            if (keycode is Key.Space or Key.Enter or Key.KpEnter)
                runner.Advance();
            return;
        }

        int index = keycode switch
        {
            Key.Key1 => 0,
            Key.Key2 => 1,
            Key.Key3 => 2,
            Key.Key4 => 3,
            Key.Key5 => 4,
            _ => -1,
        };
        if (index >= 0 && index < _choices.Count)
            runner.Choose(index);
    }

    // --- Dialogue runner callbacks ---

    private void OnDialogueLine(string speaker, string text)
    {
        _speaker = speaker;
        _line = text;
        _choices = new List<DialogueChoice>();
        _timeRemaining = 0;
        RenderDialogue();
    }

    private void OnDialogueChoices(IReadOnlyList<DialogueChoice> choices)
    {
        _choices = choices;
        _timeRemaining = World.Instance.DialogueRunner.CurrentNode?.TimeLimitSeconds ?? 0;
        RenderDialogue();
    }

    private void OnDialogueEnded()
    {
        _inDialogue = false;
        _choices = new List<DialogueChoice>();
        _line = "";
        _speaker = "";
        RenderDialogue();
        RefreshReadout();
    }

    private void RenderDialogue()
    {
        if (!_inDialogue)
        {
            _dialogue.Text = "";
            return;
        }

        string text = $"{DisplayName(_speaker)}:  {_line}\n";
        if (_choices.Count > 0)
        {
            for (int i = 0; i < _choices.Count; i++)
                text += $"\n  [{i + 1}] ({_choices[i].Tone})  {_choices[i].Label}";
            if (_timeRemaining > 0)
                text += $"\n\n  ⏳ {_timeRemaining:0.0}s";
        }
        else
        {
            text += "\n  [Space] continue";
        }
        _dialogue.Text = text;
    }

    private static string DisplayName(string characterId) => characterId switch
    {
        Characters.Arlen => "Arlen",
        Characters.Lysandra => "Lysandra",
        "" => "",
        _ => characterId,
    };

    private void OnStateChanged(GameState previous, GameState current) => UpdateHint(current);

    private void UpdateHint(GameState state)
    {
        _hint.Text = state == GameState.Paused
            ? "PAUSED\n[Esc] resume   [Backspace] main menu"
            : "Placeholder Area\n[Esc] pause   [Backspace] menu\n\n" +
              "SIM:  [T] +1 day  [G] generator fails  [1] repair  [2] ignore  [L] leave\n" +
              "      [3] warm moment  [4] a hurt  [K] discover affair  [D] dialogue\n" +
              "      [F5] quicksave   [F9] quickload";
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
        string arlenTrait = w.Personality.GetDominant(Characters.Arlen) ?? "(unformed)";

        _readout.Text =
            $"World Time: {w.Clock.ToDisplayString()}\n" +
            $"Engine stability: {w.State.GetValue(WorldFacts.Values.HeartEngineStability)}\n" +
            $"Hospital open: {w.State.GetFlag(WorldFacts.Flags.CinderHospitalOpen)}   " +
            $"Doctor survived: {w.State.GetFlag(WorldFacts.Flags.CinderDoctorSurvived)}\n" +
            $"Arlen learned healing lore: {w.State.GetFlag(WorldFacts.Flags.ArlenLearnedHealingLore)}\n" +
            $"Lysandra guards secrets: {w.State.GetFlag(WorldFacts.Flags.LysandraGuardsSecrets)}\n\n" +
            $"Arlen ↔ Lysandra —  " +
            $"Trust {al.Get(RelationshipAxis.Trust)}  " +
            $"Underst {al.Get(RelationshipAxis.Understanding)}  " +
            $"Attract {al.Get(RelationshipAxis.Attraction)}  " +
            $"Resent {al.Get(RelationshipAxis.Resentment)}  " +
            $"Vuln {al.Get(RelationshipAxis.Vulnerability)}  " +
            $"Depend {al.Get(RelationshipAxis.Dependence)}\n" +
            $"Arlen's emerging self: {arlenTrait}\n" +
            $"Active events:{active}";
    }
}
