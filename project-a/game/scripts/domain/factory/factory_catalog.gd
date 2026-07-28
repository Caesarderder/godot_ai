class_name FactoryCatalog
extends RefCounted

const MATERIAL_KEYS: Array[String] = ["porcelain", "parts", "sludge"]

const _RECIPES: Array[Dictionary] = [
	{"recipe_id": "ordinary.assault", "display_name": "冲锋马桶人", "workshop": "ordinary", "rarity": "common", "rating": "B", "archetype_id": "assault", "class_id": "fighter", "duration_seconds": 5, "cost": {"porcelain": 20, "parts": 8, "sludge": 4}},
	{"recipe_id": "ordinary.sonic", "display_name": "音波马桶人", "workshop": "ordinary", "rarity": "rare", "rating": "A", "archetype_id": "sonic", "class_id": "arcanist", "duration_seconds": 7, "cost": {"porcelain": 16, "parts": 14, "sludge": 10}},
	{"recipe_id": "flying.rocket", "display_name": "火箭飞行马桶人", "workshop": "flying", "rarity": "common", "rating": "B", "archetype_id": "rocket", "class_id": "ranger", "duration_seconds": 10, "cost": {"porcelain": 10, "parts": 24, "sludge": 18}},
	{"recipe_id": "flying.bomber", "display_name": "自爆飞行马桶人", "workshop": "flying", "rarity": "rare", "rating": "A", "archetype_id": "bomber", "class_id": "ranger", "duration_seconds": 8, "cost": {"porcelain": 12, "parts": 18, "sludge": 22}},
	{"recipe_id": "heavy.armored", "display_name": "装甲冲城马桶人", "workshop": "heavy", "rarity": "rare", "rating": "A", "archetype_id": "armored", "class_id": "guardian", "duration_seconds": 12, "cost": {"porcelain": 30, "parts": 28, "sludge": 12}},
	{"recipe_id": "heavy.saw", "display_name": "双锯重装马桶人", "workshop": "heavy", "rarity": "legendary", "rating": "S", "archetype_id": "saw", "class_id": "fighter", "duration_seconds": 14, "cost": {"porcelain": 26, "parts": 34, "sludge": 14}},
	{"recipe_id": "special.repair", "display_name": "维修马桶人", "workshop": "special", "rarity": "common", "rating": "B", "archetype_id": "repair", "class_id": "guardian", "duration_seconds": 15, "cost": {"porcelain": 18, "parts": 20, "sludge": 26}},
	{"recipe_id": "special.parasite", "display_name": "寄生母体马桶人", "workshop": "special", "rarity": "legendary", "rating": "S", "archetype_id": "parasite", "class_id": "arcanist", "duration_seconds": 18, "cost": {"porcelain": 16, "parts": 18, "sludge": 30}},
	{"recipe_id": "ordinary.signal_purifier", "display_name": "信号净化马桶人", "workshop": "ordinary", "rarity": "rare", "rating": "A", "archetype_id": "signal_purifier", "class_id": "arcanist", "duration_seconds": 9, "cost": {"porcelain": 18, "parts": 16, "sludge": 12}},
	{"recipe_id": "heavy.anchor_bastion", "display_name": "锚桩堡垒马桶人", "workshop": "heavy", "rarity": "common", "rating": "B", "archetype_id": "anchor_bastion", "class_id": "guardian", "duration_seconds": 11, "cost": {"porcelain": 28, "parts": 24, "sludge": 10}},
	{"recipe_id": "flying.magnetic_conductor", "display_name": "磁轨牵引马桶人", "workshop": "flying", "rarity": "rare", "rating": "A", "archetype_id": "magnetic_conductor", "class_id": "ranger", "duration_seconds": 10, "cost": {"porcelain": 14, "parts": 26, "sludge": 16}},
	{"recipe_id": "ordinary.phase_tunneler", "display_name": "相位钻袭马桶人", "workshop": "ordinary", "rarity": "common", "rating": "B", "archetype_id": "phase_tunneler", "class_id": "fighter", "duration_seconds": 8, "cost": {"porcelain": 22, "parts": 16, "sludge": 10}},
	{"recipe_id": "special.protocol_weaver", "display_name": "协议编织母体", "workshop": "special", "rarity": "legendary", "rating": "S", "archetype_id": "protocol_weaver", "class_id": "arcanist", "duration_seconds": 18, "cost": {"porcelain": 18, "parts": 22, "sludge": 28}},
	{"recipe_id": "ordinary.ram_breaker", "display_name": "破盾撞角马桶人", "workshop": "ordinary", "rarity": "common", "rating": "B", "archetype_id": "ram_breaker", "class_id": "fighter", "duration_seconds": 8, "cost": {"porcelain": 24, "parts": 18, "sludge": 8}},
	{"recipe_id": "special.smoke_screen", "display_name": "烟幕喷射马桶人", "workshop": "special", "rarity": "rare", "rating": "A", "archetype_id": "smoke_screen", "class_id": "arcanist", "duration_seconds": 10, "cost": {"porcelain": 16, "parts": 18, "sludge": 18}},
	{"recipe_id": "flying.mortar", "display_name": "曲射臼炮马桶人", "workshop": "flying", "rarity": "common", "rating": "B", "archetype_id": "mortar", "class_id": "ranger", "duration_seconds": 11, "cost": {"porcelain": 12, "parts": 28, "sludge": 16}},
	{"recipe_id": "flying.interceptor", "display_name": "预警截击马桶人", "workshop": "flying", "rarity": "rare", "rating": "A", "archetype_id": "interceptor", "class_id": "ranger", "duration_seconds": 9, "cost": {"porcelain": 14, "parts": 30, "sludge": 12}},
	{"recipe_id": "heavy.bulwark", "display_name": "联结壁垒马桶人", "workshop": "heavy", "rarity": "common", "rating": "B", "archetype_id": "bulwark", "class_id": "guardian", "duration_seconds": 13, "cost": {"porcelain": 32, "parts": 22, "sludge": 10}},
	{"recipe_id": "heavy.crusher", "display_name": "液压粉碎马桶人", "workshop": "heavy", "rarity": "rare", "rating": "A", "archetype_id": "crusher", "class_id": "fighter", "duration_seconds": 12, "cost": {"porcelain": 28, "parts": 30, "sludge": 10}},
	{"recipe_id": "special.echo_mimic", "display_name": "回声拟态母体", "workshop": "special", "rarity": "legendary", "rating": "S", "archetype_id": "echo_mimic", "class_id": "arcanist", "duration_seconds": 19, "cost": {"porcelain": 16, "parts": 24, "sludge": 32}},
	{"recipe_id": "heavy.drain_engine", "display_name": "虹吸引擎马桶人", "workshop": "heavy", "rarity": "rare", "rating": "A", "archetype_id": "drain_engine", "class_id": "guardian", "duration_seconds": 14, "cost": {"porcelain": 26, "parts": 26, "sludge": 20}},
	{"recipe_id": "special.swarm_beacon", "display_name": "群落信标马桶人", "workshop": "special", "rarity": "common", "rating": "B", "archetype_id": "swarm_beacon", "class_id": "arcanist", "duration_seconds": 12, "cost": {"porcelain": 18, "parts": 14, "sludge": 24}},
	{"recipe_id": "special.chronolock", "display_name": "时序锁定母体", "workshop": "special", "rarity": "legendary", "rating": "S", "archetype_id": "chronolock", "class_id": "arcanist", "duration_seconds": 20, "cost": {"porcelain": 20, "parts": 28, "sludge": 34}},
]

const _ARCHETYPES: Dictionary = {
	"gman": {
		"display_name": "Gman",
		"role": "commander",
		"active_skill": "gman_overrun",
		"description": "开局唯一指挥官，前三关可以独自碾压城市防线。",
	},
	"assault": {
		"display_name": "冲锋马桶人",
		"role": "frontline_breaker",
		"active_skill": "plunger_charge",
		"description": "快速接敌，优先清理联盟守军，2星获得顺劈，3星额外震慑目标。",
	},
	"sonic": {
		"display_name": "音波马桶人",
		"role": "crowd_control",
		"active_skill": "sonic_disruptor",
		"description": "用音波压制守军火力，2星把虚弱扩展到全线，3星追加短暂眩晕。",
	},
	"rocket": {
		"display_name": "火箭飞行马桶人",
		"role": "siege_artillery",
		"active_skill": "rocket_salvo",
		"description": "远程轰炸设施与守军，2星增加爆炸半径，3星追加破甲。",
	},
	"bomber": {
		"display_name": "自爆飞行马桶人",
		"role": "burst_sacrifice",
		"active_skill": "suicide_dive",
		"description": "对当前目标造成爆发冲击，2星波及同阶段目标，3星俯冲不再自损。",
	},
	"armored": {
		"display_name": "装甲冲城马桶人",
		"role": "siege_tank",
		"active_skill": "siege_shield",
		"description": "给队伍顶盾并承受火力，2星附带冲门伤害，3星护盾更厚并嘲讽精英。",
	},
	"saw": {
		"display_name": "双锯重装马桶人",
		"role": "elite_duelist",
		"active_skill": "saw_rush",
		"description": "专门切割精英和装甲，2星连斩，3星击杀后返还能量。",
	},
	"repair": {
		"display_name": "维修马桶人",
		"role": "sustain_support",
		"active_skill": "field_repair",
		"description": "修复低血主力，2星群体小修，3星可拉起一名刚倒下主力。",
	},
	"parasite": {
		"display_name": "寄生母体马桶人",
		"role": "summoner_debuffer",
		"active_skill": "parasite_swarm",
		"description": "召唤寄生幼体牵制守军，2星幼体更强，3星短暂策反普通守军。",
	},
	"signal_purifier": {
		"display_name": "信号净化马桶人",
		"role": "cleanse_support",
		"active_skill": "signal_cleanse",
		"description": "净化控制并保护关键成员，2星扩展全队，3星反向封锁施法源。",
	},
	"anchor_bastion": {
		"display_name": "锚桩堡垒马桶人",
		"role": "formation_anchor",
		"active_skill": "formation_anchor",
		"description": "落锚守住阵型，2星覆盖全队，3星把位移冲击转成集火窗口。",
	},
	"magnetic_conductor": {
		"display_name": "磁轨牵引马桶人",
		"role": "enemy_grouper",
		"active_skill": "magnetic_convergence",
		"description": "把分线守军聚拢，2星扩大覆盖，3星击破标记目标返还能量。",
	},
	"phase_tunneler": {
		"display_name": "相位钻袭马桶人",
		"role": "backline_raider",
		"active_skill": "phase_breach",
		"description": "绕过前排突袭后排结构，2星制造诱饵，3星击破后返还能量。",
	},
	"protocol_weaver": {
		"display_name": "协议编织母体",
		"role": "buff_hijacker",
		"active_skill": "protocol_hijack",
		"description": "夺取精英护盾并改写为己方优势，2星扩散，3星额外重放。",
	},
	"ram_breaker": {"display_name": "破盾撞角马桶人", "role": "shield_breaker", "active_skill": "ram_shatter", "description": "撞碎护盾并制造破防窗口；二星波及同阶段，三星把碎盾转成返能。"},
	"smoke_screen": {"display_name": "烟幕喷射马桶人", "role": "evasion_support", "active_skill": "caustic_smokescreen", "description": "用腐蚀烟幕保护低血主力；二星覆盖全队，三星反噬当前精英。"},
	"mortar": {"display_name": "曲射臼炮马桶人", "role": "backline_siege", "active_skill": "sewer_mortar", "description": "越过守军轰击最远结构；二星溅射，三星留下持续破甲。"},
	"interceptor": {"display_name": "预警截击马桶人", "role": "warning_interceptor", "active_skill": "warning_intercept", "description": "在炮击预警中建立截击盾；二星覆盖全队，三星反击精英。"},
	"bulwark": {"display_name": "联结壁垒马桶人", "role": "damage_link", "active_skill": "linked_bulwark", "description": "联结两名低血主力分担压力；二星覆盖全队，三星联结结束时治疗。"},
	"crusher": {"display_name": "液压粉碎马桶人", "role": "structure_executor", "active_skill": "hydraulic_crush", "description": "处决残血结构；二星同时震击守军，三星成功处决返还能量。"},
	"echo_mimic": {"display_name": "回声拟态母体", "role": "skill_echo", "active_skill": "allied_echo", "description": "重放最近的友军战术冲击；二星扩散，三星每场首次免耗回响。"},
	"drain_engine": {"display_name": "虹吸引擎马桶人", "role": "energy_support", "active_skill": "energy_siphon", "description": "从精英火力中虹吸能量给最低能量友军；二星双目标，三星附加虚弱。"},
	"swarm_beacon": {"display_name": "群落信标马桶人", "role": "decoy_summoner", "active_skill": "decoy_bloom", "description": "投放诱饵幼体吸引火力；二星增加数量，三星幼体爆裂削弱敌军。"},
	"chronolock": {"display_name": "时序锁定母体", "role": "tempo_controller", "active_skill": "chrono_lock", "description": "冻结当前阶段敌军行动；二星延长并波及精英，三星冻结结束制造集火窗口。"},
}


static func recipes() -> Array[Dictionary]:
	return _RECIPES.duplicate(true)


static func recipe(recipe_id: String) -> Dictionary:
	for item in _RECIPES:
		if String(item["recipe_id"]) == recipe_id:
			return item.duplicate(true)
	return {}


static func has_recipe(recipe_id: String) -> bool:
	return not recipe(recipe_id).is_empty()


static func recipe_for_archetype(archetype_id: String) -> Dictionary:
	for item in _RECIPES:
		if String(item["archetype_id"]) == archetype_id:
			return item.duplicate(true)
	return {}


static func archetypes() -> Dictionary:
	return _ARCHETYPES.duplicate(true)


static func archetype(archetype_id: String) -> Dictionary:
	return (_ARCHETYPES.get(archetype_id, {}) as Dictionary).duplicate(true)


static func active_skill_for_archetype(archetype_id: String) -> String:
	var data := archetype(archetype_id)
	return String(data.get("active_skill", ""))
