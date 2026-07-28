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
	"signal_purifier": "干扰增殖",
	"anchor_bastion": "钢铁防线",
	"magnetic_conductor": "远程轰炸",
	"phase_tunneler": "快攻破城",
	"protocol_weaver": "干扰增殖",
	"ram_breaker": "快攻破城",
	"smoke_screen": "干扰增殖",
	"mortar": "远程轰炸",
	"interceptor": "远程轰炸",
	"bulwark": "钢铁防线",
	"crusher": "快攻破城",
	"echo_mimic": "干扰增殖",
	"drain_engine": "钢铁防线",
	"swarm_beacon": "干扰增殖",
	"chronolock": "干扰增殖",
}

const PLAYSTYLES: Dictionary = {
	"快攻破城": "抢先爆发",
	"钢铁防线": "承炮续战",
	"远程轰炸": "后排拆塔",
	"干扰增殖": "削弱控场",
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
	"signal_purifier": {2: "净化扩展至同阶段全队", 3: "净化后反向封锁控制源"},
	"anchor_bastion": {2: "锚区覆盖同阶段全队", 3: "抵抗冲击后开放集火窗口"},
	"magnetic_conductor": {2: "聚拢当前阶段全部普通守军", 3: "击破聚焦目标后返还能量"},
	"phase_tunneler": {2: "钻出位置留下泄压诱饵", 3: "击破后排后回程追斩并返能"},
	"protocol_weaver": {2: "夺取协议扩散至更多友军", 3: "每场首次夺取后额外重放"},
	"ram_breaker": {2: "碎盾冲击波及同阶段目标", 3: "成功碎盾后返还能量"},
	"smoke_screen": {2: "烟幕覆盖全队", 3: "烟幕反噬并虚弱精英"},
	"mortar": {2: "落点溅射同阶段目标", 3: "弹坑持续破甲结构"},
	"interceptor": {2: "截击盾覆盖全队", 3: "成功拦截后反击精英"},
	"bulwark": {2: "联结覆盖全部主力", 3: "联结结束时恢复生命"},
	"crusher": {2: "粉碎冲击震击同阶段守军", 3: "处决结构后返还能量"},
	"echo_mimic": {2: "回响扩散至多个目标", 3: "每场首次回响立即再蓄能"},
	"drain_engine": {2: "能量灌注两名友军", 3: "虹吸同时虚弱精英"},
	"swarm_beacon": {2: "额外投放诱饵幼体", 3: "幼体登场时削弱守军"},
	"chronolock": {2: "冻结延长并影响精英", 3: "冻结结束开放集火窗口"},
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

const TIER_TWO_TECH: Dictionary = {
	"快攻破城": {
		"title": "全军链式点火协议",
		"effect": "同阵营主力以50能量开局，其余永久主力也获得20能量，阵营核心带动全队进入首轮爆发",
		"choice_summary": "全队协同 · 同阵营50能量\n其余主力 +20能量",
		"effect_id": "opening_energy",
		"value": 50,
		"allied_value": 20,
	},
	"钢铁防线": {
		"title": "全域堡垒协议",
		"effect": "同阵营主力获得最大生命18%的20秒护盾，其余永久主力也获得8%护盾",
		"choice_summary": "全队协同 · 同阵营18%护盾\n其余主力 +8%护盾",
		"effect_id": "opening_shield",
		"value": 1800,
		"allied_value": 800,
		"duration_ticks": 100,
	},
	"远程轰炸": {
		"title": "纵深火力标定协议",
		"effect": "前两个战区的结构整局处于火力标定状态，受到的伤害提高25%",
		"choice_summary": "全队协同 · 覆盖2个战区\n结构承伤 +25%",
		"effect_id": "opening_armor_break",
		"zone_count": 2,
		"duration_ticks": 1200,
	},
	"干扰增殖": {
		"title": "纵深失序扩散协议",
		"effect": "前两个战区守军开局虚弱15秒，让控制、召唤与续航阵容完整展开",
		"choice_summary": "全队协同 · 覆盖2个战区\n守军虚弱 15秒",
		"effect_id": "opening_weakness",
		"zone_count": 2,
		"duration_ticks": 75,
	},
}

const TIER_TWO_SPECIALIZATION: Dictionary = {
	"快攻破城": {
		"title": "核心过载点火协议",
		"effect": "只强化同阵营主力，但以75能量开局，最快形成第一轮阵营连锁爆发",
		"choice_summary": "阵营专精 · 仅同阵营\n开局75能量",
		"effect_id": "opening_energy",
		"value": 75,
	},
	"钢铁防线": {
		"title": "核心壁垒协议",
		"effect": "只强化同阵营主力，但获得最大生命25%的20秒护盾，专注承住最高压力",
		"choice_summary": "阵营专精 · 仅同阵营\n获得25%护盾",
		"effect_id": "opening_shield",
		"value": 2500,
		"duration_ticks": 100,
	},
	"远程轰炸": {
		"title": "过载火力标定协议",
		"effect": "只标定首个战区，但使结构承伤提高40%，用于更快击穿第一道防线",
		"choice_summary": "阵营专精 · 覆盖1个战区\n结构承伤 +40%",
		"effect_id": "opening_armor_break",
		"armor_break_bp": 4000,
		"zone_count": 1,
		"duration_ticks": 1200,
	},
	"干扰增殖": {
		"title": "深度失序协议",
		"effect": "只影响首个战区，但使守军虚弱25秒，为增殖阵容争取更长展开时间",
		"choice_summary": "阵营专精 · 覆盖1个战区\n守军虚弱 25秒",
		"effect_id": "opening_weakness",
		"zone_count": 1,
		"duration_ticks": 125,
	},
}


static func faction_for(archetype_id: String) -> String:
	return String(FACTIONS.get(archetype_id, "独立战术"))


static func playstyle_for(archetype_id: String) -> String:
	return String(PLAYSTYLES.get(faction_for(archetype_id), "灵活应战"))


static func next_star_effect(archetype_id: String, target_star: int) -> String:
	return String((STAR_EFFECTS.get(archetype_id, {}) as Dictionary).get(
		target_star,
		"当前已达到本切片最高质变"
	))


static func tech_preview_for(archetype_id: String) -> Dictionary:
	return tech_protocol_for(archetype_id, 1)


static func tech_protocol_for(
	archetype_id: String,
	tier: int = 1,
	doctrine_id: String = "coordination"
) -> Dictionary:
	var faction := faction_for(archetype_id)
	var catalog := (
		TIER_TWO_SPECIALIZATION
		if tier >= 2 and doctrine_id == "specialization"
		else (TIER_TWO_TECH if tier >= 2 else TECH_PREVIEWS)
	)
	var preview := (catalog.get(faction, {}) as Dictionary).duplicate(true)
	if preview.is_empty():
		return {}
	preview["faction"] = faction
	preview["archetype_id"] = archetype_id
	preview["member_archetypes"] = archetypes_for_faction(faction)
	preview["tier"] = 2 if tier >= 2 else 1
	preview["activation_chapter"] = 4 if tier >= 2 else 3
	preview["doctrine_id"] = doctrine_id if tier >= 2 else ""
	return preview


static func tier_two_options_for(archetype_id: String) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for doctrine_id in ["coordination", "specialization"]:
		var protocol := tech_protocol_for(archetype_id, 2, doctrine_id)
		if protocol.is_empty():
			continue
		options.append({
			"doctrine_id": doctrine_id,
			"title": String(protocol.get("title", "Tier 2协议")),
			"effect": String(protocol.get("effect", "")),
			"choice_summary": String(protocol.get("choice_summary", "")),
			"action_label": (
				"选择全队协同"
				if doctrine_id == "coordination"
				else "选择阵营专精"
			),
		})
	return options


static func archetypes_for_faction(faction: String) -> Array[String]:
	var result: Array[String] = []
	for archetype_id_value in FACTIONS:
		if String(FACTIONS[archetype_id_value]) == faction:
			result.append(String(archetype_id_value))
	result.sort()
	return result
