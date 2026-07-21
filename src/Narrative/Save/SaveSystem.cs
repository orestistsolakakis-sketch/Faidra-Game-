using System;
using System.Text.Json;
using System.Text.Json.Serialization;
using Godot;
using FileAccess = Godot.FileAccess;

namespace Lumenfall.Narrative.Save;

/// <summary>
/// Reads and writes <see cref="SaveData"/> to disk as JSON under Godot's
/// <c>user://</c> directory. Stateless: it captures from / applies to the live
/// <see cref="World"/>, which owns every system. Uses Godot's FileAccess so paths
/// resolve correctly across platforms and exported builds.
///
/// Enums serialize as names (readable saves, robust to reordering) via the string
/// enum converter; every save DTO is a plain record, so System.Text.Json handles
/// them by reflection with no custom converters.
/// </summary>
public static class SaveSystem
{
    private const string SaveDir = "user://saves";

    private static readonly JsonSerializerOptions Options = new()
    {
        WriteIndented = true,
        Converters = { new JsonStringEnumConverter() },
    };

    public static string SlotPath(string slot) => $"{SaveDir}/{slot}.json";

    public static bool HasSave(string slot = "quicksave") => FileAccess.FileExists(SlotPath(slot));

    /// <summary>Capture the world and write it to <paramref name="slot"/>.</summary>
    public static void Save(World world, string slot = "quicksave")
    {
        EnsureSaveDir();
        string json = JsonSerializer.Serialize(world.CaptureSave(), Options);

        using FileAccess? file = FileAccess.Open(SlotPath(slot), FileAccess.ModeFlags.Write);
        if (file is null)
            throw new InvalidOperationException(
                $"Could not open save slot '{slot}': {FileAccess.GetOpenError()}");
        file.StoreString(json);
        GD.Print($"[SaveSystem] Saved slot '{slot}'.");
    }

    /// <summary>
    /// Load <paramref name="slot"/> into the world. Returns false if the slot is
    /// missing or unreadable (the world is left untouched in that case).
    /// </summary>
    public static bool Load(World world, string slot = "quicksave")
    {
        if (!HasSave(slot))
            return false;

        using FileAccess? file = FileAccess.Open(SlotPath(slot), FileAccess.ModeFlags.Read);
        if (file is null)
            return false;

        SaveData? data;
        try
        {
            data = JsonSerializer.Deserialize<SaveData>(file.GetAsText(), Options);
        }
        catch (JsonException e)
        {
            GD.PrintErr($"[SaveSystem] Corrupt save '{slot}': {e.Message}");
            return false;
        }

        if (data is null)
            return false;

        world.LoadGame(data);
        GD.Print($"[SaveSystem] Loaded slot '{slot}'.");
        return true;
    }

    private static void EnsureSaveDir()
    {
        if (!DirAccess.DirExistsAbsolute(SaveDir))
            DirAccess.MakeDirRecursiveAbsolute(SaveDir);
    }
}
