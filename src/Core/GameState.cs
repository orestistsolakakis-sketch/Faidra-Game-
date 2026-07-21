namespace Lumenfall.Core;

/// <summary>
/// The high-level states the whole game can be in. This is deliberately
/// coarse — it is NOT the player's movement state or a quest step. It is
/// the top of the hierarchy that decides which subsystems are active
/// (e.g. is the world simulating? is input going to menus or gameplay?).
///
/// Keeping this small and explicit is what lets every other system react
/// to state changes instead of knowing about each other.
/// </summary>
public enum GameState
{
    /// <summary>First frame; services initialising before anything is shown.</summary>
    Boot,

    /// <summary>Title / main menu is up; the world is not simulating.</summary>
    MainMenu,

    /// <summary>A scene transition is in progress (fade + async load).</summary>
    Loading,

    /// <summary>Normal gameplay; the world simulates and accepts input.</summary>
    Playing,

    /// <summary>Gameplay is frozen behind a pause menu.</summary>
    Paused,
}
