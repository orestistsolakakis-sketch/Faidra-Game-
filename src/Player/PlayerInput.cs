using Godot;

namespace Lumenfall.Player;

/// <summary>
/// Registers the gameplay input actions in code rather than hand-editing the
/// fragile <c>[input]</c> block in project.godot. Called once at startup by the
/// party controller; idempotent, so re-entering the scene is safe.
///
/// Physical keycodes are used so the bindings follow key *position* across
/// keyboard layouts (WASD stays where WASD is on AZERTY, etc.). A real rebinding
/// UI will later edit these same actions.
/// </summary>
public static class PlayerInput
{
    public const string MoveForward = "move_forward";
    public const string MoveBack = "move_back";
    public const string MoveLeft = "move_left";
    public const string MoveRight = "move_right";
    public const string Run = "run";
    public const string Jump = "jump";
    public const string Interact = "interact";
    public const string SwitchCharacter = "switch_character";

    private static bool _registered;

    public static void EnsureActions()
    {
        if (_registered)
            return;
        _registered = true;

        Bind(MoveForward, Key.W, Key.Up);
        Bind(MoveBack, Key.S, Key.Down);
        Bind(MoveLeft, Key.A, Key.Left);
        Bind(MoveRight, Key.D, Key.Right);
        Bind(Run, Key.Shift);
        Bind(Jump, Key.Space);
        Bind(Interact, Key.E);
        Bind(SwitchCharacter, Key.Q);
    }

    private static void Bind(string action, params Key[] keys)
    {
        if (!InputMap.HasAction(action))
            InputMap.AddAction(action);

        foreach (Key key in keys)
            InputMap.ActionAddEvent(action, new InputEventKey { PhysicalKeycode = key });
    }
}
