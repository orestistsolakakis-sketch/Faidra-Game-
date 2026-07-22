class_name Traits
## Arlen's journey traits — the visible, buildable RPG-style stats the player
## shapes through dialogue answers (distinct from the hidden relationship values
## and the emergent personality archetypes). Traits are shown as percentages and
## gate/aid choices later in the journey. Access as Traits.COMPASSION etc.

const COMPASSION := "compassion"   # helping people, mercy, healing others
const RESOLVE := "resolve"         # grit, pushing through cost and pain
const CUNNING := "cunning"         # cleverness, leverage, reading a situation
const INSIGHT := "insight"         # noticing, understanding systems and people
const COURAGE := "courage"         # facing danger and hard truths

const ALL := [COMPASSION, RESOLVE, CUNNING, INSIGHT, COURAGE]

const START_VALUE := 20  # everyone begins with a little of each


static func display_name(trait_id: String) -> String:
	match trait_id:
		COMPASSION: return "Compassion"
		RESOLVE: return "Resolve"
		CUNNING: return "Cunning"
		INSIGHT: return "Insight"
		COURAGE: return "Courage"
		_: return trait_id
