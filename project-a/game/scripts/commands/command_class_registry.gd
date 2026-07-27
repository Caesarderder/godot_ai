class_name CommandClassRegistry
extends RefCounted

const DURABLE_VALUE: String = "DURABLE_VALUE"
const REVERSIBLE_META: String = "REVERSIBLE_META"

const COMMAND_CLASSES: Dictionary = {
	"grant_resources": DURABLE_VALUE,
	"settle_battle": DURABLE_VALUE,
	"claim_war_merit_reward": DURABLE_VALUE,
	"refresh_quests": DURABLE_VALUE,
	"claim_quest": DURABLE_VALUE,
	"unlock_foundational_blueprint": DURABLE_VALUE,
	"claim_blueprint_research": DURABLE_VALUE,
	"claim_scrap_recovery": DURABLE_VALUE,
	"claim_factory_output": DURABLE_VALUE,
	"claim_facility_output": DURABLE_VALUE,
	"upgrade_permanent_hero": DURABLE_VALUE,
	"upgrade_hero_star": DURABLE_VALUE,
	"research_active_skill": DURABLE_VALUE,
	"assign_factory_specialist": DURABLE_VALUE,
	"upgrade_facility": DURABLE_VALUE,
	"construct_facility": DURABLE_VALUE,
	"claim_facility_work": DURABLE_VALUE,
	"claim_onboarding_task": DURABLE_VALUE,
	"claim_starter_gift": DURABLE_VALUE,
	"claim_new_player_welfare": DURABLE_VALUE,
	"open_smuggled_logistics_case": DURABLE_VALUE,
	"use_welfare_star_core": DURABLE_VALUE,
	"refresh_achievements": DURABLE_VALUE,
	"claim_achievement": DURABLE_VALUE,
	"refresh_meta_progression": DURABLE_VALUE,
	"claim_meta_mission": DURABLE_VALUE,
	"claim_meta_pass_level": DURABLE_VALUE,
	"claim_all_meta_pass_levels": DURABLE_VALUE,
	"claim_commander_level_reward": DURABLE_VALUE,
	"claim_all_commander_level_rewards": DURABLE_VALUE,
	"claim_meta_achievement": DURABLE_VALUE,
	"claim_all_meta_achievements": DURABLE_VALUE,
	"assign_formation_slot": REVERSIBLE_META,
	"signal_recruit": DURABLE_VALUE,
	"claim_foundational_signal": DURABLE_VALUE,
	"claim_faction_signal": DURABLE_VALUE,
	"choose_faction_core": DURABLE_VALUE,
	"choose_faction_doctrine": DURABLE_VALUE,
	"set_formation": REVERSIBLE_META,
	"refill_formation": REVERSIBLE_META,
	"set_auto_skill_preference": REVERSIBLE_META,
}


static func has_command(command_type: String) -> bool:
	return COMMAND_CLASSES.has(command_type)


static func command_class(command_type: String) -> String:
	return String(COMMAND_CLASSES.get(command_type, "UNKNOWN"))
