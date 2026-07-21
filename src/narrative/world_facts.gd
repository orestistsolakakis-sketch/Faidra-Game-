class_name WorldFacts
## The central, typo-safe registry of fact keys used with WorldState. Funnelling
## every key through named constants prevents a typo silently creating a dead
## fact. This is the living index of tracked world state. Access as
## WorldFacts.Flags.ELDER_ALIVE etc.


class Flags:
	# Level 01: Cinder Hollow (see docs/levels/01_CINDER_HOLLOW.md)
	const CINDER_FREIGHT_LIFT_REPAIRED := "cinder_freight_lift_repaired"
	const SENSE_AWAKENED := "sense_awakened"
	const FIRST_ANIMAL_HEALED := "first_animal_healed"
	const CINDER_CORE_STABILISED := "cinder_core_stabilised"
	const ELDER_ALIVE := "elder_alive"
	const MET_LYSANDRA := "met_lysandra"

	# Cross-region
	const GEARMARKET_LIFT_REPAIRED := "lift_gearmarket_repaired"

	# Event-system demonstration (Cinder Hollow living world)
	const CINDER_GENERATOR_FAILED := "cinder_generator_failed"
	const CINDER_POWER_RESTORED := "cinder_power_restored"
	const CINDER_HOSPITAL_OPEN := "cinder_hospital_open"
	const CINDER_DOCTOR_SURVIVED := "cinder_doctor_survived"
	const ARLEN_LEARNED_HEALING_LORE := "arlen_learned_healing_lore"
	const CINDER_FOOD_RESTORED := "cinder_food_restored"
	const LEFT_CINDER_HOLLOW := "left_cinder_hollow"
	const CINDER_FOOD_SHORTAGE := "cinder_food_shortage"

	# Level 01 opening (Cinder Hollow, Arlen solo)
	const CINDER_WORKSHOP_DOOR_FIXED := "cinder_workshop_door_fixed"
	const TALKED_TO_BRAM := "cinder_talked_to_bram"
	const CINDER_LIFT_INSPECTED := "cinder_lift_inspected"

	# Dialogue: knowledge & memory
	const ARLEN_HID_INFO_FROM_LYSANDRA := "arlen_hid_info_from_lysandra"
	const HAS_DISCOVERED_EWALD_AFFAIR := "has_discovered_ewald_affair"
	const ARLEN_SAID_PEOPLE_DONT_CHANGE := "arlen_said_people_dont_change"
	const LYSANDRA_GUARDS_SECRETS := "lysandra_guards_secrets"


class Values:
	const LEFT_CINDER_DAY := "left_cinder_day"
	const HEART_ENGINE_STABILITY := "heart_engine_stability"
	const CONTINUANCE_INFLUENCE := "continuance_influence"
