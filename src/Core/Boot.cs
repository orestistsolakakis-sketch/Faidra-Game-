using Godot;

namespace Lumenfall.Core;

/// <summary>
/// Boot is the very first scene's script (see scenes/Boot/Main.tscn). Its only
/// job is to be a clean, single entry point: once the autoload services exist,
/// it hands off to the main menu.
///
/// WHY IT EXISTS:
/// Godot needs one "main scene". Rather than making that the menu directly, we
/// keep a tiny boot scene so there is one obvious place for future startup work
/// (loading settings/save-game, warming asset caches, showing a studio splash)
/// before the player sees anything.
/// </summary>
public partial class Boot : Node
{
    public override void _Ready()
    {
        // Future: load user settings, apply accessibility options, show splash.
        // For now, go straight to the main menu.
        SceneLoader.Instance.TransitionTo("res://scenes/UI/MainMenu.tscn", GameState.MainMenu);
    }
}
