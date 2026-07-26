class_name StageCatalog
extends RefCounted

const StageDefinitionCatalogScript := preload("res://game/scripts/content/stage_definition_catalog.gd")

const ACT1_STAGE_IDS: Array[String] = [
	"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
	"stage_2_1", "stage_2_2", "stage_2_3", "stage_2_4", "stage_2_5",
	"stage_3_1", "stage_3_2", "stage_3_3", "stage_3_4", "stage_3_5",
	"stage_4_1", "stage_4_2", "stage_4_3", "stage_4_4", "stage_4_5",
	"stage_5_1", "stage_5_2", "stage_5_3", "stage_5_4", "stage_5_5",
]

const DEFAULT_STAGE_ID: String = "stage_1_1"
const ENDLESS_PREFIX: String = "endless_"
const DEFAULT_STAGE_NAMES: Array[String] = ["城市外围", "火力封锁区", "基地广场"]
const RECOMMENDED_POWER: Array[int] = [
	1950, 2000, 2020, 5700, 6500,
	15500, 16500, 17500, 18500, 19500,
	20000, 20500, 21000, 21500, 22000,
	22500, 23000, 23500, 24000, 24500,
	25000, 25500, 26000, 26250, 26500,
]
const ENEMY_POWER_BP: Array[int] = [
	6200, 7200, 8400, 9000, 10750,
	20000, 26000, 27500, 29000, 30000,
	31500, 32500, 33500, 34250, 35000,
	35250, 35500, 35750, 36000, 36500,
	36800, 37100, 37400, 37700, 38000,
]


static func all_stage_ids() -> Array[String]:
	return ACT1_STAGE_IDS.duplicate()


static func has_stage(stage_id: String) -> bool:
	return ACT1_STAGE_IDS.has(stage_id) or _endless_index(stage_id) > 0


static func stage(stage_id: String = DEFAULT_STAGE_ID) -> Dictionary:
	if not has_stage(stage_id):
		return {}
	if _endless_index(stage_id) > 0:
		return _endless_stage(_endless_index(stage_id))
	var index := ACT1_STAGE_IDS.find(stage_id)
	var chapter := int(index / 5) + 1
	var stage_in_chapter := int(index % 5) + 1
	var authored_definition: Resource = StageDefinitionCatalogScript.definition(stage_id)
	var power_bp := int(authored_definition.enemy_power_bp) if authored_definition != null else ENEMY_POWER_BP[index]
	var config := _base_stage(stage_id, chapter, stage_in_chapter, power_bp)
	if stage_id == DEFAULT_STAGE_ID:
		# 第一关是纯粹的破坏教学：没有联盟守军或炮台，
		# 先撞开废弃路障，再摧毁唯一城市目标。
		config["display_name"] = "1-1 无防备城市"
		config["stage_names"] = ["城市外围"]
		config["final_structure_id"] = "unguarded_city"
		config["enemies"] = []
		config["structures"] = [
			_structure("abandoned_barricade", "废弃路障", "structure", 0, 430, 1, 180, 1, 0, 0),
			_structure("unguarded_city", "无防备城市", "city", 0, 620, 1, 760, 4, 0, 0),
		]
		config["threat_summary"] = "城市没有组织防守；先撞开废弃路障，再摧毁城市目标。"
		config["counter_hint"] = "让 Gman 自动推进，能量充满后点击头像快速突破路障。"
		config["reward_victory"] = {"gold": 80, "xp_books": 0, "porcelain": 24, "parts": 16, "sludge": 12}
		config["reward_defeat"] = {"gold": 12, "xp_books": 2, "porcelain": 8, "parts": 5, "sludge": 4}
		config["unlock_on_defeat"] = []
		config["unlock_on_victory"] = []
		config["unlock_preview"] = ""
		return _apply_authored_definition(config, authored_definition)
	if stage_id == "stage_1_2":
		# 第二关只引入城市内的第一批远程联盟成员，还没有固定火力。
		config["display_name"] = "1-2 城市警报"
		config["solo_pressure_bp"] = 10000
		config["stage_names"] = ["警报街区"]
		config["final_structure_id"] = "alerted_city"
		config["enemies"] = _scaled_enemies([
			_enemy("militia_l", "远程摄像警卫", "ranger", 0, 420, 0, 90, 15, 3, 160, 9, false),
			_enemy("militia_r", "远程摄像警卫", "ranger", 0, 460, 2, 90, 15, 3, 160, 9, false),
		], power_bp)
		config["structures"] = _scaled_structures([
			_structure("alerted_city", "警报中的城市", "city", 0, 720, 1, 820, 5, 0, 0),
		], power_bp)
		return _apply_authored_definition(config, authored_definition)
	if stage_id == "stage_1_3":
		# 第三关让零散守卫正式组成联盟，并部署一座低压预警炮塔；
		# Gman 可以残血突破，第 4 关才升级为必败的重炮墙。
		config["display_name"] = "1-3 联盟集结"
		config["solo_pressure_bp"] = 13000
		config["stage_names"] = ["联盟街垒", "城市议事厅"]
		config["final_structure_id"] = "alliance_hall"
		config["enemies"] = _scaled_enemies([
			_enemy("alliance_grunt_l", "联盟摄像兵", "ranger", 0, 280, 0, 105, 18, 4, 120, 9, false),
			_enemy("alliance_grunt_c", "联盟摄像兵", "ranger", 0, 310, 1, 115, 19, 5, 120, 9, false),
			_enemy("alliance_grunt_r", "联盟摄像兵", "ranger", 0, 340, 2, 105, 18, 4, 120, 9, false),
			_enemy("alliance_captain", "联盟临时队长", "guardian", 1, 530, 1, 175, 23, 9, 110, 9, true),
		], power_bp)
		config["structures"] = _scaled_structures([
			_structure("alliance_barricade", "联盟街垒", "structure", 0, 420, 1, 200, 7, 0, 0),
			_structure("warning_turret", "警戒轻炮塔", "turret", 1, 580, 1, 160, 6, 17, 8),
			_structure("alliance_hall", "联盟议事厅", "city", 1, 700, 1, 430, 7, 0, 0),
		], power_bp)
		return _apply_authored_definition(config, authored_definition)
	config["enemies"] = _scaled_enemies(_enemy_template_for(chapter, stage_in_chapter), power_bp)
	config["structures"] = _scaled_structures(_structure_template_for(chapter, stage_in_chapter), power_bp)
	return _apply_authored_definition(config, authored_definition)


static func _apply_authored_definition(config: Dictionary, definition: Resource) -> Dictionary:
	if definition == null:
		config["enemy_power_bp"] = int(config.get("enemy_power_bp", 10000))
		config["structure_hp_bp"] = int(config.get("structure_hp_bp", 10000))
		return config
	config["display_name"] = String(definition.display_name)
	config["recommended_power"] = int(definition.recommended_power)
	config["minimum_power"] = int(int(definition.recommended_power) * 85 / 100)
	config["enemy_power_bp"] = int(definition.enemy_power_bp)
	config["solo_pressure_bp"] = int(definition.solo_pressure_bp)
	config["structure_hp_bp"] = int(definition.structure_hp_bp)
	config["threat_summary"] = String(definition.threat_summary)
	config["counter_hint"] = String(definition.counter_hint)
	if int(definition.structure_hp_bp) != 10000:
		for structure in config.get("structures", []):
			structure["max_hp"] = maxi(
				1,
				int(int(structure["max_hp"]) * int(definition.structure_hp_bp) / 10000)
			)
			structure["hp"] = int(structure["max_hp"])
	return config


static func reward_for(stage_id: String, outcome: String) -> Dictionary:
	var config := stage(stage_id)
	if config.is_empty():
		return {}
	var key := "reward_%s" % outcome
	return (config.get(key, config.get("reward_defeat", {})) as Dictionary).duplicate(true)


static func reward_for_context(
	stage_id: String,
	outcome: String,
	prior_attempts: int,
	already_cleared: bool
) -> Dictionary:
	var base := reward_for(stage_id, outcome)
	if base.is_empty():
		return {}
	if outcome == "defeat" and prior_attempts > 0:
		return {"gold": 0, "xp_books": 0, "porcelain": 0, "parts": 0, "sludge": 0}
	if outcome == "victory" and already_cleared:
		return _scaled_repeat_reward(base)
	return base


static func reward_tier(outcome: String, prior_attempts: int, already_cleared: bool) -> String:
	if outcome == "defeat" and prior_attempts > 0:
		return "repeat_defeat"
	if outcome == "victory" and already_cleared:
		return "repeat_victory"
	return "first_victory" if outcome == "victory" else "first_defeat"


static func next_stage_id(stage_id: String) -> String:
	var config := stage(stage_id)
	return String(config.get("next_stage_id", ""))


static func breakthrough_reward(stage_id: String, already_cleared: bool) -> Dictionary:
	if already_cleared or not ACT1_STAGE_IDS.has(stage_id):
		return {"hero_shards": 0, "skill_chips": 0}
	var index := ACT1_STAGE_IDS.find(stage_id)
	var stage_in_chapter := int(index % 5) + 1
	if stage_id == "stage_1_2":
		return {"hero_shards": 4, "skill_chips": 0}
	if stage_in_chapter == 3:
		return {"hero_shards": 4, "skill_chips": 0}
	if stage_in_chapter == 5:
		return {"hero_shards": 8, "skill_chips": 2}
	return {"hero_shards": 0, "skill_chips": 0}


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
	var recommended_power := RECOMMENDED_POWER[index]
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
	var next_id := ACT1_STAGE_IDS[index + 1] if index >= 0 and index + 1 < ACT1_STAGE_IDS.size() else "endless_1"
	var is_boss := stage_in_chapter == 5
	var unlock_victory: Array[String] = []
	var readability := _readability_fields(stage_id, chapter, stage_in_chapter, unlock_victory)
	var recommendation := _recommendation_fields(stage_id)
	return {
		"stage_id": stage_id,
		"act": 1,
		"chapter": chapter,
		"stage_in_chapter": stage_in_chapter,
		"display_name": "%d-%d %s" % [chapter, stage_in_chapter, boss_names.get(chapter, "联盟基地") if is_boss else chapter_names.get(chapter, "城市大道")],
		"stage_names": DEFAULT_STAGE_NAMES.duplicate(),
		"final_structure_id": "alliance_core",
		"suppressible_cannon": is_boss,
		"cannon_suppression_target": _cannon_suppression_target(chapter) if is_boss else 0,
		"cannon_warning_ticks": 20 if is_boss else 0,
		"next_stage_id": next_id,
		"reward_victory": {
			"gold": 35 + chapter * 8 + stage_in_chapter * 3,
			"xp_books": 1 if is_boss else 0,
			"porcelain": 14 + chapter * 3 + stage_in_chapter * 2,
			"parts": 10 + chapter * 3 + stage_in_chapter * 2,
			"sludge": 8 + chapter * 3 + stage_in_chapter * 2,
		},
		"reward_defeat": {
			"gold": 0,
			"xp_books": 0,
			"porcelain": 0,
			"parts": 0,
			"sludge": 0,
		},
		"unlock_on_defeat": [],
		"unlock_on_victory": unlock_victory,
		"unlock_preview": "",
		"threat_summary": readability["threat_summary"],
		"counter_hint": readability["counter_hint"],
		"chapter_feedback": readability["chapter_feedback"],
		"recommended_recipe_ids": recommendation["recommended_recipe_ids"],
		"fallback_recipe_ids": recommendation["fallback_recipe_ids"],
		"recommendation_reason": recommendation["recommendation_reason"],
		"factory_production_target": 0,
		"defense_evolution": _defense_evolution(stage_id, chapter, stage_in_chapter),
		"power_bp": power_bp,
		"minimum_power": int(recommended_power * 85 / 100),
		"recommended_power": recommended_power,
	}


static func _endless_index(stage_id: String) -> int:
	if not stage_id.begins_with(ENDLESS_PREFIX):
		return 0
	var suffix := stage_id.trim_prefix(ENDLESS_PREFIX)
	if not suffix.is_valid_int():
		return 0
	return maxi(0, int(suffix))


static func _endless_stage(index: int) -> Dictionary:
	var power_bp := 38000 + index * 850
	var config := _base_stage("stage_5_4", 5, 4, power_bp)
	config["stage_id"] = "%s%d" % [ENDLESS_PREFIX, index]
	config["act"] = 2
	config["chapter"] = 6
	config["stage_in_chapter"] = index
	config["display_name"] = "无尽前线 %d" % index
	config["next_stage_id"] = "%s%d" % [ENDLESS_PREFIX, index + 1]
	config["recommended_power"] = 26500 + index * 700
	config["minimum_power"] = int(config["recommended_power"] * 85 / 100)
	config["power_bp"] = power_bp
	config["reward_victory"] = {
		"gold": 78 + index * 3,
		"xp_books": 0,
		"porcelain": 30 + index,
		"parts": 27 + index,
		"sludge": 24 + index,
	}
	config["reward_defeat"] = {"gold": 0, "xp_books": 0, "porcelain": 0, "parts": 0, "sludge": 0}
	config["unlock_on_defeat"] = []
	config["unlock_on_victory"] = []
	config["unlock_preview"] = ""
	config["threat_summary"] = "无尽前线会逐层提高敌军生命、攻击和推荐战力。"
	config["counter_hint"] = "根据实际阵亡与材料储备决定继续推进或主动撤退止损。"
	return config


static func _scaled_repeat_reward(base: Dictionary) -> Dictionary:
	return {
		"gold": int(int(base.get("gold", 0)) * 30 / 100),
		"xp_books": 0,
		"porcelain": int(int(base.get("porcelain", 0)) * 30 / 100),
		"parts": int(int(base.get("parts", 0)) * 30 / 100),
		"sludge": int(int(base.get("sludge", 0)) * 30 / 100),
	}


static func _defense_evolution(stage_id: String, chapter: int, stage_in_chapter: int) -> Dictionary:
	var opening_beats: Dictionary = {
		"stage_1_1": {
			"tier": "unguarded_city",
			"title": "无防备城市",
			"description": "没有联盟、守军或炮台，Gman 摧毁唯一的城市目标即可。",
			"features": ["单一城市目标", "零防守"],
		},
		"stage_1_2": {
			"tier": "city_alarm",
			"title": "城市警戒",
			"description": "警报响起，路障和临时守卫开始拖慢推进。",
			"features": ["警戒路障", "临时守卫"],
		},
		"stage_1_3": {
			"tier": "alliance_militia",
			"title": "联盟成立",
			"description": "城市守军组成联盟，第一次形成有组织的交叉火力。",
			"features": ["联盟士兵", "防守据点"],
		},
		"stage_1_4": {
			"tier": "turret_line",
			"title": "炮台防线",
			"description": "联盟部署固定炮台和精英守军，单靠 Gman 无法继续碾压。",
			"features": ["固定炮台", "精英守军", "交叉火力"],
		},
	}
	if opening_beats.has(stage_id):
		return (opening_beats[stage_id] as Dictionary).duplicate(true)
	return {
		"tier": "chapter_%d_beat_%d" % [chapter, stage_in_chapter],
		"title": "联合防守" if chapter >= 4 else "升级防线",
		"description": "敌方持续叠加守军、设施和章节机制。",
		"features": ["联盟守军", "防御设施", "章节机制"],
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
			"recommended": [],
			"fallback": [],
			"reason": "第一关不需要生产任何小兵，Gman 独自摧毁无防备城市。",
		},
		"stage_1_2": {
			"recommended": [],
			"fallback": ["heavy.armored", "flying.rocket"],
			"reason": "城市只有少量临时联盟守卫，继续由 Gman 独自推进。",
		},
		"stage_1_3": {
			"recommended": [],
			"fallback": ["heavy.armored"],
			"reason": "联盟刚刚形成，尚未部署炮台；Gman 仍能完成最后一次单人推进。",
		},
		"stage_1_4": {
			"recommended": [],
			"fallback": ["ordinary.assault"],
			"reason": "炮台防线是设计好的首次失败点；失败后研究图纸、生产九兵并完成第一次三合一。",
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
		1: "保持 Gman 与六名小兵满编，观察谁先倒下，再回厂补同职责角色。",
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
	var threat := "%s %s" % [String(chapter_threats[chapter]), String(beat_threats[stage_in_chapter])]
	var counter := "%s %s" % [String(chapter_counters[chapter]), String(beat_counters[stage_in_chapter])]
	var opening_readability: Dictionary = {
		"stage_1_1": {
			"threat": "城市尚未形成任何有效抵抗，场上只有城市本体。",
			"counter": "让 Gman 独自推进并熟悉自动攻击与技能。",
		},
		"stage_1_2": {
			"threat": "城市拉响警报，临时路障和警卫开始拖慢 Gman。",
			"counter": "继续依靠 Gman 的压制力，不需要提前生产小兵。",
		},
		"stage_1_3": {
			"threat": "城市联盟成立，守军第一次组织交叉火力。",
			"counter": "Gman 仍能独自突破；观察联盟如何为下一关架设防线。",
		},
		"stage_1_4": {
			"threat": "联盟部署固定炮台、精英守军与交叉火力，形成首次必败墙。",
			"counter": "失败后带回冲锋马桶人设计图，交给博士研究并生产 9 个援军。",
		},
	}
	if opening_readability.has(stage_id):
		var opening := opening_readability[stage_id] as Dictionary
		threat = String(opening["threat"])
		counter = String(opening["counter"])
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
