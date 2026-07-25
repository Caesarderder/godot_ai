class_name CommandClassRegistry
extends RefCounted

const DURABLE_VALUE: String = "DURABLE_VALUE"
const REVERSIBLE_META: String = "REVERSIBLE_META"

const COMMAND_CLASSES: Dictionary = {
	"recruit_hero": DURABLE_VALUE,
	"train_hero": DURABLE_VALUE,
	"grant_resources": DURABLE_VALUE,
	"settle_battle": DURABLE_VALUE,
	"exchange_salvage": DURABLE_VALUE,
	"refresh_quests": DURABLE_VALUE,
	"claim_quest": DURABLE_VALUE,
	"refresh_achievements": DURABLE_VALUE,
	"claim_achievement": DURABLE_VALUE,
	"start_production": DURABLE_VALUE,
	"claim_production": DURABLE_VALUE,
	"claim_ready_productions": DURABLE_VALUE,
	"merge_heroes": DURABLE_VALUE,
	"set_formation": REVERSIBLE_META,
	"set_auto_skill_preference": REVERSIBLE_META,
}


static func has_command(command_type: String) -> bool:
	return COMMAND_CLASSES.has(command_type)


static func command_class(command_type: String) -> String:
	return String(COMMAND_CLASSES.get(command_type, "UNKNOWN"))
