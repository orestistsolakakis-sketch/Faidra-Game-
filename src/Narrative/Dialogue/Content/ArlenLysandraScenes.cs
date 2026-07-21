using System.Collections.Generic;
using Lumenfall.Narrative.Personality;
using Lumenfall.Narrative.Relationships;

namespace Lumenfall.Narrative.Dialogue.Content;

/// <summary>
/// Authored dialogue content for Arlen &amp; Lysandra — the first proof the engine
/// expresses the canonical designs in docs/DIALOGUE_SYSTEM_BIBLE.md:
/// intent-tagged choices, a timed opening line, relationship + personality +
/// memory effects, an info-gated confrontation, and conditional text variants
/// (the same line reading differently by Trust and by what Arlen once said).
/// </summary>
public static class ArlenLysandraScenes
{
    public const string Argument01Id = "ARLEN_LYSANDRA_ARGUMENT_01";

    public static void RegisterInto(DialogueLibrary library) => library.Register(BuildArgument01());

    private static DialogueScene BuildArgument01() => new()
    {
        Id = Argument01Id,
        Location = "On the road",
        Participants = new[] { Characters.Arlen, Characters.Lysandra },

        // Trigger: Lysandra found out Arlen hid something, while trust is still low.
        Available = ctx =>
            ctx.State.GetFlag(WorldFacts.Flags.ArlenHidInfoFromLysandra) &&
            ctx.Relationships.Get(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Trust) < 50,

        StartNodeId = "open",
        Nodes = new Dictionary<string, DialogueNode>
        {
            ["open"] = new DialogueNode
            {
                Id = "open",
                Speaker = Characters.Lysandra,
                Text = "You knew the entire time.",
                TimeLimitSeconds = 6.0,
                DefaultChoiceIndex = 3, // hesitation resolves to silence
                Choices = new[]
                {
                    new DialogueChoice
                    {
                        Label = "\"I knew something was wrong. I didn't know what.\"",
                        Tone = DialogueTone.Honest,
                        Next = "truth",
                        Effect = ctx =>
                        {
                            ctx.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Trust, 8);
                            ctx.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Understanding, 6);
                            ctx.Personality.Add(Characters.Arlen, PersonalityTraits.Arlen.Compassionate);
                        },
                    },
                    new DialogueChoice
                    {
                        Label = "\"You have a strange way of asking questions.\"",
                        Tone = DialogueTone.Sarcastic,
                        Next = "cold",
                        Effect = ctx =>
                        {
                            ctx.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Resentment, 3);
                            ctx.Personality.Add(Characters.Arlen, PersonalityTraits.Arlen.Cynical);
                        },
                    },
                    new DialogueChoice
                    {
                        Label = "\"I have no idea what you're talking about.\"",
                        Tone = DialogueTone.Defensive,
                        Next = "lie",
                        Effect = ctx =>
                        {
                            ctx.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Trust, -10);
                            ctx.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Resentment, 5);
                            ctx.Personality.Add(Characters.Arlen, PersonalityTraits.Arlen.Cynical);
                        },
                    },
                    new DialogueChoice
                    {
                        Label = "(Say nothing.)",
                        Tone = DialogueTone.Silence,
                        Next = "silence",
                        Effect = ctx =>
                        {
                            ctx.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Understanding, -5);
                            ctx.Personality.Add(Characters.Arlen, PersonalityTraits.Arlen.Independent);
                        },
                    },
                    // Info-gated: only if the player has uncovered the affair.
                    new DialogueChoice
                    {
                        Label = "\"Then why did the palace shut down the hospital?\"",
                        Tone = DialogueTone.Confront,
                        Available = ctx => ctx.State.GetFlag(WorldFacts.Flags.HasDiscoveredEwaldAffair),
                        Next = "confront",
                        Effect = ctx =>
                        {
                            ctx.Relationships.Adjust(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Understanding, 4);
                            ctx.Personality.Add(Characters.Arlen, PersonalityTraits.Arlen.Independent);
                        },
                    },
                },
            },

            ["truth"] = new DialogueNode
            {
                Id = "truth",
                Speaker = Characters.Lysandra,
                Text = "...Fine. But you tell me everything from now on.",
                TextVariants = new[]
                {
                    // Memory: callback to something Arlen said earlier in the game.
                    new DialogueTextVariant
                    {
                        When = ctx => ctx.State.GetFlag(WorldFacts.Flags.ArlenSaidPeopleDontChange),
                        Text = "You told me people don't change. Maybe you were wrong about that, too.",
                    },
                    // Warmth scales with the trust the honest answer just built.
                    new DialogueTextVariant
                    {
                        When = ctx => ctx.Relationships.Get(Characters.Arlen, Characters.Lysandra, RelationshipAxis.Trust) >= 40,
                        Text = "...Then we start over. Together.",
                    },
                },
                Next = null,
            },

            ["confront"] = new DialogueNode
            {
                Id = "confront",
                Speaker = Characters.Lysandra,
                Text = "...I didn't know about the hospital. I swear to you I didn't.",
                Next = null,
            },

            ["silence"] = new DialogueNode
            {
                Id = "silence",
                Speaker = Characters.Lysandra,
                Text = "Say something. Please.",
                OnEnter = ctx =>
                    ctx.Relationships.Adjust(Characters.Lysandra, Characters.Arlen, RelationshipAxis.Vulnerability, 4),
                Next = "cold",
            },

            ["lie"] = new DialogueNode
            {
                Id = "lie",
                Speaker = Characters.Lysandra,
                Text = "You're lying. I can see it.",
                Next = "cold",
            },

            ["cold"] = new DialogueNode
            {
                Id = "cold",
                Speaker = Characters.Lysandra,
                Text = "...I thought we were past this.",
                // Future consequence: Lysandra stops sharing secrets with Arlen.
                OnEnter = ctx => ctx.State.SetFlag(WorldFacts.Flags.LysandraGuardsSecrets, true),
                Next = null,
            },
        },
    };
}
