class_name FactoryCatalog
extends RefCounted

const MATERIAL_KEYS: Array[String] = ["porcelain", "parts", "sludge"]

const _RECIPES: Array[Dictionary] = [
	{"recipe_id": "ordinary.assault", "display_name": "普通马桶人", "workshop": "ordinary", "rarity": "common", "rating": "B", "archetype_id": "assault", "class_id": "fighter", "duration_seconds": 5, "cost": {"porcelain": 20, "parts": 8, "sludge": 4}},
	{"recipe_id": "ordinary.sonic", "display_name": "故障闪电马桶人", "workshop": "ordinary", "rarity": "rare", "rating": "A", "archetype_id": "sonic", "class_id": "arcanist", "duration_seconds": 7, "cost": {"porcelain": 16, "parts": 14, "sludge": 10}},
	{"recipe_id": "flying.rocket", "display_name": "飞行四发射器马桶人", "workshop": "flying", "rarity": "common", "rating": "B", "archetype_id": "rocket", "class_id": "ranger", "duration_seconds": 10, "cost": {"porcelain": 10, "parts": 24, "sludge": 18}},
	{"recipe_id": "flying.bomber", "display_name": "炸弹桶马桶人", "workshop": "flying", "rarity": "rare", "rating": "A", "archetype_id": "bomber", "class_id": "ranger", "duration_seconds": 8, "cost": {"porcelain": 12, "parts": 18, "sludge": 22}},
	{"recipe_id": "heavy.armored", "display_name": "激光火箭筒马桶人", "workshop": "heavy", "rarity": "rare", "rating": "A", "archetype_id": "armored", "class_id": "guardian", "duration_seconds": 12, "cost": {"porcelain": 30, "parts": 28, "sludge": 12}},
	{"recipe_id": "heavy.saw", "display_name": "飞行双圆锯马桶人", "workshop": "heavy", "rarity": "legendary", "rating": "S", "archetype_id": "saw", "class_id": "fighter", "duration_seconds": 14, "cost": {"porcelain": 26, "parts": 34, "sludge": 14}},
	{"recipe_id": "special.repair", "display_name": "研究员马桶人", "workshop": "special", "rarity": "common", "rating": "B", "archetype_id": "repair", "class_id": "guardian", "duration_seconds": 15, "cost": {"porcelain": 18, "parts": 20, "sludge": 26}},
	{"recipe_id": "special.parasite", "display_name": "大型寄生虫马桶人", "workshop": "special", "rarity": "legendary", "rating": "S", "archetype_id": "parasite", "class_id": "arcanist", "duration_seconds": 18, "cost": {"porcelain": 16, "parts": 18, "sludge": 30}},
	{"recipe_id": "ordinary.signal_purifier", "display_name": "钢爪马桶人科学家", "workshop": "ordinary", "rarity": "rare", "rating": "A", "archetype_id": "signal_purifier", "class_id": "arcanist", "duration_seconds": 9, "cost": {"porcelain": 18, "parts": 16, "sludge": 12}},
	{"recipe_id": "heavy.anchor_bastion", "display_name": "巨型飞行马桶人", "workshop": "heavy", "rarity": "common", "rating": "B", "archetype_id": "anchor_bastion", "class_id": "guardian", "duration_seconds": 11, "cost": {"porcelain": 28, "parts": 24, "sludge": 10}},
	{"recipe_id": "flying.magnetic_conductor", "display_name": "冲击波直升机马桶人", "workshop": "flying", "rarity": "rare", "rating": "A", "archetype_id": "magnetic_conductor", "class_id": "ranger", "duration_seconds": 10, "cost": {"porcelain": 14, "parts": 26, "sludge": 16}},
	{"recipe_id": "ordinary.phase_tunneler", "display_name": "武士刀蜘蛛马桶人", "workshop": "ordinary", "rarity": "common", "rating": "B", "archetype_id": "phase_tunneler", "class_id": "fighter", "duration_seconds": 8, "cost": {"porcelain": 22, "parts": 16, "sludge": 10}},
	{"recipe_id": "special.protocol_weaver", "display_name": "寄生虫马桶人", "workshop": "special", "rarity": "legendary", "rating": "S", "archetype_id": "protocol_weaver", "class_id": "arcanist", "duration_seconds": 18, "cost": {"porcelain": 18, "parts": 22, "sludge": 28}},
	{"recipe_id": "ordinary.ram_breaker", "display_name": "喷气背包钢爪马桶人", "workshop": "ordinary", "rarity": "common", "rating": "B", "archetype_id": "ram_breaker", "class_id": "fighter", "duration_seconds": 8, "cost": {"porcelain": 24, "parts": 18, "sludge": 8}},
	{"recipe_id": "special.smoke_screen", "display_name": "硫酸桶马桶人", "workshop": "special", "rarity": "rare", "rating": "A", "archetype_id": "smoke_screen", "class_id": "arcanist", "duration_seconds": 10, "cost": {"porcelain": 16, "parts": 18, "sludge": 18}},
	{"recipe_id": "flying.mortar", "display_name": "喷气背包六发射器马桶人", "workshop": "flying", "rarity": "common", "rating": "B", "archetype_id": "mortar", "class_id": "ranger", "duration_seconds": 11, "cost": {"porcelain": 12, "parts": 28, "sludge": 16}},
	{"recipe_id": "flying.interceptor", "display_name": "直升机马桶人", "workshop": "flying", "rarity": "rare", "rating": "A", "archetype_id": "interceptor", "class_id": "ranger", "duration_seconds": 9, "cost": {"porcelain": 14, "parts": 30, "sludge": 12}},
	{"recipe_id": "heavy.bulwark", "display_name": "多头马桶人", "workshop": "heavy", "rarity": "common", "rating": "B", "archetype_id": "bulwark", "class_id": "guardian", "duration_seconds": 13, "cost": {"porcelain": 32, "parts": 22, "sludge": 10}},
	{"recipe_id": "heavy.crusher", "display_name": "圆锯突变马桶人", "workshop": "heavy", "rarity": "rare", "rating": "A", "archetype_id": "crusher", "class_id": "fighter", "duration_seconds": 12, "cost": {"porcelain": 28, "parts": 30, "sludge": 10}},
	{"recipe_id": "special.echo_mimic", "display_name": "DJ马桶人", "workshop": "special", "rarity": "legendary", "rating": "S", "archetype_id": "echo_mimic", "class_id": "arcanist", "duration_seconds": 19, "cost": {"porcelain": 16, "parts": 24, "sludge": 32}},
	{"recipe_id": "heavy.drain_engine", "display_name": "吸尘小便池人", "workshop": "heavy", "rarity": "rare", "rating": "A", "archetype_id": "drain_engine", "class_id": "guardian", "duration_seconds": 14, "cost": {"porcelain": 26, "parts": 26, "sludge": 20}},
	{"recipe_id": "special.swarm_beacon", "display_name": "直升机寄生虫马桶人", "workshop": "special", "rarity": "common", "rating": "B", "archetype_id": "swarm_beacon", "class_id": "arcanist", "duration_seconds": 12, "cost": {"porcelain": 18, "parts": 14, "sludge": 24}},
	{"recipe_id": "special.chronolock", "display_name": "硫酸骷髅马桶人", "workshop": "special", "rarity": "legendary", "rating": "S", "archetype_id": "chronolock", "class_id": "arcanist", "duration_seconds": 20, "cost": {"porcelain": 20, "parts": 28, "sludge": 34}},
]

const _ARCHETYPES: Dictionary = {
	"gman": {
		"display_name": "Gman",
		"role": "commander",
		"active_skill": "gman_overrun",
		"description": "原作地球马桶人阵营领袖；技能表现为本作玩法改编，不补写原作未说明的经历。",
	},
	"assault": {
		"display_name": "普通马桶人",
		"role": "frontline_breaker",
		"active_skill": "plunger_charge",
		"description": "Wiki 将白色或灰色陶瓷个体列为最常见的基础马桶人；皮搋冲锋是玩法改编。",
	},
	"sonic": {
		"display_name": "故障闪电马桶人",
		"role": "crowd_control",
		"active_skill": "sonic_disruptor",
		"description": "Wiki 记载其依靠高速撞击并具有声波电荷；跨线削弱与压制是玩法改编。",
	},
	"rocket": {
		"display_name": "飞行四发射器马桶人",
		"role": "siege_artillery",
		"active_skill": "rocket_salvo",
		"description": "Wiki 列出的四发射器喷气背包变体；齐射范围与结构破甲是玩法改编。",
	},
	"bomber": {
		"display_name": "炸弹桶马桶人",
		"role": "burst_sacrifice",
		"active_skill": "suicide_dive",
		"description": "Wiki 列出的天然飞行爆破变体；可存活返航的爆破载荷是玩法改编。",
	},
	"armored": {
		"display_name": "激光火箭筒马桶人",
		"role": "siege_tank",
		"active_skill": "siege_shield",
		"description": "Wiki 列出的轮式重武装变体；全队护盾、格挡巨炮与嘲讽是玩法改编。",
	},
	"saw": {
		"display_name": "飞行双圆锯马桶人",
		"role": "elite_duelist",
		"active_skill": "saw_rush",
		"description": "Wiki 列出的双圆锯喷气背包变体；精英连斩与击杀返能是玩法改编。",
	},
	"repair": {
		"display_name": "研究员马桶人",
		"role": "sustain_support",
		"active_skill": "field_repair",
		"description": "科学家页面提到其科学团队中的研究员马桶人；战地抢修与复苏是玩法改编。",
	},
	"parasite": {
		"display_name": "大型寄生虫马桶人",
		"role": "summoner_debuffer",
		"active_skill": "parasite_swarm",
		"description": "Wiki 记载大型寄生体曾长期控制泰坦音响人；幼体召唤与短时策反是玩法改编。",
	},
	"signal_purifier": {
		"display_name": "钢爪马桶人科学家",
		"role": "cleanse_support",
		"active_skill": "signal_cleanse",
		"description": "科学家页面提到钢爪科学家属于科研团队；白噪净化与反控护盾是玩法改编。",
	},
	"anchor_bastion": {
		"display_name": "巨型飞行马桶人",
		"role": "formation_anchor",
		"active_skill": "formation_anchor",
		"description": "Wiki 列出的天然飞行巨型变体；落锚护盾与阵型减伤是玩法改编。",
	},
	"magnetic_conductor": {
		"display_name": "冲击波直升机马桶人",
		"role": "enemy_grouper",
		"active_skill": "magnetic_convergence",
		"description": "Wiki 列出的旋翼冲击波变体；把分线守军聚拢并返能是玩法改编。",
	},
	"phase_tunneler": {
		"display_name": "武士刀蜘蛛马桶人",
		"role": "backline_raider",
		"active_skill": "phase_breach",
		"description": "Wiki 列出的蜘蛛腿武士刀变体；钻入后排与留下诱饵是玩法改编。",
	},
	"protocol_weaver": {
		"display_name": "寄生虫马桶人",
		"role": "buff_hijacker",
		"active_skill": "protocol_hijack",
		"description": "Wiki 列出的基础寄生马桶人；夺取敌方增益并转交友军是玩法改编。",
	},
	"ram_breaker": {"display_name": "喷气背包钢爪马桶人", "role": "shield_breaker", "active_skill": "ram_shatter", "description": "Wiki 列出的钢爪喷气背包变体；撞碎护盾与返能是玩法改编。"},
	"smoke_screen": {"display_name": "硫酸桶马桶人", "role": "evasion_support", "active_skill": "caustic_smokescreen", "description": "Wiki 列出的天然飞行硫酸载荷变体；保护友军的腐蚀烟幕是玩法改编。"},
	"mortar": {"display_name": "喷气背包六发射器马桶人", "role": "backline_siege", "active_skill": "sewer_mortar", "description": "Wiki 列出的六发射器喷气背包变体；曲射、溅射与弹坑破甲是玩法改编。"},
	"interceptor": {"display_name": "直升机马桶人", "role": "warning_interceptor", "active_skill": "warning_intercept", "description": "Wiki 列出的旋翼飞行变体；炮击截击盾与反击是玩法改编。"},
	"bulwark": {"display_name": "多头马桶人", "role": "damage_link", "active_skill": "linked_bulwark", "description": "Wiki 列出的多头蜘蛛腿变体；联结队友分担伤害与治疗是玩法改编。"},
	"crusher": {"display_name": "圆锯突变马桶人", "role": "structure_executor", "active_skill": "hydraulic_crush", "description": "Wiki 列出的人形圆锯突变体；结构处决与击破返能是玩法改编。"},
	"echo_mimic": {"display_name": "DJ马桶人", "role": "skill_echo", "active_skill": "allied_echo", "description": "Wiki 记载其使用独特混音、音波并经历多次升级；友军技能回响是玩法改编。"},
	"drain_engine": {"display_name": "吸尘小便池人", "role": "energy_support", "active_skill": "energy_siphon", "description": "Wiki 列出的轮式吸尘小便池变体；能量虹吸、充能与虚弱是玩法改编。"},
	"swarm_beacon": {"display_name": "直升机寄生虫马桶人", "role": "decoy_summoner", "active_skill": "decoy_bloom", "description": "Wiki 列出的旋翼寄生变体；投放诱饵幼体与削弱守军是玩法改编。"},
	"chronolock": {"display_name": "硫酸骷髅马桶人", "role": "tempo_controller", "active_skill": "chrono_lock", "description": "Wiki 将其列为可传送变体；冻结守军、延长控制与削防是玩法改编。"},
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
