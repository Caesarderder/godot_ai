class_name FactoryCatalog
extends RefCounted

const MATERIAL_KEYS: Array[String] = ["porcelain", "parts", "sludge"]

const _RECIPES: Array[Dictionary] = [
	{"recipe_id": "ordinary.assault", "display_name": "冲锋马桶人", "workshop": "ordinary", "rarity": "common", "archetype_id": "assault", "class_id": "fighter", "duration_seconds": 5, "cost": {"porcelain": 20, "parts": 8, "sludge": 4}},
	{"recipe_id": "ordinary.sonic", "display_name": "音波马桶人", "workshop": "ordinary", "rarity": "common", "archetype_id": "sonic", "class_id": "arcanist", "duration_seconds": 7, "cost": {"porcelain": 16, "parts": 14, "sludge": 10}},
	{"recipe_id": "flying.rocket", "display_name": "火箭飞行马桶人", "workshop": "flying", "rarity": "rare", "archetype_id": "rocket", "class_id": "ranger", "duration_seconds": 10, "cost": {"porcelain": 10, "parts": 24, "sludge": 18}},
	{"recipe_id": "flying.bomber", "display_name": "自爆飞行马桶人", "workshop": "flying", "rarity": "rare", "archetype_id": "bomber", "class_id": "ranger", "duration_seconds": 8, "cost": {"porcelain": 12, "parts": 18, "sludge": 22}},
	{"recipe_id": "heavy.armored", "display_name": "装甲冲城马桶人", "workshop": "heavy", "rarity": "rare", "archetype_id": "armored", "class_id": "guardian", "duration_seconds": 12, "cost": {"porcelain": 30, "parts": 28, "sludge": 12}},
	{"recipe_id": "heavy.saw", "display_name": "双锯重装马桶人", "workshop": "heavy", "rarity": "epic", "archetype_id": "saw", "class_id": "fighter", "duration_seconds": 14, "cost": {"porcelain": 26, "parts": 34, "sludge": 14}},
	{"recipe_id": "special.repair", "display_name": "维修马桶人", "workshop": "special", "rarity": "epic", "archetype_id": "repair", "class_id": "guardian", "duration_seconds": 15, "cost": {"porcelain": 18, "parts": 20, "sludge": 26}},
	{"recipe_id": "special.parasite", "display_name": "寄生母体马桶人", "workshop": "special", "rarity": "legendary", "archetype_id": "parasite", "class_id": "arcanist", "duration_seconds": 18, "cost": {"porcelain": 16, "parts": 18, "sludge": 30}},
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
		"description": "用音波压制守军火力，2星延长虚弱，3星扩展到全线。",
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
		"description": "对当前目标造成爆发冲击，2星波及同阶段目标，3星保留残血撤离。",
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
