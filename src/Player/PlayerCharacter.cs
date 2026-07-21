using Godot;
using Lumenfall.Core;

namespace Lumenfall.Player;

/// <summary>
/// A playable lead (Arlen or Lysandra). Handles its own third-person movement in
/// the physics step, but ONLY when it is the active character AND the game is in
/// <see cref="GameMode.Exploration"/> — so control freezes automatically during
/// dialogue and cutscenes without this class knowing anything about them. That
/// gate is the payoff of the GameMode layer.
///
/// Movement is camera-relative: the party controller feeds this character the
/// camera pivot each frame so "forward" always means "away from the camera".
/// </summary>
public partial class PlayerCharacter : CharacterBody3D
{
    /// <summary>Which character this is (see <see cref="Lumenfall.Narrative.Relationships.Characters"/>).</summary>
    [Export] public string CharacterId { get; set; } = "";

    [Export] public float WalkSpeed { get; set; } = 4.5f;
    [Export] public float RunSpeed { get; set; } = 7.5f;
    [Export] public float JumpVelocity { get; set; } = 5.0f;

    /// <summary>Higher = snappier acceleration and turning.</summary>
    [Export] public float Responsiveness { get; set; } = 12f;

    /// <summary>True when this character currently receives input (set by the party controller).</summary>
    public bool IsActive { get; set; }

    /// <summary>The camera's yaw pivot; movement is relative to it. Set each frame by the controller.</summary>
    public Node3D? CameraPivot { get; set; }

    private readonly float _gravity =
        (float)ProjectSettings.GetSetting("physics/3d/default_gravity", 9.8f);

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;
        Vector3 velocity = Velocity;

        if (!IsOnFloor())
            velocity.Y -= _gravity * dt;

        bool controllable = IsActive && GameModeManager.Instance.AcceptsMovement;

        Vector3 direction = controllable ? ReadMoveDirection() : Vector3.Zero;
        float speed = controllable && Input.IsActionPressed(PlayerInput.Run) ? RunSpeed : WalkSpeed;

        // Smoothly approach the target horizontal velocity (frame-rate independent).
        float t = 1f - Mathf.Exp(-Responsiveness * dt);
        Vector3 horizontal = new(velocity.X, 0f, velocity.Z);
        horizontal = horizontal.Lerp(direction * speed, t);
        velocity.X = horizontal.X;
        velocity.Z = horizontal.Z;

        if (controllable && Input.IsActionJustPressed(PlayerInput.Jump) && IsOnFloor())
            velocity.Y = JumpVelocity;

        Velocity = velocity;
        MoveAndSlide();

        // Face the direction of travel.
        if (direction.LengthSquared() > 0.001f)
        {
            float targetYaw = Mathf.Atan2(-direction.X, -direction.Z);
            Vector3 rot = Rotation;
            rot.Y = Mathf.LerpAngle(rot.Y, targetYaw, t);
            Rotation = rot;
        }
    }

    /// <summary>Camera-relative move direction on the ground plane from the input actions.</summary>
    private Vector3 ReadMoveDirection()
    {
        Vector2 input = Input.GetVector(
            PlayerInput.MoveLeft, PlayerInput.MoveRight, PlayerInput.MoveForward, PlayerInput.MoveBack);
        if (input == Vector2.Zero || CameraPivot is null)
            return Vector3.Zero;

        // Rotate the raw input by the camera's yaw so forward tracks the camera.
        float yaw = CameraPivot.GlobalRotation.Y;
        Basis basis = new(Vector3.Up, yaw);
        return (basis * new Vector3(input.X, 0f, input.Y)).Normalized();
    }
}
