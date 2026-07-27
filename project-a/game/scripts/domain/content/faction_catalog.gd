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
		"effect": "围绕首次破坏结构后的连续突进窗口，放大冲锋、双锯与自爆的抢攻节奏",
	},
	"钢铁防线": {
		"title": "移动堡垒协议",
		"effect": "围绕格挡后的反攻窗口，让装甲、维修与 Gman 把承压转成持续推进",
	},
	"远程轰炸": {
		"title": "火力标定协议",
		"effect": "围绕结构破甲后的集火窗口，让火箭、自爆与 Gman 更快拆除关键设施",
	},
	"干扰增殖": {
		"title": "失序扩散协议",
		"effect": "围绕虚弱目标的控制窗口，让音波、寄生与维修扩大召唤和续航优势",
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
	return preview
