class_name CommandClassRegistry
extends RefCounted

const UNKNOWN := -1
const DURABLE_VALUE := 0
const INTERNAL_DURABLE := 1
const REVERSIBLE_META := 2
const EPHEMERAL := 3

const _COMMAND_CLASSES: Dictionary = {
	&"recruit_hero": DURABLE_VALUE,
	&"train_hero": DURABLE_VALUE,
	&"enhance_item": DURABLE_VALUE,
	&"upgrade_facility": DURABLE_VALUE,
	&"claim_reward": DURABLE_VALUE,
	&"settle_battle_result": DURABLE_VALUE,
	&"settle_offline": DURABLE_VALUE,
	&"reserve_battle_attempt": DURABLE_VALUE,
	&"__lifecycle_pause_anchor": INTERNAL_DURABLE,
	&"__lifecycle_heartbeat_anchor": INTERNAL_DURABLE,
	&"__lifecycle_resume_settle": INTERNAL_DURABLE,
	&"set_formation": REVERSIBLE_META,
	&"equip_item": REVERSIBLE_META,
	&"unequip_item": REVERSIBLE_META,
	&"set_roster_filter": REVERSIBLE_META,
	&"rename_hero": REVERSIBLE_META,
	&"navigate_screen": EPHEMERAL,
	&"open_detail": EPHEMERAL,
	&"battle_tick": EPHEMERAL,
	&"play_vfx": EPHEMERAL,
	&"sort_preview": EPHEMERAL,
}


static func classify(command_type: StringName) -> int:
	return int(_COMMAND_CLASSES.get(command_type, UNKNOWN))


static func is_internal(command_type: StringName) -> bool:
	return classify(command_type) == INTERNAL_DURABLE
