using System.Collections.Generic;
using Godot;
using Lumenfall.Core;

namespace Lumenfall.Player;

/// <summary>
/// Drives the two-lead party: owns the third-person camera rig, decides which
/// character is active, switches between them, and handles mouse-look. This is
/// the concrete implementation of the "dual switchable control" canon decision.
///
/// The camera pivot is kept as a sibling (not a child of a character) so it can
/// smoothly follow whoever is active in world space. Mouse-look and switching are
/// gated by the same condition as movement — active play in Exploration mode — so
/// the camera locks and the cursor frees during dialogue and pauses.
/// </summary>
public partial class PartyController : Node3D
{
    [Export] public Godot.Collections.Array<NodePath> CharacterPaths { get; set; } = new();
    [Export] public NodePath CameraPivotPath { get; set; } = new();

    [Export] public float MouseSensitivity { get; set; } = 0.004f;
    [Export] public float FollowResponsiveness { get; set; } = 12f;
    [Export] public float EyeHeight { get; set; } = 1.4f;

    private readonly List<PlayerCharacter> _characters = new();
    private Node3D _pivot = null!;
    private SpringArm3D? _spring;
    private int _activeIndex;
    private float _yaw;
    private float _pitch = -0.3f;

    public override void _Ready()
    {
        PlayerInput.EnsureActions();

        _pivot = GetNode<Node3D>(CameraPivotPath);
        _spring = _pivot.GetNodeOrNull<SpringArm3D>("SpringArm3D");

        foreach (NodePath path in CharacterPaths)
            _characters.Add(GetNode<PlayerCharacter>(path));

        if (_characters.Count > 0)
            SetActive(0);
    }

    private PlayerCharacter? Active => _characters.Count > 0 ? _characters[_activeIndex] : null;

    private bool CanControl =>
        GameManager.Instance.State == GameState.Playing && GameModeManager.Instance.AcceptsMovement;

    public override void _UnhandledInput(InputEvent @event)
    {
        if (@event is InputEventMouseMotion motion && CanControl)
        {
            _yaw -= motion.Relative.X * MouseSensitivity;
            _pitch = Mathf.Clamp(_pitch - motion.Relative.Y * MouseSensitivity, -1.3f, 0.4f);
        }
    }

    public override void _Process(double delta)
    {
        // Free the cursor whenever the player isn't in direct control.
        Input.MouseMode = CanControl ? Input.MouseModeEnum.Captured : Input.MouseModeEnum.Visible;

        if (CanControl && Input.IsActionJustPressed(PlayerInput.SwitchCharacter) && _characters.Count > 1)
            SetActive((_activeIndex + 1) % _characters.Count);

        if (Active is null)
            return;

        // Smoothly follow the active character and apply look rotation.
        float t = 1f - Mathf.Exp(-FollowResponsiveness * (float)delta);
        Vector3 target = Active.GlobalPosition + Vector3.Up * EyeHeight;
        _pivot.GlobalPosition = _pivot.GlobalPosition.Lerp(target, t);

        Vector3 pivotRot = _pivot.Rotation;
        pivotRot.Y = _yaw;
        _pivot.Rotation = pivotRot;

        if (_spring is not null)
        {
            Vector3 springRot = _spring.Rotation;
            springRot.X = _pitch;
            _spring.Rotation = springRot;
        }
    }

    private void SetActive(int index)
    {
        _activeIndex = index;
        for (int i = 0; i < _characters.Count; i++)
        {
            _characters[i].IsActive = i == index;
            _characters[i].CameraPivot = _pivot;
        }
        GD.Print($"[Party] Now controlling: {_characters[index].CharacterId}");
    }
}
