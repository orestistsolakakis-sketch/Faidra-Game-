namespace Lumenfall.Core;

/// <summary>
/// The interaction mode during gameplay (see docs/SYSTEMS_BIBLE.md, "three
/// gameplay modes"). This is a sub-state of <see cref="GameState.Playing"/>: it
/// decides whether the player is driving a character, watching a scene, or making
/// a choice — and therefore who receives input. It is distinct from the coarse
/// <see cref="GameState"/> (which decides whether the world simulates at all).
/// </summary>
public enum GameMode
{
    /// <summary>The player directly controls a character and moves through the world.</summary>
    Exploration,

    /// <summary>The player watches a scene; movement input is suspended.</summary>
    Cinematic,

    /// <summary>A watched scene the player can still act within (look, choose, interrupt).</summary>
    InteractiveCinematic,

    /// <summary>A focused choice is being made, often under a time limit.</summary>
    Decision,
}
