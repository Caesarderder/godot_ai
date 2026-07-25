class_name StageCatalog
extends RefCounted

const ACT1_STAGE_IDS: Array[String] = [
	"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
	"stage_2_1", "stage_2_2", "stage_2_3", "stage_2_4", "stage_2_5",
	"stage_3_1", "stage_3_2", "stage_3_3", "stage_3_4", "stage_3_5",
	"stage_4_1", "stage_4_2", "stage_4_3", "stage_4_4", "stage_4_5",
	"stage_5_1", "stage_5_2", "stage_5_3", "stage_5_4", "stage_5_5",
]

const DEFAULT_STAGE_ID: String = "stage_1_1"
const DEFAULT_STAGE_NAMES: Array[String] = ["城市外围", "火力封锁区", "基地广场"]


static func all_stage_ids() -> Array[String]:
	return ACT1_STAGE_IDS.duplicate()


static func has_stage(stage_id: String) -> bool:
	return ACT1_STAGE_IDS.has(stage_id)


static func stage(stage_id: String = DEFAULT_STAGE_ID) -> Dictionary:
	if not has_stage(stage_id):
		return {}
	var index := ACT1_STAGE_IDS.find(stage_id)
	var chapter := int(index / 5) + 1
	var stage_in_chapter := int(index % 5) + 1
	var power_bp := 10000 + chapter * 1800 + stage_in_chapter * 650
	if stage_id == DEFAULT_STAGE_ID:
		power_bp = 10000
	var config := _base_stage(stage_id, chapter, stage_in_chapter, power_bp)
	if stage_id == DEFAULT_STAGE_ID:
		config["enemies"] = _legacy_stage_1_1_enemies()
		config["structures"] = _legacy_stage_1_1_structures()
		config["reward_victory"] = {"gold": 80, "xp_books": 1, "porcelain": 24, "parts": 16, "sludge": 12}
		config["reward_defeat"] = {"gold": 12, "xp_books": 2, "porcelain": 8, "parts": 5, "sludge": 4}
		config["reward_timeout"] = {"gold": 6, "xp_books": 2, "porcelain": 4, "parts": 3, "sludge": 2}
		config["unlock_on_defeat"] = ["flying.rocket", "heavy.armored"]
		config["unlock_on_timeout"] = ["flying.rocket", "heavy.armored"]
		config["unlock_on_victory"] = ["flying.rocket", "heavy.armored", "flying.bomber", "heavy.saw", "special.repair", "special.parasite"]
		return config
	config["enemies"] = _scaled_enemies(_enemy_template_for(chapter, stage_in_chapter), power_bp)
	config["structures"] = _scaled_structures(_structure_template_for(chapter, stage_in_chapter), power_bp)
	return config


static func reward_for(stage_id: String, outcome: String) -> Dictionary:
	var config := stage(stage_id)
	if config.is_empty():
		return {}
	var key := "reward_%s" % outcome
	return (config.get(key, config.get("reward_defeat", {})) as Dictionary).duplicate(true)


static func next_stage_id(stage_id: String) -> String:
	var config := stage(stage_id)
	return String(config.get("next_stage_id", ""))


static func unlocks_for(stage_id: String, outcome: String) -> Array[String]:
	var config := stage(stage_id)
	if config.is_empty():
		return []
	var key := "unlock_on_%s" % outcome
	var values: Array[String] = []
	for recipe_id in config.get(key, []):
		values.append(String(recipe_id))
	return values


static func _base_stage(stage_id: String, chapter: int, stage_in_chapter: int, power_bp: int) -> Dictionary:
	var index := ACT1_STAGE_IDS.find(stage_id)
	var boss_names := {
		1: "灰镜核心巨炮",
		2: "共振堡垒",
		3: "黑屏中继塔",
		4: "三联军械库",
		5: "审判之门",
	}
	var chapter_names := {
		1: "灰镜街区",
		2: "震荡封锁线",
		3: "黑屏城区",
		4: "三军联合防线",
		5: "伪胜之城",
	}
	var next_id := ACT1_STAGE_IDS[index + 1] if index >= 0 and index + 1 < ACT1_STAGE_IDS.size() else ""
	var is_boss := stage_in_chapter == 5
	var reward_scale := chapter * 8 + stage_in_chapter * 3
	var unlock_victory: Array[String] = []
	if stage_id == "stage_1_3":
		unlock_victory.append("heavy.armored")
	elif stage_id == "stage_1_5":
		unlock_victory.append("flying.rocket")
	elif stage_id == "stage_2_3":
		unlock_victory.append("flying.bomber")
	elif stage_id == "stage_2_5":
		unlock_victory.append("special.repair")
	elif stage_id == "stage_3_3":
		unlock_victory.append("special.parasite")
	elif stage_id == "stage_4_3":
		unlock_victory.append("heavy.saw")
	var readability := _readability_fields(stage_id, chapter, stage_in_chapter, unlock_victory)
	var recommendation := _recommendation_fields(stage_id)
	return {
		"stage_id": stage_id,
		"act": 1,
		"chapter": chapter,
		"stage_in_chapter": stage_in_chapter,
		"display_name": "%d-%d %s" % [chapter, stage_in_chapter, boss_names.get(chapter, "联盟基地") if is_boss else chapter_names.get(chapter, "城市大道")],
		"stage_names": DEFAULT_STAGE_NAMES.duplicate(),
		"max_ticks": 360 if is_boss else 300,
		"final_structure_id": "alliance_core",
		"suppressible_cannon": is_boss,
		"cannon_suppression_target": _cannon_suppression_target(chapter) if is_boss else 0,
		"cannon_warning_ticks": 20 if is_boss else 0,
		"next_stage_id": next_id,
		"reward_victory": {"gold": 60 + reward_scale, "xp_books": 1 + int(stage_in_chapter >= 4), "porcelain": 18 + reward_scale, "parts": 12 + reward_scale, "sludge": 8 + reward_scale},
		"reward_defeat": {"gold": 10 + chapter, "xp_books": 2, "porcelain": 7 + chapter, "parts": 4 + chapter, "sludge": 3 + chapter},
		"reward_timeout": {"gold": 5 + chapter, "xp_books": 2, "porcelain": 4 + chapter, "parts": 3 + chapter, "sludge": 2 + chapter},
		"unlock_on_defeat": ["flying.rocket", "heavy.armored"] if stage_id == DEFAULT_STAGE_ID else [],
		"unlock_on_timeout": ["flying.rocket", "heavy.armored"] if stage_id == DEFAULT_STAGE_ID else [],
		"unlock_on_victory": unlock_victory,
		"unlock_preview": readability["unlock_preview"],
		"threat_summary": readability["threat_summary"],
		"counter_hint": readability["counter_hint"],
		"chapter_feedback": readability["chapter_feedback"],
		"recommended_recipe_ids": recommendation["recommended_recipe_ids"],
		"fallback_recipe_ids": recommendation["fallback_recipe_ids"],
		"recommendation_reason": recommendation["recommendation_reason"],
		"power_bp": power_bp,
	}


static func _cannon_suppression_target(chapter: int) -> int:
	var targets := {
		1: 70,
		2: 85,
		3: 100,
		4: 115,
		5: 130,
	}
	return int(targets.get(chapter, 70))


static func _recommendation_fields(stage_id: String) -> Dictionary:
	var recommendations: Dictionary = {
		"stage_1_1": {
			"recommended": ["ordinary.assault", "ordinary.sonic"],
			"fallback": [],
			"reason": "初战只依赖初始普通车间：冲锋负责推进，音波负责削弱摄像守军。",
		},
		"stage_1_2": {
			"recommended": ["ordinary.assault", "ordinary.sonic"],
			"fallback": ["heavy.armored", "flying.rocket"],
			"reason": "继续用初始双核处理侧翼压力；若已触发反攻蓝图，可补装甲或火箭。",
		},
		"stage_1_3": {
			"recommended": ["ordinary.sonic", "ordinary.assault"],
			"fallback": ["heavy.armored"],
			"reason": "中段门槛先用音波压低精英火力，胜利后再把装甲纳入主阵容。",
		},
		"stage_1_4": {
			"recommended": ["heavy.armored", "ordinary.sonic"],
			"fallback": ["ordinary.assault"],
			"reason": "装甲护盾承接炮塔与精英压力，音波降低前线损耗。",
		},
		"stage_1_5": {
			"recommended": ["heavy.armored", "ordinary.sonic", "ordinary.assault"],
			"fallback": ["flying.rocket"],
			"reason": "章节 Boss 先用装甲抗炮击，火箭作为胜利后的结构反制预期。",
		},
		"stage_2_1": {
			"recommended": ["heavy.armored", "flying.rocket"],
			"fallback": ["ordinary.sonic"],
			"reason": "进入声波封锁线后，用装甲保队伍站位，火箭加速拆设施。",
		},
		"stage_2_2": {
			"recommended": ["heavy.armored", "ordinary.sonic"],
			"fallback": ["flying.rocket"],
			"reason": "能量干扰会拉长战斗，装甲与音波组合更稳定。",
		},
		"stage_2_3": {
			"recommended": ["flying.rocket", "heavy.armored"],
			"fallback": ["flying.bomber"],
			"reason": "火箭处理防御设施，装甲维持推进；自爆作为本关后的爆发解法。",
		},
		"stage_2_4": {
			"recommended": ["flying.bomber", "heavy.armored"],
			"fallback": ["ordinary.sonic"],
			"reason": "自爆快速削阶段目标，装甲避免队伍被精英火力打散。",
		},
		"stage_2_5": {
			"recommended": ["heavy.armored", "flying.bomber", "flying.rocket"],
			"fallback": ["special.repair"],
			"reason": "章节 Boss 需要承压、爆发和拆结构；维修作为通关后的续航答案。",
		},
		"stage_3_1": {
			"recommended": ["special.repair", "heavy.armored"],
			"fallback": ["ordinary.sonic"],
			"reason": "TV 控制会制造点杀窗口，维修和装甲提高容错。",
		},
		"stage_3_2": {
			"recommended": ["special.repair", "flying.rocket"],
			"fallback": ["heavy.armored"],
			"reason": "维修保住被控制的低血单位，火箭远程拆核心设施。",
		},
		"stage_3_3": {
			"recommended": ["ordinary.sonic", "special.repair"],
			"fallback": ["special.parasite"],
			"reason": "音波削弱控制链，维修兜底；寄生作为本关后反控和牵制方案。",
		},
		"stage_3_4": {
			"recommended": ["special.parasite", "special.repair"],
			"fallback": ["flying.rocket"],
			"reason": "寄生幼体分摊精英火力，维修保证主队不被连续控制击穿。",
		},
		"stage_3_5": {
			"recommended": ["special.repair", "special.parasite", "flying.rocket"],
			"fallback": ["heavy.armored"],
			"reason": "Boss 持续轰炸下，维修与寄生提升存活，火箭负责打核心结构。",
		},
		"stage_4_1": {
			"recommended": ["special.parasite", "heavy.armored"],
			"fallback": ["flying.rocket"],
			"reason": "联合部队精英护盾增多，寄生分散仇恨，装甲承接集火。",
		},
		"stage_4_2": {
			"recommended": ["flying.rocket", "ordinary.sonic"],
			"fallback": ["special.repair"],
			"reason": "火箭针对结构与护甲，音波削弱联合守军输出。",
		},
		"stage_4_3": {
			"recommended": ["flying.rocket", "special.repair"],
			"fallback": ["heavy.saw"],
			"reason": "维修抗持续伤害，火箭拆模块；双锯作为本关后的精英反制。",
		},
		"stage_4_4": {
			"recommended": ["heavy.saw", "special.repair"],
			"fallback": ["flying.rocket"],
			"reason": "双锯专门切精英，维修防止队伍在精英压力关崩盘。",
		},
		"stage_4_5": {
			"recommended": ["heavy.saw", "flying.rocket", "special.repair"],
			"fallback": ["heavy.armored"],
			"reason": "章节 Boss 同时考验反精英、破甲和续航，双锯火箭维修形成核心组合。",
		},
		"stage_5_1": {
			"recommended": ["special.repair", "heavy.saw"],
			"fallback": ["flying.rocket"],
			"reason": "终章炮火密度提高，维修防减员，双锯处理高威胁精英。",
		},
		"stage_5_2": {
			"recommended": ["heavy.armored", "special.repair"],
			"fallback": ["special.parasite"],
			"reason": "诱导撤退和持续轰炸要求前排硬度与稳定恢复。",
		},
		"stage_5_3": {
			"recommended": ["flying.rocket", "heavy.saw"],
			"fallback": ["ordinary.sonic"],
			"reason": "输出校验升高，火箭打结构，双锯处理精英护盾。",
		},
		"stage_5_4": {
			"recommended": ["special.repair", "flying.rocket", "heavy.saw"],
			"fallback": ["special.parasite"],
			"reason": "幕末精英压力关需要续航、破结构和反精英齐备。",
		},
		"stage_5_5": {
			"recommended": ["special.repair", "flying.rocket", "heavy.saw", "heavy.armored"],
			"fallback": ["special.parasite"],
			"reason": "最终基地比拼输出速度，同时要求抗炮击、破甲、续航和反精英。",
		},
	}
	var data := recommendations.get(stage_id, {
		"recommended": ["ordinary.assault", "ordinary.sonic"],
		"fallback": [],
		"reason": "默认使用初始推进与削弱组合，保证关卡提示不会为空。",
	}) as Dictionary
	return {
		"recommended_recipe_ids": (data.get("recommended", []) as Array).duplicate(),
		"fallback_recipe_ids": (data.get("fallback", []) as Array).duplicate(),
		"recommendation_reason": String(data.get("reason", "")),
	}


static func _readability_fields(stage_id: String, chapter: int, stage_in_chapter: int, unlock_victory: Array[String]) -> Dictionary:
	var is_boss := stage_in_chapter == 5
	var chapter_threats: Dictionary = {
		1: "Cameramen 用路障、标记射击和炮塔压住城市大道。",
		2: "Speakermen 用声波冲锋和能量干扰拖慢技能节奏。",
		3: "TV Men 用烟幕、传送和屏幕控制打乱稳定输出。",
		4: "三族联合部队开始同时反飞行、反寄生并保护装甲结构。",
		5: "中央基地用持续炮火和诱导撤退路线检验第一幕完整阵容。",
	}
	var chapter_counters: Dictionary = {
		1: "用装甲单位承压，冲锋和火箭处理路障与炮塔。",
		2: "提前存技能，用音波、自爆和维修撑过声波高峰。",
		3: "保留控制与召唤技能，优先打断 TV 护盾和传送节奏。",
		4: "不要纯飞行或纯寄生，改用装甲、双锯、火箭和维修混编。",
		5: "保持一到两名三星核心，手动或自动技能都要围绕炮击窗口爆发。",
	}
	var beat_threats: Dictionary = {
		1: "普通推进关，重点是读懂本章敌人的基础攻击方式。",
		2: "侧翼压力增加，后排会更早承受远程或机动单位干扰。",
		3: "中段门槛关，敌方机制会暴露单一阵容的短板。",
		4: "精英压力关，持续炮击和精英守军会惩罚无恢复阵容。",
		5: "章节 Boss 关，基地结构分层破坏并持续轰炸全场。",
	}
	var beat_counters: Dictionary = {
		1: "保持六人满编，观察谁先倒下，再回厂补同职责角色。",
		2: "调整前后排，让承伤角色吃第一轮火力，后排保留输出。",
		3: "使用本章新解法或上一章反制单位，不要只看总战力。",
		4: "失败后优先升星承压或恢复位，而不是只堆最高攻击。",
		5: "先拆外围模块降低炮击压力，再在核心暴露时集中技能。",
	}
	var chapter_feedback: Dictionary = {
		1: "灰镜街区让玩家确认：工厂生产和升星能直接改变攻城结果。",
		2: "震荡封锁线提醒玩家：技能节奏、范围爆发和维修同样重要。",
		3: "黑屏城区强调反控制与特殊单位价值，战斗不再只是正面推血条。",
		4: "三军联合防线要求玩家根据敌方模块换阵，单一套路开始失效。",
		5: "伪胜之城制造战术胜利与战略陷阱的反差，为幕末工厂被毁做铺垫。",
	}
	var unlock_preview := ""
	if not unlock_victory.is_empty():
		unlock_preview = "胜利后预览新蓝图：%s。" % _recipe_labels(unlock_victory)
	elif stage_id == DEFAULT_STAGE_ID:
		unlock_preview = "失败或超时后预览反攻蓝图：火箭飞行马桶人、装甲冲城马桶人。"
	var threat := "%s %s" % [String(chapter_threats[chapter]), String(beat_threats[stage_in_chapter])]
	var counter := "%s %s" % [String(chapter_counters[chapter]), String(beat_counters[stage_in_chapter])]
	if is_boss:
		threat = "%s 本关是章节 Boss，最终结构会分段受损并逼玩家与基地比拼输出速度。" % String(chapter_threats[chapter])
		counter = "%s Boss 战优先处理电池和护甲层，核心暴露后再集中释放攻城技能。" % String(chapter_counters[chapter])
	return {
		"threat_summary": threat,
		"counter_hint": counter,
		"chapter_feedback": String(chapter_feedback[chapter]),
		"unlock_preview": unlock_preview,
	}


static func _recipe_labels(recipe_ids: Array[String]) -> String:
	var labels: Dictionary = {
		"heavy.armored": "装甲冲城马桶人",
		"flying.rocket": "火箭飞行马桶人",
		"flying.bomber": "自爆飞行马桶人",
		"special.repair": "维修马桶人",
		"special.parasite": "寄生母体马桶人",
		"heavy.saw": "双锯重装马桶人",
	}
	var values: Array[String] = []
	for recipe_id in recipe_ids:
		values.append(String(labels.get(recipe_id, recipe_id)))
	return "、".join(values)


static func _enemy_template_for(chapter: int, stage_in_chapter: int) -> Array[Dictionary]:
	var families: Array[String] = ["camera", "speaker", "tv", "alliance", "alliance"]
	var family: String = families[chapter - 1]
	var base_label: String = String({
		"camera": "联盟摄像兵",
		"speaker": "联盟音箱兵",
		"tv": "电视特工",
		"alliance": "联盟联合兵",
	}.get(family, "联盟守军"))
	var elite_label: String = String({
		"camera": "摄像盾卫",
		"speaker": "大型音箱兵",
		"tv": "电视监军",
		"alliance": "联合核心近卫",
	}.get(family, "联盟精英"))
	var ranged_class: String = "ranger" if family == "camera" else ("arcanist" if family in ["speaker", "tv"] else "guardian")
	var values: Array[Dictionary] = [
		_enemy("%s_grunt_l" % family, base_label, "fighter", 0, 220, 0, 105, 20, 6, 34, 8, false),
		_enemy("%s_grunt_c" % family, base_label, "fighter", 0, 245, 1, 115, 22, 7, 34, 8, false),
		_enemy("%s_support_r" % family, base_label, ranged_class, 0, 272, 2, 98, 22, 5, 94, 9, false),
		_enemy("%s_elite_mid" % family, elite_label, "guardian", 1, 505, 1, 190, 29, 12, 38, 8, true),
	]
	if stage_in_chapter >= 2:
		values.append(_enemy("%s_flank_l" % family, base_label, ranged_class, 1, 480, 0, 120, 25, 7, 108, 7, false))
	if stage_in_chapter >= 3:
		values.append(_enemy("%s_flank_r" % family, base_label, ranged_class, 1, 520, 2, 125, 25, 7, 108, 7, false))
	if stage_in_chapter >= 4:
		values.append(_enemy("%s_elite_base" % family, elite_label, "arcanist", 2, 805, 1, 240, 34, 11, 96, 8, true))
	values.append(_enemy("%s_core_guard_l" % family, "核心近卫", "guardian", 2, 840, 0, 190, 29, 13, 38, 7, true))
	values.append(_enemy("%s_core_guard_r" % family, "核心近卫", "guardian", 2, 840, 2, 190, 29, 13, 38, 7, true))
	return values


static func _structure_template_for(chapter: int, stage_in_chapter: int) -> Array[Dictionary]:
	var boss_core_names := {
		1: "灰镜核心巨炮",
		2: "共振堡垒核心",
		3: "黑屏中继塔",
		4: "三联军械库核心",
		5: "审判之门",
	}
	var core_name := String(boss_core_names.get(chapter, "联盟核心"))
	var values: Array[Dictionary] = [
		_structure("outer_barricade", "外围路障", "structure", 0, 300, 1, 220, 10, 0, 0),
		_structure("fire_tower", "火力塔", "turret", 1, 560, 0, 330, 11, 16, 8),
		_structure("armored_gate", "装甲大门", "armored", 1, 640, 1, 520, 16, 0, 0),
	]
	if stage_in_chapter >= 5:
		values.append(_structure("left_battery", "左防御设施", "battery", 2, 815, 0, 420, 13, 22, 9))
		values.append(_structure("right_battery", "右防御设施", "battery", 2, 815, 2, 420, 13, 22, 9))
		values.append(_structure("core_armor", "核心外层装甲", "armored", 2, 900, 1, 610, 20, 0, 0))
		values.append(_structure("alliance_core", core_name, "core", 2, 1000, 1, 850, 16, 0, 0))
	else:
		values.append(_structure("left_battery", "左防御设施", "battery", 2, 815, 0, 300, 12, 17, 10))
		values.append(_structure("alliance_core", "联盟据点核心", "core", 2, 1000, 1, 580, 14, 0, 0))
	return values


static func _scaled_enemies(enemies: Array[Dictionary], power_bp: int) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for enemy_data in enemies:
		var enemy := enemy_data.duplicate(true)
		enemy["hp"] = int(int(enemy["hp"]) * power_bp / 10000)
		enemy["attack"] = int(int(enemy["attack"]) * power_bp / 10000)
		enemy["defense"] = int(int(enemy["defense"]) * power_bp / 10000)
		enemy["max_hp"] = enemy["hp"]
		values.append(enemy)
	return values


static func _scaled_structures(structures: Array[Dictionary], power_bp: int) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for structure_data in structures:
		var structure := structure_data.duplicate(true)
		structure["max_hp"] = int(int(structure["max_hp"]) * power_bp / 10000)
		structure["hp"] = structure["max_hp"]
		structure["defense"] = int(int(structure["defense"]) * power_bp / 10000)
		structure["attack"] = int(int(structure["attack"]) * power_bp / 10000)
		values.append(structure)
	return values


static func _legacy_stage_1_1_enemies() -> Array[Dictionary]:
	return [
		_enemy("cam_grunt_l", "联盟摄像兵", "fighter", 0, 230, 0, 115, 22, 7, 32, 8, false),
		_enemy("cam_grunt_c", "联盟摄像兵", "fighter", 0, 250, 1, 125, 23, 7, 32, 8, false),
		_enemy("camera_marksman", "摄像狙击手", "ranger", 0, 270, 2, 105, 24, 5, 90, 9, false),
		_enemy("shield_captain", "盾阵队长", "guardian", 1, 505, 1, 230, 32, 14, 36, 8, true),
		_enemy("turret_guard_l", "火力守军", "ranger", 1, 480, 0, 145, 29, 8, 110, 7, false),
		_enemy("turret_guard_r", "火力守军", "ranger", 1, 520, 2, 145, 29, 8, 110, 7, false),
		_enemy("camera_heavy_guard", "大型摄像守卫", "guardian", 2, 805, 1, 285, 36, 12, 100, 8, true),
		_enemy("core_guard_l", "核心近卫", "guardian", 2, 840, 0, 220, 31, 14, 38, 7, true),
		_enemy("core_guard_r", "核心近卫", "guardian", 2, 840, 2, 220, 31, 14, 38, 7, true),
	]


static func _legacy_stage_1_1_structures() -> Array[Dictionary]:
	return [
		_structure("outer_barricade", "外围路障", "structure", 0, 300, 1, 260, 11, 0, 0),
		_structure("fire_tower", "火力塔", "turret", 1, 560, 0, 440, 12, 18, 8),
		_structure("armored_gate", "装甲大门", "armored", 1, 640, 1, 700, 18, 0, 0),
		_structure("left_battery", "左防御设施", "battery", 2, 815, 0, 450, 13, 23, 9),
		_structure("right_battery", "右防御设施", "battery", 2, 815, 2, 450, 13, 23, 9),
		_structure("core_armor", "核心外层装甲", "armored", 2, 900, 1, 650, 20, 0, 0),
		_structure("alliance_core", "灰镜核心巨炮", "core", 2, 1000, 1, 900, 16, 0, 0),
	]


static func _enemy(id: String, label: String, class_id: String, stage_index: int, road_position: int, lane: int, hp: int, attack: int, defense: int, attack_range: int, period: int, elite: bool) -> Dictionary:
	return {
		"unit_id": id,
		"display_name": label,
		"class_id": class_id,
		"stage": stage_index,
		"road_position": road_position,
		"lane": lane,
		"hp": hp,
		"attack": attack,
		"defense": defense,
		"range": attack_range,
		"attack_period_ticks": period,
		"elite": elite,
	}


static func _structure(id: String, label: String, kind: String, stage_index: int, road_position: int, lane: int, max_hp: int, defense: int, attack: int, attack_period_ticks: int) -> Dictionary:
	return {
		"structure_id": id,
		"display_name": label,
		"kind": kind,
		"stage": stage_index,
		"road_position": road_position,
		"lane": lane,
		"max_hp": max_hp,
		"defense": defense,
		"attack": attack,
		"attack_period_ticks": attack_period_ticks,
	}
