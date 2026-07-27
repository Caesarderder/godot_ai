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
	"sonic": {2: "虚弱覆盖跨线目标", 3: "控制并处决普通守军"},
	"rocket": {2: "齐射当前阶段多个目标", 3: "对结构追加破甲"},
	"bomber": {2: "爆发波及同阶段目标", 3: "保留残血撤离能力"},
	"armored": {2: "炮击格挡、冲门与反震", 3: "更厚的全队护盾"},
	"saw": {2: "连续斩击精英", 3: "击杀后返还能量"},
	"repair": {2: "维修扩展为群体效果", 3: "强化救场能力"},
	"parasite": {2: "召唤更多寄生幼体", 3: "短暂策反普通守军"},
}


static func faction_for(archetype_id: String) -> String:
	return String(FACTIONS.get(archetype_id, "独立战术"))


static func next_star_effect(archetype_id: String, target_star: int) -> String:
	return String((STAR_EFFECTS.get(archetype_id, {}) as Dictionary).get(
		target_star,
		"当前已达到本切片最高质变"
	))
