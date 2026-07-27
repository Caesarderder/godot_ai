class_name FactionCatalog
extends RefCounted


const FACTIONS: Dictionary = {
	"gman": "钢铁防线",
	"assault": "快攻破城",
	"armored": "钢铁防线",
	"repair": "钢铁防线",
	"rocket": "远程轰炸",
	"bomber": "远程轰炸",
	"sonic": "干扰增殖",
	"parasite": "干扰增殖",
	"saw": "快攻破城",
}

const STAR_EFFECTS: Dictionary = {
	"assault": {2: "突进顺劈多个目标", 3: "高倍率冲击并震慑"},
	"sonic": {2: "虚弱覆盖跨线目标", 3: "普通守军追加短暂眩晕"},
	"rocket": {2: "齐射当前阶段多个目标", 3: "对结构追加破甲"},
	"bomber": {2: "爆发波及同阶段目标", 3: "俯冲取消自损，保持当前生命"},
	"armored": {2: "炮击格挡、冲门与反震", 3: "更厚全队护盾并嘲讽精英"},
	"saw": {2: "连续斩击精英", 3: "击杀后返还能量"},
	"repair": {2: "维修扩展为群体效果", 3: "首次拉起一名倒下主力"},
	"parasite": {2: "召唤更多寄生幼体", 3: "短暂策反普通守军"},
}

const TECH_PREVIEWS: Dictionary = {
	"快攻破城": {
		"title": "连锁破城协议",
		"effect": "同阵营主力以额外30能量开局，更早形成第一次集中爆发",
		"effect_id": "opening_energy",
		"value": 30,
	},
	"钢铁防线": {
		"title": "移动堡垒协议",
		"effect": "同阵营主力开局获得最大生命12%的20秒护盾，把第一轮承压转为推进窗口",
		"effect_id": "opening_shield",
		"value": 1200,
		"duration_ticks": 100,
	},
	"远程轰炸": {
		"title": "火力标定协议",
		"effect": "首个战区的结构在本局持续处于火力标定状态，受到的伤害提高25%",
		"effect_id": "opening_armor_break",
		"duration_ticks": 1200,
	},
	"干扰增殖": {
		"title": "失序扩散协议",
		"effect": "首个战区守军开局虚弱10秒，为召唤、控制与续航争取展开时间",
		"effect_id": "opening_weakness",
		"duration_ticks": 50,
	},
}


static func faction_for(archetype_id: String) -> String:
	return String(FACTIONS.get(archetype_id, "独立战术"))


static func next_star_effect(archetype_id: String, target_star: int) -> String:
	return String((STAR_EFFECTS.get(archetype_id, {}) as Dictionary).get(
		target_star,
		"当前已达到本切片最高质变"
	))


static func tech_preview_for(archetype_id: String) -> Dictionary:
	var faction := faction_for(archetype_id)
	var preview := (TECH_PREVIEWS.get(faction, {}) as Dictionary).duplicate(true)
	if preview.is_empty():
		return {}
	preview["faction"] = faction
	preview["archetype_id"] = archetype_id
	preview["member_archetypes"] = archetypes_for_faction(faction)
	return preview


static func archetypes_for_faction(faction: String) -> Array[String]:
	var result: Array[String] = []
	for archetype_id_value in FACTIONS:
		if String(FACTIONS[archetype_id_value]) == faction:
			result.append(String(archetype_id_value))
	result.sort()
	return result
