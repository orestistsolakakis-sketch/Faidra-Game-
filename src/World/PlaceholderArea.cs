using Godot;
using Lumenfall.Core;

namespace Lumenfall.World;

/// <summary>
/// A stand-in "gameplay" scene so the core loop (Menu -> Play -> Pause -> Menu)
/// is fully exercisable before any real area exists. It proves the state
/// machine and scene transitions work end to end.
///
/// It will be replaced by the first real area (the forest) once we build the
/// player controller and level systems.
/// </summary>
public partial class PlaceholderArea : Node3D
{
    private Label _hint = null!;

    public override void _Ready()
    {
        // Keep processing input while the tree is paused so [Esc] can un-pause.
        // Real gameplay children will default to Pausable; only this controller
        // needs to listen through a pause.
        ProcessMode = ProcessModeEnum.Always;

        _hint = GetNode<Label>("%Hint");
        UpdateHint(GameManager.Instance.State);

        // React to state changes rather than polling — the pattern every future
        // system will follow.
        GameManager.Instance.StateChanged += OnStateChanged;
    }

    public override void _ExitTree()
    {
        // Autoloads outlive scenes, so always unsubscribe to avoid a dangling
        // handler firing on a freed node.
        if (GameManager.Instance is not null)
            GameManager.Instance.StateChanged -= OnStateChanged;
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        // Esc pauses/unpauses; Backspace returns to the menu. Uses raw keys for
        // now — we'll move to named InputMap actions when we build input config.
        if (@event is InputEventKey { Pressed: true } key)
        {
            switch (key.Keycode)
            {
                case Key.Escape:
                    GameManager.Instance.TogglePause();
                    break;
                case Key.Backspace:
                    SceneLoader.Instance.TransitionTo("res://scenes/UI/MainMenu.tscn", GameState.MainMenu);
                    break;
            }
        }
    }

    private void OnStateChanged(GameState previous, GameState current) => UpdateHint(current);

    private void UpdateHint(GameState state)
    {
        _hint.Text = state == GameState.Paused
            ? "PAUSED\n\n[Esc] resume    [Backspace] main menu"
            : "Placeholder Area\n\n[Esc] pause    [Backspace] main menu";
    }
}
