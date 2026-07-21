using Lumenfall.Narrative;

namespace Lumenfall.Narrative.Events.Content;

/// <summary>
/// Authored event content for Cinder Hollow — the first proof that the event
/// engine can express the canonical designs from docs/EVENT_SYSTEM_BIBLE.md.
///
/// It implements two things from the bible:
/// 1. The hospital-crisis consequence CHAIN (repair → power → hospital open →
///    doctor survives → doctor teaches Arlen), including the "do nothing" default
///    outcome that closes the hospital when its deadline passes.
/// 2. A DELAYED, hidden event: a food shortage that only occurs if the player
///    leaves Cinder Hollow and stays away ~30 days without restoring food.
///
/// Content is C# authored against the engine API; it can later move to data files
/// without changing the engine. Register it at new-game via <see cref="RegisterInto"/>.
/// </summary>
public static class CinderHollowEvents
{
    public const string HospitalCrisisId = "CINDER_HOLLOW_HOSPITAL_CRISIS";
    public const string FoodShortageId = "CINDER_HOLLOW_FOOD_SHORTAGE";

    public static void RegisterInto(EventManager events)
    {
        events.Register(BuildHospitalCrisis());
        events.Register(BuildFoodShortage());
    }

    /// <summary>
    /// The generator has failed and the hospital runs on borrowed time. The player
    /// has 3 days to act; ignoring it closes the hospital and kills the chain that
    /// would otherwise teach Arlen about healing.
    /// </summary>
    private static WorldEvent BuildHospitalCrisis() => new()
    {
        Id = HospitalCrisisId,
        Location = "Cinder Hollow",
        Category = EventCategory.Local,
        Level = ConsequenceLevel.LongTerm,
        Priority = 80,

        // Activates once the generator has failed and power hasn't been restored.
        Condition = ctx =>
            ctx.State.GetFlag(WorldFacts.Flags.CinderGeneratorFailed) &&
            !ctx.State.GetFlag(WorldFacts.Flags.CinderPowerRestored),

        DeadlineMinutes = 3L * WorldClock.MinutesPerDay,

        Outcomes = new System.Collections.Generic.Dictionary<string, EventOutcome>
        {
            ["repair_generator"] = new EventOutcome
            {
                Label = "Repair the generator (2 days, costs materials).",
                Apply = ctx =>
                {
                    ctx.Clock.AdvanceDays(2);
                    RestorePowerAndSaveHospital(ctx);
                },
            },
            ["find_replacement_part"] = new EventOutcome
            {
                Label = "Search for a replacement part (1 week; may reveal an old workshop).",
                Apply = ctx =>
                {
                    ctx.Clock.AdvanceDays(7);
                    RestorePowerAndSaveHospital(ctx);
                },
            },
            ["ignore"] = new EventOutcome
            {
                Label = "Leave it — there are other priorities.",
                Apply = CloseHospital, // same consequence as letting it expire
            },
        },

        // "Do nothing": the deadline passes, the hospital closes on its own.
        OnExpire = CloseHospital,
    };

    /// <summary>Power restored → hospital stays open → doctor survives → Arlen learns healing lore.</summary>
    private static void RestorePowerAndSaveHospital(ConsequenceContext ctx)
    {
        ctx.State.SetFlag(WorldFacts.Flags.CinderPowerRestored, true);
        ctx.State.SetFlag(WorldFacts.Flags.CinderHospitalOpen, true);
        ctx.State.SetFlag(WorldFacts.Flags.CinderDoctorSurvived, true);
        // The chain payoff: a surviving doctor is the one who first helps Arlen
        // understand what she is. (A later Arlen-heals-someone event can gate on
        // this flag to unlock a healing insight.)
        ctx.State.SetFlag(WorldFacts.Flags.ArlenLearnedHealingLore, true);
    }

    /// <summary>The hospital closes; the doctor does not survive; the healing-lore chain is severed.</summary>
    private static void CloseHospital(ConsequenceContext ctx)
    {
        ctx.State.SetFlag(WorldFacts.Flags.CinderHospitalOpen, false);
        ctx.State.SetFlag(WorldFacts.Flags.CinderDoctorSurvived, false);
        // ArlenLearnedHealingLore is never set → a different story path.
    }

    /// <summary>
    /// A delayed, hidden consequence. Arms when the player leaves Cinder Hollow;
    /// fires ~30 days later if food was never restored. It has no player outcomes —
    /// it simply changes the world, and the player discovers it on return.
    /// </summary>
    private static WorldEvent BuildFoodShortage() => new()
    {
        Id = FoodShortageId,
        Location = "Cinder Hollow",
        Category = EventCategory.Local,
        Level = ConsequenceLevel.LongTerm,
        Priority = 40,

        Condition = ctx =>
        {
            if (ctx.State.GetFlag(WorldFacts.Flags.CinderFoodRestored))
                return false;
            int leftDay = ctx.State.GetValue(WorldFacts.Values.LeftCinderDay);
            if (leftDay <= 0)
                return false; // hasn't left yet
            return ctx.Clock.Day - leftDay >= 30;
        },

        // Ambient: activating IS the consequence — no deadline, no player choices.
        OnActivate = ctx => ctx.State.SetFlag(WorldFacts.Flags.CinderFoodShortage, true),
    };
}
