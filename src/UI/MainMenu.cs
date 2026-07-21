using Godot;
using Lumenfall.Core;
using Lumenfall.Narrative;

namespace Lumenfall.UI;

/// <summary>
/// The title screen. Deliberately thin: it wires its buttons to the core
/// services and owns no game logic of its own. "Play" asks the SceneLoader to
/// transition into the world; "Quit" exits.
///
/// This is a placeholder for the eventual cinematic main menu (animated vista,
/// music, save-slot selection) but the wiring pattern stays the same.
/// </summary>
public partial class MainMenu : Control
{
    // Node paths are resolved in _Ready so the scene file stays the source of
    // truth for layout while the script stays the source of truth for behaviour.
    private Button _playButton = null!;
    private Button _quitButton = null!;

    public override void _Ready()
    {
        _playButton = GetNode<Button>("%PlayButton");
        _quitButton = GetNode<Button>("%QuitButton");

        _playButton.Pressed += OnPlayPressed;
        _quitButton.Pressed += OnQuitPressed;

        _playButton.GrabFocus();
    }

    private void OnPlayPressed()
    {
        // Boot the narrative simulation for a fresh run, then enter the world.
        // (A save-slot flow will later choose between NewGame and loading.)
        World.Instance.NewGame();
        SceneLoader.Instance.TransitionTo("res://scenes/World/PlayerSandbox.tscn", GameState.Playing);
    }

    private void OnQuitPressed()
    {
        GetTree().Quit();
    }
}
