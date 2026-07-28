class_name StageCatalog
extends RefCounted

const StageDefinitionCatalogScript := preload("res://game/scripts/content/stage_definition_catalog.gd")

const CHAPTER_COUNT: int = 5
const STAGES_PER_CHAPTER: int = 12
const ELITE_STAGE_NUMBERS: Array[int] = [3, 6, 9]
const BOSS_STAGE_NUMBER: int = 12
const ACT1_STAGE_IDS: Array[String] = [
	"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5", "stage_1_6",
	"stage_1_7", "stage_1_8", "stage_1_9", "stage_1_10", "stage_1_11", "stage_1_12",
	"stage_2_1", "stage_2_2", "stage_2_3", "stage_2_4", "stage_2_5", "stage_2_6",
	"stage_2_7", "stage_2_8", "stage_2_9", "stage_2_10", "stage_2_11", "stage_2_12",
	"stage_3_1", "stage_3_2", "stage_3_3", "stage_3_4", "stage_3_5", "stage_3_6",
	"stage_3_7", "stage_3_8", "stage_3_9", "stage_3_10", "stage_3_11", "stage_3_12",
	"stage_4_1", "stage_4_2", "stage_4_3", "stage_4_4", "stage_4_5", "stage_4_6",
	"stage_4_7", "stage_4_8", "stage_4_9", "stage_4_10", "stage_4_11", "stage_4_12",
	"stage_5_1", "stage_5_2", "stage_5_3", "stage_5_4", "stage_5_5", "stage_5_6",
	"stage_5_7", "stage_5_8", "stage_5_9", "stage_5_10", "stage_5_11", "stage_5_12",
]

const DEFAULT_STAGE_ID: String = "stage_1_1"
const ENDLESS_PREFIX: String = "endless_"
const DEFAULT_STAGE_NAMES: Array[String] = ["城市外围", "火力封锁区", "基地广场"]
const ACT1_DISPLAY_NAMES: Dictionary = {
	"stage_2_1": "低音街垒",
	"stage_2_2": "震荡高架",
	"stage_2_3": "广播车队",
	"stage_2_4": "双塔回响",
	"stage_2_5": "共振堡垒",
	"stage_3_1": "信号消失",
	"stage_3_2": "烟幕换位",
	"stage_3_3": "镜片工厂",
	"stage_3_4": "处决画面",
	"stage_3_5": "黑屏中继塔",
	"stage_4_1": "联合标记",
	"stage_4_2": "禁飞走廊",
	"stage_4_3": "反寄生实验区",
	"stage_4_4": "轮换防线",
	"stage_4_5": "三联军械库",
	"stage_5_1": "空城大道",
	"stage_5_2": "战略仓库",
	"stage_5_3": "泰坦足迹",
	"stage_5_4": "中央防区",
	"stage_5_5": "审判之门",
}
const CHAPTER_STAGE_NAMES: Dictionary = {
	1: [
		"无防备城市", "城市警报", "联盟集结", "炮台防线", "灰镜核心",
		"摄像重装营", "失焦街区", "黑屏预警", "电视人闪袭",
		"镜片仓库", "泰坦足迹", "抵抗军总台",
	],
	2: [
		"低音街垒", "震荡高架", "广播车队", "回声隧道", "共振前哨",
		"巨型音箱阵", "寄生样本库", "失控广播站", "感染泰坦投影",
		"静音走廊", "解毒车队", "共振堡垒",
	],
	3: [
		"信号消失", "烟幕换位", "镜片工厂", "处决画面", "黑屏中继",
		"电视监军", "传送残影", "控制矩阵", "夺控实验室",
		"暗屏走廊", "泰坦回归", "黑屏母塔",
	],
	4: [
		"联合标记", "禁飞走廊", "反寄生区", "轮换防线", "三军前哨",
		"联合近卫", "装甲列车", "模块工坊", "协议封锁",
		"渗透入口", "实验室外环", "三联军械库",
	],
	5: [
		"空城大道", "战略仓库", "泰坦足迹", "中央防区", "审判前门",
		"科学家机甲", "诱敌回廊", "连续炮阵", "指挥干扰核心",
		"实验室深层", "G军团决战", "审判之门",
	],
}
const CHAPTER_POWER_START: Array[int] = [1950, 9400, 13000, 17200, 22500]
const CHAPTER_POWER_END: Array[int] = [9000, 12500, 16500, 21500, 28000]
const CHAPTER_ENEMY_BP_START: Array[int] = [6200, 18000, 27000, 35000, 43000]
const CHAPTER_ENEMY_BP_END: Array[int] = [15200, 26000, 34000, 42000, 52000]
const LEGACY_RECOMMENDED_POWER: Array[int] = [
	1950, 2000, 2020, 5700, 6500,
	6900, 7300, 7700, 8100, 9000,
	9400, 9800, 10200, 10600, 11500,
	11900, 12300, 12700, 13100, 14000,
	14400, 14800, 15200, 15600, 16500,
]
const LEGACY_ENEMY_POWER_BP: Array[int] = [
	6200, 7200, 8400, 9000, 10750,
	11200, 11600, 12000, 16000, 18000,
	20200, 23000, 22000, 22000, 27000,
	28500, 29500, 30500, 31500, 33500,
	35000, 36000, 37000, 38000, 40000,
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
	var chapter := int(index / STAGES_PER_CHAPTER) + 1
	var stage_in_chapter := int(index % STAGES_PER_CHAPTER) + 1
	# The accepted first 30 minutes remain intact through the original 1-5
	# mid-boss; the new campaign depth begins at 1-6.
	var authored_definition: Resource = (
		StageDefinitionCatalogScript.definition(stage_id)
		if chapter == 1 and stage_in_chapter <= 5
		else null
	)
	var power_bp := _enemy_power_bp(chapter, stage_in_chapter)
	var config := _base_stage(stage_id, chapter, stage_in_chapter, power_bp)
	if stage_id == DEFAULT_STAGE_ID:
		# 第一关是纯粹的破坏教学：没有联盟守军或炮台，
		# 先撞开废弃路障，再摧毁唯一城市目标。
		config["display_name"] = "1-1 无防备城市"
		config["stage_names"] = ["城市外围"]
		config["final_structure_id"] = "unguarded_city"
		config["gman_opening_damage_bp"] = 30000
		config["enemies"] = []
		config["structures"] = [
			_structure("abandoned_barricade", "废弃路障", "structure", 0, 430, 1, 180, 1, 0, 0),
			_structure("unguarded_city", "无防备城市", "city", 0, 620, 1, 760, 4, 0, 0),
		]
		config["threat_summary"] = "城市没有组织防守；先撞开废弃路障，再摧毁城市目标。"
		config["counter_hint"] = "让 Gman 自动推进，能量充满后点击头像快速突破路障。"
		config["reward_victory"] = {"gold": 80}
		config["reward_defeat"] = {"gold": 0}
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
		config["enemies"] = _fixed_enemies([
			_enemy("militia_l", "远程摄像警卫", "ranger", 0, 420, 0, 65, 11, 2, 160, 9, false, "camera_sentry"),
			_enemy("militia_r", "远程摄像警卫", "ranger", 0, 460, 2, 65, 11, 2, 160, 9, false, "camera_sentry"),
		])
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
		config["enemies"] = _fixed_enemies([
			_enemy("alliance_grunt_l", "联盟摄像兵", "ranger", 0, 280, 0, 88, 16, 3, 120, 9, false, "camera_trooper"),
			_enemy("alliance_grunt_c", "联盟摄像兵", "ranger", 0, 310, 1, 88, 16, 3, 120, 9, false, "camera_trooper"),
			_enemy("alliance_grunt_r", "联盟摄像兵", "ranger", 0, 340, 2, 88, 16, 3, 120, 9, false, "camera_trooper"),
			_enemy("alliance_captain", "联盟临时队长", "guardian", 1, 530, 1, 147, 19, 7, 110, 9, true, "camera_field_captain"),
		])
		config["structures"] = _scaled_structures([
			_structure("alliance_barricade", "联盟街垒", "structure", 0, 420, 1, 200, 7, 0, 0),
			_structure("warning_turret", "警戒轻炮塔", "turret", 1, 580, 1, 160, 6, 17, 8),
			_structure("alliance_hall", "联盟议事厅", "city", 1, 700, 1, 430, 7, 0, 0),
		], power_bp)
		return _apply_authored_definition(config, authored_definition)
	var enemy_template := _enemy_template_for(chapter, stage_in_chapter)
	config["enemies"] = _fixed_enemies(enemy_template) if chapter == 1 else _scaled_enemies(enemy_template, power_bp)
	config["structures"] = _scaled_structures(_structure_template_for(chapter, stage_in_chapter), power_bp)
	config = _apply_authored_definition(config, authored_definition)
	if stage_id in ["stage_1_5", "stage_1_12"]:
		_shape_chapter_one_boss(config)
	elif stage_id == "stage_2_9":
		_shape_chapter_two_gate(config)
	elif stage_in_chapter in [5, BOSS_STAGE_NUMBER] and chapter >= 2:
		_shape_boss_finale(config)
	return config


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
		return {"gold": 0}
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
		return {"hero_shards": 0}
	var index := ACT1_STAGE_IDS.find(stage_id)
	var stage_in_chapter := int(index % STAGES_PER_CHAPTER) + 1
	if stage_id == "stage_1_2":
		return {"hero_shards": 4}
	if ELITE_STAGE_NUMBERS.has(stage_in_chapter):
		return {"hero_shards": 4}
	if stage_in_chapter in [5, BOSS_STAGE_NUMBER]:
		# 旧 8 数据 + 2 芯片，按 1 芯片 = 4 军团数据合并。
		return {"hero_shards": 16}
	return {"hero_shards": 0}


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
	var recommended_power := _recommended_power(chapter, stage_in_chapter)
	var next_id := ACT1_STAGE_IDS[index + 1] if index >= 0 and index + 1 < ACT1_STAGE_IDS.size() else "endless_1"
	var is_boss := (
		stage_in_chapter in [5, BOSS_STAGE_NUMBER]
	)
	var unlock_victory: Array[String] = []
	var readability := _readability_fields(stage_id, chapter, stage_in_chapter, unlock_victory)
	var recommendation := _recommendation_fields(stage_id)
	var resonance := _resonance_profile(chapter, stage_in_chapter)
	var encounter := _chapter_two_encounter_profile(chapter, stage_in_chapter)
	var tv_encounter := _chapter_three_encounter_profile(chapter, stage_in_chapter)
	var alliance_encounter := _chapter_four_encounter_profile(chapter, stage_in_chapter)
	var finale_encounter := _chapter_five_encounter_profile(chapter, stage_in_chapter)
	return {
		"stage_id": stage_id,
		"act": 1,
		"chapter": chapter,
		"stage_in_chapter": stage_in_chapter,
		"display_name": "%d-%d %s" % [
			chapter,
			stage_in_chapter,
			_stage_display_name(chapter, stage_in_chapter, is_boss),
		],
		"stage_names": DEFAULT_STAGE_NAMES.duplicate(),
		"final_structure_id": "alliance_core",
		"suppressible_cannon": is_boss,
		"cannon_suppression_target": _cannon_suppression_target(chapter) if is_boss else 0,
		"cannon_warning_ticks": (25 if chapter == 1 else 20) if is_boss else 0,
		"next_stage_id": next_id,
		"reward_victory": _victory_reward(chapter, stage_in_chapter),
		"encounter_tier": _encounter_tier(stage_in_chapter),
		"required_counter_tech": _required_counter_tech(chapter, stage_in_chapter),
		"reward_defeat": {
			"gold": 0,
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
		"resonance_period_ticks": int(resonance.get("period_ticks", 0)),
		"resonance_warning_ticks": int(resonance.get("warning_ticks", 0)),
		"resonance_energy_drain": int(resonance.get("energy_drain", 0)),
		"resonance_weakness_ticks": int(resonance.get("weakness_ticks", 0)),
		"speaker_reinforcement_period_ticks": int(encounter.get("reinforcement_period_ticks", 0)),
		"speaker_reinforcement_wave_limit": int(encounter.get("reinforcement_wave_limit", 0)),
		"speaker_reinforcement_spawns_unit": bool(encounter.get("reinforcement_spawns_unit", true)),
		"speaker_echo_period_ticks": int(encounter.get("echo_period_ticks", 0)),
		"speaker_echo_warning_ticks": int(encounter.get("echo_warning_ticks", 0)),
		"speaker_echo_damage": int(encounter.get("echo_damage", 0)),
		"speaker_echo_impact_limit": int(encounter.get("echo_impact_limit", 0)),
		"tv_signal_period_ticks": int(tv_encounter.get("signal_period_ticks", 0)),
		"tv_signal_duration_ticks": int(tv_encounter.get("signal_duration_ticks", 0)),
		"tv_signal_limit": int(tv_encounter.get("signal_limit", 0)),
		"tv_teleport_period_ticks": int(tv_encounter.get("teleport_period_ticks", 0)),
		"tv_teleport_limit": int(tv_encounter.get("teleport_limit", 0)),
		"tv_control_period_ticks": int(tv_encounter.get("control_period_ticks", 0)),
		"tv_control_duration_ticks": int(tv_encounter.get("control_duration_ticks", 0)),
		"tv_control_limit": int(tv_encounter.get("control_limit", 0)),
		"tv_shield_period_ticks": int(tv_encounter.get("shield_period_ticks", 0)),
		"tv_shield_amount": int(tv_encounter.get("shield_amount", 0)),
		"tv_shield_limit": int(tv_encounter.get("shield_limit", 0)),
		"alliance_module_mode": String(alliance_encounter.get("module_mode", "")),
		"alliance_module_period_ticks": int(alliance_encounter.get("module_period_ticks", 0)),
		"alliance_mark_period_ticks": int(alliance_encounter.get("mark_period_ticks", 0)),
		"alliance_mark_duration_ticks": int(alliance_encounter.get("mark_duration_ticks", 0)),
		"alliance_mark_limit": int(alliance_encounter.get("mark_limit", 0)),
		"alliance_anti_air_period_ticks": int(alliance_encounter.get("anti_air_period_ticks", 0)),
		"alliance_anti_air_duration_ticks": int(alliance_encounter.get("anti_air_duration_ticks", 0)),
		"alliance_anti_air_limit": int(alliance_encounter.get("anti_air_limit", 0)),
		"alliance_purge_period_ticks": int(alliance_encounter.get("purge_period_ticks", 0)),
		"alliance_purge_damage": int(alliance_encounter.get("purge_damage", 0)),
		"alliance_purge_limit": int(alliance_encounter.get("purge_limit", 0)),
		"alliance_shield_period_ticks": int(alliance_encounter.get("shield_period_ticks", 0)),
		"alliance_shield_amount": int(alliance_encounter.get("shield_amount", 0)),
		"alliance_shield_limit": int(alliance_encounter.get("shield_limit", 0)),
		"finale_mode": String(finale_encounter.get("mode", "")),
		"finale_period_ticks": int(finale_encounter.get("period_ticks", 0)),
		"finale_warning_ticks": int(finale_encounter.get("warning_ticks", 0)),
		"finale_damage": int(finale_encounter.get("damage", 0)),
		"finale_limit": int(finale_encounter.get("limit", 0)),
		"finale_armor_amount": int(finale_encounter.get("armor_amount", 0)),
		"finale_support_tick": int(finale_encounter.get("support_tick", 0)),
		"finale_support_damage": int(finale_encounter.get("support_damage", 0)),
		"power_bp": power_bp,
		"minimum_power": int(recommended_power * 85 / 100),
		"recommended_power": recommended_power,
	}


static func _stage_display_name(chapter: int, stage_in_chapter: int, is_boss: bool) -> String:
	var names := CHAPTER_STAGE_NAMES.get(chapter, []) as Array
	if stage_in_chapter >= 1 and stage_in_chapter <= names.size():
		return String(names[stage_in_chapter - 1])
	return "联盟基地" if is_boss else "城市大道"


static func _recommended_power(chapter: int, stage_in_chapter: int) -> int:
	if chapter == 1 and stage_in_chapter <= 5:
		return LEGACY_RECOMMENDED_POWER[(chapter - 1) * 5 + stage_in_chapter - 1]
	if chapter == 1 and stage_in_chapter >= 6:
		var post_tutorial := [6800, 7050, 7300, 7800, 7950, 8200, 9000]
		return int(post_tutorial[stage_in_chapter - 6])
	var start := CHAPTER_POWER_START[chapter - 1]
	var finish := CHAPTER_POWER_END[chapter - 1]
	var linear := start + int((finish - start) * (stage_in_chapter - 1) / 11)
	var wall_bonus := 0
	if stage_in_chapter == 6:
		wall_bonus = int((finish - start) * 8 / 100)
	elif stage_in_chapter == 9:
		wall_bonus = int((finish - start) * 5 / 100)
	elif stage_in_chapter == BOSS_STAGE_NUMBER:
		wall_bonus = int((finish - start) * 10 / 100)
	return linear + wall_bonus


static func _enemy_power_bp(chapter: int, stage_in_chapter: int) -> int:
	if stage_in_chapter <= 5:
		return LEGACY_ENEMY_POWER_BP[(chapter - 1) * 5 + stage_in_chapter - 1]
	if chapter == 1 and stage_in_chapter >= 6:
		var post_tutorial := [11600, 11900, 12200, 13200, 13500, 13900, 15200]
		return int(post_tutorial[stage_in_chapter - 6])
	var start := CHAPTER_ENEMY_BP_START[chapter - 1]
	var finish := CHAPTER_ENEMY_BP_END[chapter - 1]
	var linear := start + int((finish - start) * (stage_in_chapter - 1) / 11)
	if stage_in_chapter == 6:
		return int(linear * 112 / 100)
	if stage_in_chapter == 9:
		return int(linear * 106 / 100)
	if stage_in_chapter == BOSS_STAGE_NUMBER:
		return int(linear * 112 / 100)
	return linear


static func _encounter_tier(stage_in_chapter: int) -> String:
	if stage_in_chapter == BOSS_STAGE_NUMBER:
		return "boss"
	if ELITE_STAGE_NUMBERS.has(stage_in_chapter):
		return "elite"
	if stage_in_chapter % 3 == 2:
		return "checkpoint"
	return "normal"


static func _victory_reward(chapter: int, stage_in_chapter: int) -> Dictionary:
	# Twelve stages redistribute the former five-stage chapter budget instead of
	# multiplying it. The second stage of each trio is the visible small reward;
	# elite and boss rewards carry the meaningful spikes.
	var gold := 12 + chapter * 3
	if stage_in_chapter % 3 == 2:
		gold += 10
	if ELITE_STAGE_NUMBERS.has(stage_in_chapter):
		gold += 28
	if stage_in_chapter == BOSS_STAGE_NUMBER:
		gold += 62
	return {"gold": gold}


static func _required_counter_tech(chapter: int, stage_in_chapter: int) -> String:
	if stage_in_chapter not in [9, BOSS_STAGE_NUMBER]:
		return ""
	var chapter_techs := {
		1: "counter.sunglasses",
		2: "counter.resonance_insulation",
		3: "counter.signal_anchor",
		4: "counter.alliance_decoder",
		5: "counter.command_stabilizer",
	}
	return String(chapter_techs.get(chapter, ""))


static func counter_tech_for_chapter(chapter: int) -> Dictionary:
	var definitions := {
		1: {
			"tech_id": "counter.sunglasses",
			"display_name": "战术墨镜",
			"cost": 18,
			"threat": "电视人的致盲闪屏会重创未防护的马桶人。",
			"effect": "免疫致盲，并将闪屏伤害降低 80%。",
		},
		2: {
			"tech_id": "counter.resonance_insulation",
			"display_name": "共振绝缘层",
			"cost": 26,
			"threat": "音波共振会抽空技能能量并暴露全队。",
			"effect": "共振能量损失与易伤持续时间降低 70%。",
		},
		3: {
			"tech_id": "counter.signal_anchor",
			"display_name": "信号锚定器",
			"cost": 34,
			"threat": "电视人会消失、换位并控制落单单位。",
			"effect": "控制持续时间降低 75%，首次传送会被揭露。",
		},
		4: {
			"tech_id": "counter.alliance_decoder",
			"display_name": "联军协议解码器",
			"cost": 42,
			"threat": "联合模块会轮换标记、防空、净化与护盾。",
			"effect": "模块持续时间降低 60%，并显示下一模块。",
		},
		5: {
			"tech_id": "counter.command_stabilizer",
			"display_name": "指挥核心稳定器",
			"cost": 50,
			"threat": "终章诱导撤退与连续炮击会瓦解技能循环。",
			"effect": "撤退冲击伤害降低 75%，炮击预警延长。",
		},
	}
	return (definitions.get(chapter, {}) as Dictionary).duplicate(true)


static func _resonance_profile(chapter: int, stage_in_chapter: int) -> Dictionary:
	if chapter != 2:
		return {}
	var beat := (
		stage_in_chapter
		if stage_in_chapter <= 5
		else mini(5, int(ceil(float(stage_in_chapter - 5) * 5.0 / 7.0)))
	)
	var beats := {
		1: {"period_ticks": 55, "warning_ticks": 10, "energy_drain": 10, "weakness_ticks": 5},
		2: {"period_ticks": 50, "warning_ticks": 10, "energy_drain": 12, "weakness_ticks": 6},
		3: {"period_ticks": 45, "warning_ticks": 10, "energy_drain": 14, "weakness_ticks": 7},
		4: {"period_ticks": 35, "warning_ticks": 10, "energy_drain": 18, "weakness_ticks": 8},
		5: {"period_ticks": 35, "warning_ticks": 10, "energy_drain": 18, "weakness_ticks": 8},
	}
	return (beats.get(beat, beats[5]) as Dictionary).duplicate(true)


static func _chapter_two_encounter_profile(
	chapter: int,
	stage_in_chapter: int
) -> Dictionary:
	if chapter != 2:
		return {}
	var beat := (
		stage_in_chapter
		if stage_in_chapter <= 5
		else mini(5, int(ceil(float(stage_in_chapter - 5) * 5.0 / 7.0)))
	)
	var beats := {
		3: {
			"reinforcement_period_ticks": 65,
			"reinforcement_wave_limit": 2,
		},
		4: {
			"echo_period_ticks": 50,
			"echo_warning_ticks": 10,
			"echo_damage": 1,
			"echo_impact_limit": 2,
		},
		5: {
			"reinforcement_period_ticks": 70,
			"reinforcement_wave_limit": 1,
			"reinforcement_spawns_unit": false,
			"echo_period_ticks": 50,
			"echo_warning_ticks": 10,
			"echo_damage": 1,
			"echo_impact_limit": 3,
		},
	}
	return (beats.get(beat, {}) as Dictionary).duplicate(true)


static func _chapter_three_encounter_profile(
	chapter: int,
	stage_in_chapter: int
) -> Dictionary:
	if chapter != 3:
		return {}
	var beat := (
		stage_in_chapter
		if stage_in_chapter <= 5
		else mini(5, int(ceil(float(stage_in_chapter - 5) * 5.0 / 7.0)))
	)
	var beats := {
		1: {
			"signal_period_ticks": 60,
			"signal_duration_ticks": 10,
			"signal_limit": 2,
		},
		2: {
			"teleport_period_ticks": 50,
			"teleport_limit": 3,
		},
		3: {
			"control_period_ticks": 40,
			"control_duration_ticks": 8,
			"control_limit": 6,
		},
		4: {
			"control_period_ticks": 50,
			"control_duration_ticks": 8,
			"control_limit": 5,
			"shield_period_ticks": 60,
			"shield_amount": 24,
			"shield_limit": 4,
		},
		5: {
			"teleport_period_ticks": 120,
			"teleport_limit": 6,
			"control_period_ticks": 120,
			"control_duration_ticks": 8,
			"control_limit": 6,
			"shield_period_ticks": 120,
			"shield_amount": 28,
			"shield_limit": 6,
		},
	}
	return (beats.get(beat, {}) as Dictionary).duplicate(true)


static func _chapter_four_encounter_profile(
	chapter: int,
	stage_in_chapter: int
) -> Dictionary:
	if chapter != 4:
		return {}
	var beat := (
		stage_in_chapter
		if stage_in_chapter <= 5
		else mini(5, int(ceil(float(stage_in_chapter - 5) * 5.0 / 7.0)))
	)
	var beats := {
		1: {
			"mark_period_ticks": 50,
			"mark_duration_ticks": 15,
			"mark_limit": 4,
		},
		2: {
			"anti_air_period_ticks": 50,
			"anti_air_duration_ticks": 5,
			"anti_air_limit": 4,
		},
		3: {
			"purge_period_ticks": 50,
			"purge_damage": 32,
			"purge_limit": 4,
		},
		4: {
			"module_mode": "stage",
			"module_period_ticks": 50,
			"mark_duration_ticks": 15,
			"mark_limit": 4,
			"anti_air_duration_ticks": 5,
			"anti_air_limit": 4,
			"purge_damage": 32,
			"purge_limit": 4,
			"shield_amount": 24,
			"shield_limit": 4,
		},
		5: {
			"module_mode": "cycle",
			"module_period_ticks": 45,
			"mark_duration_ticks": 15,
			"mark_limit": 6,
			"anti_air_duration_ticks": 5,
			"anti_air_limit": 6,
			"purge_damage": 36,
			"purge_limit": 6,
			"shield_amount": 28,
			"shield_limit": 6,
		},
	}
	return (beats.get(beat, {}) as Dictionary).duplicate(true)


static func _chapter_five_encounter_profile(
	chapter: int,
	stage_in_chapter: int
) -> Dictionary:
	if chapter != 5:
		return {}
	var beat := (
		stage_in_chapter
		if stage_in_chapter <= 5
		else mini(5, int(ceil(float(stage_in_chapter - 5) * 5.0 / 7.0)))
	)
	var beats := {
		1: {"mode": "retreat", "period_ticks": 55, "warning_ticks": 10, "damage": 20, "limit": 3},
		2: {"mode": "armor", "period_ticks": 50, "armor_amount": 34, "limit": 4},
		3: {"mode": "titan", "period_ticks": 60, "warning_ticks": 10, "damage": 26, "limit": 3},
		4: {"mode": "combined", "period_ticks": 55, "warning_ticks": 10, "damage": 24, "armor_amount": 30, "limit": 4, "support_tick": 85, "support_damage": 180},
		5: {"mode": "final_exam", "period_ticks": 50, "warning_ticks": 10, "damage": 28, "armor_amount": 34, "limit": 6, "support_tick": 100, "support_damage": 220},
	}
	return (beats.get(beat, {}) as Dictionary).duplicate(true)


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
	}
	config["reward_defeat"] = {"gold": 0}
	config["unlock_on_defeat"] = []
	config["unlock_on_victory"] = []
	config["unlock_preview"] = ""
	config["threat_summary"] = "无尽前线会逐层提高敌军生命、攻击和推荐战力。"
	config["counter_hint"] = "根据实际阵亡与材料储备决定继续推进或主动撤退止损。"
	return config


static func _scaled_repeat_reward(base: Dictionary) -> Dictionary:
	return {
		"gold": int(int(base.get("gold", 0)) * 30 / 100),
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
			"reason": "炮台防线是设计好的首次失败点；失败后由研究所研发 1-2、1-3 首通获得的永久装甲与冲锋援军。",
		},
		"stage_1_5": {
			"recommended": ["heavy.armored", "ordinary.assault"],
			"fallback": [],
			"reason": "首次成长二选一：冲锋二星压制巨炮，或装甲二星格挡反震；两条路线都能完成首章。",
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
			"recommended": ["flying.rocket", "heavy.armored", "ordinary.sonic"],
			"fallback": ["special.repair"],
			"reason": "火箭快速削阶段目标，装甲避免队伍被精英火力打散，音波缓解共振压力。",
		},
		"stage_2_5": {
			"recommended": ["heavy.armored", "flying.rocket", "ordinary.sonic"],
			"fallback": ["special.repair"],
			"reason": "中段据点需要承压、削弱和拆结构；自爆设计图留到 2-12 章节 Boss 首通后发放。",
		},
		"stage_3_1": {
			"recommended": ["special.repair", "heavy.armored"],
			"fallback": ["ordinary.sonic"],
			"reason": "TV 控制会制造点杀窗口，维修和装甲提高容错。",
		},
		"stage_3_2": {
			"recommended": ["special.repair", "flying.rocket", "heavy.armored"],
			"fallback": ["heavy.armored"],
			"reason": "先用维修保住被控制的低血单位，火箭远程拆核心设施；净化型号将在 3-3 精英战后获得。",
		},
		"stage_3_3": {
			"recommended": ["ordinary.sonic", "special.repair", "heavy.armored"],
			"fallback": ["special.parasite"],
			"reason": "音波削弱控制链，维修与装甲兜底；首通后获得信号净化型号。",
		},
		"stage_3_4": {
			"recommended": ["ordinary.signal_purifier", "special.parasite", "special.repair"],
			"fallback": ["flying.rocket"],
			"reason": "净化解除控制，寄生幼体分摊精英火力，维修保证主队不被连续击穿。",
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
			"recommended": ["ordinary.sonic", "heavy.armored", "special.repair"],
			"fallback": ["special.repair"],
			"reason": "地面音波与装甲不会被防空锁定，维修维持推进；磁轨型号将在 4-3 精英战后获得。",
		},
		"stage_4_3": {
			"recommended": ["flying.rocket", "special.repair", "ordinary.sonic"],
			"fallback": ["ordinary.sonic"],
			"reason": "净化只处理召唤物；火箭、维修和音波用永久主队稳定拆模块，首通后获得磁轨牵引型号。",
		},
		"stage_4_4": {
			"recommended": ["flying.magnetic_conductor", "heavy.saw", "special.repair"],
			"fallback": ["flying.rocket"],
			"reason": "磁轨聚拢守军，双锯切精英，维修防止队伍在压力关崩盘。",
		},
		"stage_3_7": {
			"recommended": ["heavy.anchor_bastion", "ordinary.signal_purifier", "special.repair"],
			"fallback": ["heavy.armored"],
			"reason": "3-6 战力墙后的锚桩型号稳住阵线，净化处理 TV 控制链。",
		},
		"stage_4_7": {
			"recommended": ["ordinary.phase_tunneler", "flying.magnetic_conductor", "special.repair"],
			"fallback": ["heavy.saw"],
			"reason": "4-6 战力墙后的相位型号直切后排，磁轨聚怪后形成集中突破。",
		},
		"stage_4_10": {
			"recommended": ["special.protocol_weaver", "ordinary.phase_tunneler", "heavy.saw"],
			"fallback": ["special.repair"],
			"reason": "4-9 科技墙后的协议型号夺取敌方护盾，相位与双锯负责完成收束。",
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
	var is_boss := stage_in_chapter in [5, BOSS_STAGE_NUMBER]
	var cycle_position := ((stage_in_chapter - 1) % 3) + 1
	var beat := 5 if is_boss else (4 if stage_in_chapter == 9 else cycle_position)
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
		1: "使用现有永久军团观察敌方机制；若战力不足，先培养角色或调整前后排。",
		2: "调整前后排，让承伤角色吃第一轮火力，后排保留输出。",
		3: "使用本章新解法或上一章反制单位，不要只看总战力。",
		4: "失败后优先升星承压或恢复位，而不是只堆最高攻击。",
		5: "先拆外围模块降低炮击压力，再在核心暴露时集中技能。",
	}
	var chapter_feedback: Dictionary = {
		1: "灰镜街区让玩家确认：研究突破、永久援军和自主升星会直接改变攻城结果。",
		2: "震荡封锁线提醒玩家：技能节奏、范围爆发和维修同样重要。",
		3: "黑屏城区强调反控制与特殊单位价值，战斗不再只是正面推血条。",
		4: "三军联合防线要求玩家根据敌方模块换阵，单一套路开始失效。",
		5: "伪胜之城制造战术胜利与战略陷阱的反差，为幕末工厂被毁做铺垫。",
	}
	var unlock_preview := ""
	if not unlock_victory.is_empty():
		unlock_preview = "胜利后预览新蓝图：%s。" % _recipe_labels(unlock_victory)
	var threat := "%s %s" % [String(chapter_threats[chapter]), String(beat_threats[beat])]
	var counter := "%s %s" % [String(chapter_counters[chapter]), String(beat_counters[beat])]
	if stage_in_chapter == 6:
		threat += " 这是本章战力精英墙，会直接检验角色等级、星级和阵型承压。"
	if stage_in_chapter == 9:
		var tech := counter_tech_for_chapter(chapter)
		threat += " 这是本章科技精英墙：%s" % String(tech.get("threat", "需要专项反制科技。"))
		counter = "先在研究所研发「%s」。%s" % [
			String(tech.get("display_name", "专项反制")),
			String(tech.get("effect", "")),
		]
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
			"counter": "回到开局建成的研究所，研发 1-2、1-3 获得的装甲与冲锋图纸，再把两名永久援军编入队伍反攻。",
		},
	}
	if opening_readability.has(stage_id):
		var opening := opening_readability[stage_id] as Dictionary
		threat = String(opening["threat"])
		counter = String(opening["counter"])
	if is_boss:
		threat = "%s 本关是章节 Boss，最终结构会分段受损并逼玩家与基地比拼输出速度。" % String(chapter_threats[chapter])
		counter = "%s Boss 战优先处理电池和护甲层，核心暴露后再集中释放攻城技能。" % String(chapter_counters[chapter])
	var encounter_readability: Dictionary = {
		"stage_3_1": {
			"threat": "TV 单位会短暂从战场信号中消失，原集火目标在 2 秒内无法锁定。",
			"counter": "目标消失时立即转火场上敌人；它复现后再决定是否切回。",
		},
		"stage_3_2": {
			"threat": "TV 精英会在前后战斗带与路线间传送，持续打乱军团锁定顺序。",
			"counter": "观察青色传送反馈，优先处理贴近前线的精英，不要追逐退后的目标。",
		},
		"stage_3_3": {
			"threat": "屏幕控制会让当前低生命关键成员短暂停火，但触发次数有限。",
			"counter": "受控成员停火时让其他角色维持推进；手动技能不要全部压在同一人身上。",
		},
		"stage_3_4": {
			"threat": "TV 监军会为当前战斗带的高伤精英补充护盾，并穿插有限屏幕控制。",
			"counter": "先集中火力击穿青色护盾，再处理高伤目标；保留一轮技能应对重新加盾。",
		},
		"stage_3_5": {
			"threat": "本关是章节 Boss：黑屏中继塔错峰轮换传送、屏幕控制与精英护盾，并启用核心巨炮。",
			"counter": "Boss 战先识别当前模块；传送后重锁目标、控制时分散技能、护盾期集中爆发，巨炮预警仍优先处理。",
		},
		"stage_4_1": {
			"threat": "Camera 会标记当前最高攻击主力，Speaker 守军随后集中攻击该目标。",
			"counter": "用装甲承压、维修续航或召唤物分担战线；红色标记期间优先开盾与治疗。",
		},
		"stage_4_2": {
			"threat": "防空扫描会让一名火箭或自爆飞行角色短暂停火，但不会伤害永久角色。",
			"counter": "减少纯飞行编队，加入音波、装甲或维修等地面成员维持拆塔输出。",
		},
		"stage_4_3": {
			"threat": "净化装置只会伤害寄生幼体与被策反单位；永久角色完全不受净化伤害。",
			"counter": "用永久主队输出，或把召唤技能错开净化脉冲；火箭、维修和音波都是可用替代。",
		},
		"stage_4_4": {
			"threat": "三段战场依次启用联合标记、防空扫描、净化与精英护盾。",
			"counter": "根据当前阶段保留承压、地面输出与破盾技能，不需要为单一模块牺牲整支阵容。",
		},
		"stage_4_5": {
			"threat": "本关是章节 Boss：三联军械库按固定顺序轮换标记、防空、净化护盾，并启用核心巨炮。",
			"counter": "Boss 战读取顶部模块反馈，依次用承压、地面输出和集中破盾应对；巨炮预警始终优先。",
		},
	}
	if encounter_readability.has(stage_id):
		var encounter_copy := encounter_readability[stage_id] as Dictionary
		threat = String(encounter_copy["threat"])
		counter = String(encounter_copy["counter"])
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
	var grunt_archetype := "%s_grunt" % family
	var support_archetype := "%s_support" % family
	var elite_archetype := "%s_elite" % family
	var values: Array[Dictionary] = [
		_enemy("%s_grunt_l" % family, base_label, "fighter", 0, 220, 0, 95, 18, 5, 34, 8, false, grunt_archetype),
		_enemy("%s_grunt_c" % family, base_label, "fighter", 0, 245, 1, 95, 18, 5, 34, 8, false, grunt_archetype),
		_enemy("%s_support_r" % family, "%s射手" % base_label.trim_suffix("兵"), ranged_class, 0, 272, 2, 95, 20, 5, 108, 8, false, support_archetype),
		_enemy("%s_elite_mid" % family, elite_label, "guardian", 1, 505, 1, 190, 29, 12, 38, 8, true, elite_archetype),
	]
	if stage_in_chapter >= 2:
		values.append(_enemy("%s_flank_l" % family, "%s射手" % base_label.trim_suffix("兵"), ranged_class, 1, 480, 0, 95, 20, 5, 108, 8, false, support_archetype))
	if stage_in_chapter >= 3:
		values.append(_enemy("%s_flank_r" % family, "%s射手" % base_label.trim_suffix("兵"), ranged_class, 1, 520, 2, 95, 20, 5, 108, 8, false, support_archetype))
	if stage_in_chapter >= 4:
		values.append(_enemy("%s_elite_base" % family, "%s监军" % elite_label.trim_suffix("卫"), "arcanist", 2, 805, 1, 240, 34, 11, 96, 8, true, "%s_overseer" % family))
	values.append(_enemy("%s_core_guard_l" % family, "核心近卫", "guardian", 2, 840, 0, 190, 29, 13, 38, 7, true, "core_guard"))
	values.append(_enemy("%s_core_guard_r" % family, "核心近卫", "guardian", 2, 840, 2, 190, 29, 13, 38, 7, true, "core_guard"))
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


static func _fixed_enemies(enemies: Array[Dictionary]) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for enemy_data in enemies:
		var enemy := enemy_data.duplicate(true)
		enemy["max_hp"] = int(enemy["hp"])
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


static func _shape_boss_finale(config: Dictionary) -> void:
	# Boss 关把压力从“刚进第三段就团灭”转成最终核心的收尾检验：
	# 降低第三段护卫与外围设施的压制，但加厚最终核心，使首轮成长能打到
	# Boss 并削掉血量，下一轮成长后才稳定完成击破。
	var final_structure_id := String(config.get("final_structure_id", "alliance_core"))
	var chapter := int(config.get("chapter", 2))
	config["cannon_suppression_target"] = 800 + chapter * 100
	config["boss_cannon_damage"] = 140 + chapter * 20
	config["boss_cannon_period_ticks"] = 28 - chapter
	var core_hp_multiplier_percent := 95 if chapter == 2 else 220
	for enemy in config.get("enemies", []):
		if int(enemy.get("stage", -1)) != 2:
			continue
		enemy["hp"] = maxi(1, int(int(enemy.get("hp", 1)) * 40 / 100))
		enemy["max_hp"] = int(enemy["hp"])
		enemy["attack"] = maxi(1, int(int(enemy.get("attack", 1)) * 40 / 100))
	for structure in config.get("structures", []):
		if String(structure.get("structure_id", "")) == final_structure_id:
			structure["max_hp"] = maxi(
				1,
				int(int(structure.get("max_hp", 1)) * core_hp_multiplier_percent / 100)
			)
			structure["hp"] = int(structure["max_hp"])
		elif int(structure.get("stage", -1)) == 2:
			structure["max_hp"] = maxi(1, int(int(structure.get("max_hp", 1)) * 40 / 100))
			structure["hp"] = int(structure["max_hp"])
			structure["attack"] = maxi(0, int(int(structure.get("attack", 0)) * 40 / 100))


static func _shape_chapter_two_gate(config: Dictionary) -> void:
	# 2-4 teaches the full echo/resonance combination, but its cleanup must not
	# outlast the chapter Boss. Keep the authored enemies and pressure intact so
	# the 1★ wall remains real; shorten only the exposed final objective.
	var final_structure_id := String(config.get("final_structure_id", "alliance_core"))
	for structure in config.get("structures", []):
		if String(structure.get("structure_id", "")) != final_structure_id:
			continue
		structure["max_hp"] = maxi(1, int(int(structure.get("max_hp", 1)) * 40 / 100))
		structure["hp"] = int(structure["max_hp"])


static func _shape_chapter_one_boss(config: Dictionary) -> void:
	# 首章 Boss 只通过可见的敌人、结构和巨炮形成压力，不使用计时强制判负。
	pass


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


static func _enemy(id: String, label: String, class_id: String, stage_index: int, road_position: int, lane: int, hp: int, attack: int, defense: int, attack_range: int, period: int, elite: bool, archetype_id: String = "") -> Dictionary:
	return {
		"unit_id": id,
		"archetype_id": archetype_id if not archetype_id.is_empty() else id,
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
