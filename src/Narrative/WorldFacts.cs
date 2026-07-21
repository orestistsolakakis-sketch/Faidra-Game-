namespace Lumenfall.Narrative;

/// <summary>
/// The central registry of well-known fact keys used with <see cref="WorldState"/>.
///
/// WHY IT EXISTS:
/// <see cref="WorldState"/> is keyed by strings. If systems typed those strings
/// inline, one typo ("elder_alive" vs "elder_alvie") would silently create a
/// second, always-false fact and a consequence chain would quietly break. By
/// funnelling every key through named constants here we get compile-time safety,
/// autocomplete, and one place to see every fact the game tracks.
///
/// This file grows as content is authored — treat it as the living index of the
/// world's tracked state. Group keys by area/system and keep names snake_case so
/// they read clearly in save files and debug output.
/// </summary>
public static class WorldFacts
{
    /// <summary>Boolean facts: "did this happen / is this true?".</summary>
    public static class Flags
    {
        // --- Level 01: Cinder Hollow (see docs/levels/01_CINDER_HOLLOW.md) ---

        /// <summary>Arlen restored the sealed freight elevator into the deep tunnels.</summary>
        public const string CinderFreightLiftRepaired = "cinder_freight_lift_repaired";

        /// <summary>Arlen's Sense (L2) ability has awoken.</summary>
        public const string SenseAwakened = "sense_awakened";

        /// <summary>The scripted first animal-heal has occurred (Arlen L3 seed).</summary>
        public const string FirstAnimalHealed = "first_animal_healed";

        /// <summary>The overfed Engine-fragment core has been stabilised (not shut down).</summary>
        public const string CinderCoreStabilised = "cinder_core_stabilised";

        /// <summary>The sick elder of Cinder Hollow is still alive.</summary>
        public const string ElderAlive = "elder_alive";

        /// <summary>Arlen and Lysandra have met (end of Level 01).</summary>
        public const string MetLysandra = "met_lysandra";

        // --- Cross-region examples (from the Systems Bible mission sample) ---

        /// <summary>The lift connecting Gearmarket and Cinder Hollow is repaired.</summary>
        public const string GearmarketLiftRepaired = "lift_gearmarket_repaired";

        // --- Event-system demonstration facts (Cinder Hollow living world) ---

        /// <summary>Cinder Hollow's main power generator has failed.</summary>
        public const string CinderGeneratorFailed = "cinder_generator_failed";

        /// <summary>Cinder Hollow's power has been restored (generator repaired/replaced).</summary>
        public const string CinderPowerRestored = "cinder_power_restored";

        /// <summary>The Cinder Hollow hospital is still open and operating.</summary>
        public const string CinderHospitalOpen = "cinder_hospital_open";

        /// <summary>The hospital doctor survived (depends on the hospital staying open).</summary>
        public const string CinderDoctorSurvived = "cinder_doctor_survived";

        /// <summary>The doctor taught Arlen about the nature of healing (a chain payoff).</summary>
        public const string ArlenLearnedHealingLore = "arlen_learned_healing_lore";

        /// <summary>Cinder Hollow's food supply has been restored.</summary>
        public const string CinderFoodRestored = "cinder_food_restored";

        /// <summary>The party has departed Cinder Hollow (arms delayed away-from-home events).</summary>
        public const string LeftCinderHollow = "left_cinder_hollow";

        /// <summary>A food shortage has taken hold in Cinder Hollow.</summary>
        public const string CinderFoodShortage = "cinder_food_shortage";
    }

    /// <summary>Integer facts: "how much / how many?".</summary>
    public static class Values
    {
        /// <summary>The World-Time day on which the party left Cinder Hollow (0 = not left).</summary>
        public const string LeftCinderDay = "left_cinder_day";

        /// <summary>
        /// Heart Engine stability, 0–100. Degrades as World Time passes; the
        /// spine of the "hurry vs. help" tension. 100 = stable at game start.
        /// </summary>
        public const string HeartEngineStability = "heart_engine_stability";

        /// <summary>The Continuance faction's influence. Grows if left unchecked.</summary>
        public const string ContinuanceInfluence = "continuance_influence";
    }
}
