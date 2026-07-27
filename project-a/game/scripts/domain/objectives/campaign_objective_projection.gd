class_name CampaignObjectiveProjection
extends RefCounted

const ObjectiveHurdleCatalogScript := preload("res://game/scripts/content/objective_hurdle_catalog.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")
const WarReadinessReportScript := preload("res://game/scripts/domain/progression/war_readiness_report.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const FactionCatalogScript := preload("res://game/scripts/domain/content/faction_catalog.gd")
const RecruitmentResultProjectionScript := preload(
	"res://game/scripts/domain/recruitment/recruitment_result_projection.gd"
)
const ResearchBreakthroughServiceScript := preload(
	"res://game/scripts/domain/recruitment/research_breakthrough_service.gd"
)

const CHAPTER_ONE_STAGE_IDS: Array[String] = [
	"stage_1_1",
	"stage_1_2",
	"stage_1_3",
	"stage_1_4",
	"stage_1_5",
]


static func derive(state: RefCounted, onboarding: Dictionary) -> Dictionary:
	if state == null:
		return {}
	var cleared := state.stage_progress.get("cleared_stages", []) as Array
	var stage_id := String(state.stage_progress.get("highest_unlocked_stage", StageCatalogScript.DEFAULT_STAGE_ID))
	var stage_config := StageCatalogScript.stage(stage_id)
	var report := WarReadinessReportScript.derive(state, stage_config)
	var action := report.get("next_action", {}) as Dictionary
	var needs_growth := String(action.get("id", "attack")) == "upgrade"
	var challenge_gap := maxi(
		0,
		int(report.get("minimum_power", 0)) - int(report.get("cp_ready", 0))
	)
	var chapter_one_cleared := _count_cleared(cleared, CHAPTER_ONE_STAGE_IDS)
	var campaign_cleared := _count_cleared(cleared, StageCatalogScript.ACT1_STAGE_IDS)
	var onboarding_finished := bool(onboarding.get("finished", false))
	var faction_recruit_pending := (
		onboarding_finished
		and cleared.has("stage_1_5")
		and not ResearchBreakthroughServiceScript.is_faction_claimed(state)
	)
	var faction_journey := _faction_journey(state, cleared)
	var faction_journey_active := bool(faction_journey.get("active", false))
	var hierarchy := _onboarding_hierarchy(onboarding, cleared)
	if onboarding_finished:
		hierarchy = (
			_faction_recruit_hierarchy()
			if faction_recruit_pending
			else (faction_journey.get("hierarchy", {}) as Dictionary)
			if faction_journey_active
			else _next_chapter_hierarchy(
				stage_id,
				stage_config,
				needs_growth,
				challenge_gap
			)
		)
	return {
		"stage_id": stage_id,
		"stage_config": stage_config,
		"report": report,
		"needs_growth": needs_growth,
		"challenge_gap": challenge_gap,
		"chapter_one_cleared": chapter_one_cleared,
		"campaign_cleared": campaign_cleared,
		"chapter_one_complete": chapter_one_cleared >= CHAPTER_ONE_STAGE_IDS.size(),
		"campaign_complete": campaign_cleared >= StageCatalogScript.ACT1_STAGE_IDS.size(),
		"title": (
			{
				"primary_label": "返回指挥室",
				"objective": "下一行动 · 领取阵营起手十连",
			}
			if faction_recruit_pending
			else (faction_journey.get("title", {}) as Dictionary)
			if faction_journey_active
			else _title_view(
			cleared.is_empty(),
			campaign_cleared >= StageCatalogScript.ACT1_STAGE_IDS.size(),
			chapter_one_cleared,
			stage_config,
			report,
			needs_growth,
			challenge_gap
			)
		),
		"hierarchy": hierarchy,
		"factory_task": (
			_faction_recruit_factory_task()
			if faction_recruit_pending
			else (faction_journey.get("factory_task", {}) as Dictionary)
			if faction_journey_active
			else _next_chapter_factory_task(
				stage_id,
				stage_config,
				needs_growth,
				challenge_gap
			)
			if onboarding_finished
			else onboarding
		),
	}


static func _faction_journey(state: RefCounted, cleared: Array) -> Dictionary:
	if not ResearchBreakthroughServiceScript.is_faction_claimed(state):
		return {"active": false}
	var event := RecruitmentResultProjectionScript.latest_event_for_command(
		state,
		"claim_faction_signal"
	)
	var archetype_id := String(event.get("guaranteed_duplicate_archetype", ""))
	if archetype_id.is_empty():
		return {"active": false}
	var recipe := FactoryCatalogScript.recipe_for_archetype(archetype_id)
	var role_name := String(recipe.get("display_name", archetype_id))
	var faction_name := FactionCatalogScript.faction_for(archetype_id)
	var hero: RefCounted = null
	for roster_hero in state.roster:
		if String(roster_hero.archetype_id) == archetype_id:
			hero = roster_hero
			break
	var phase := ""
	var small := ""
	var cta_label := ""
	var target := ""
	var stage_id := String(
		state.stage_progress.get("highest_unlocked_stage", "stage_2_1")
	)
	var hurdle_title := ""
	var hurdle_reason := ""
	var recovery := ""
	var hero_id := ""
	if hero == null:
		phase = "research"
		small = "把%s图纸研发为永久角色" % role_name
		cta_label = "研发%s" % role_name
		target = "blueprints"
		hurdle_title = "图纸还不是角色"
		hurdle_reason = "抽取获得的是永久设计资格，需要在研究所完成实体化。"
		recovery = "研究所已建成；启动并领取5秒研发，不消耗抽卡资源。"
	else:
		hero_id = String(hero.hero_id)
		var deployed: bool = state.formation.hero_ids().has(hero_id)
		var chapter_two_clears := _count_cleared(cleared, [
			"stage_2_1", "stage_2_2", "stage_2_3",
		])
		if not deployed:
			phase = "formation"
			small = "把%s编入六槽队伍，建立%s起手式" % [role_name, faction_name]
			cta_label = "编入%s" % role_name
			target = "formation"
			hurdle_title = "新角色仍在待命"
			hurdle_reason = "永久角色不会自动替玩家改变编队。"
			recovery = "进入编队，选择一个阵位并亲自确认替换。"
		elif chapter_two_clears < 3:
			phase = "prove_one_star"
			small = "用%d★%s推进第二章（实战证明 %d/3）" % [
				int(hero.star),
				role_name,
				chapter_two_clears,
			]
			cta_label = "验证%s · %s" % [
				role_name,
				String(StageCatalogScript.stage(stage_id).get("display_name", stage_id)),
			]
			target = "map"
			hurdle_title = "阵营打法尚未经过实战"
			hurdle_reason = "战力数字不能替代玩家亲自看见新职责改变战局。"
			recovery = "连续推进三座城，观察新角色的技能时机与战报贡献。"
		elif int(hero.star) < 2:
			phase = "star"
			small = "使用%s专属碎片升至2★，兑现阵营质变" % role_name
			cta_label = "将%s升至2★" % role_name
			target = "legion"
			hurdle_title = "第二章后段成长墙"
			hurdle_reason = "1★已经证明角色定位，后段要求一次可感知的职责质变。"
			recovery = "免费十连已保证同型号重复；碎片只用于这个角色。"
		elif not cleared.has("stage_2_5"):
			phase = "breakthrough"
			small = "用2★%s突破第二章后段，击毁2-5核心" % role_name
			cta_label = "检验2★质变 · %s" % String(
				StageCatalogScript.stage(stage_id).get("display_name", stage_id)
			)
			target = "map"
			hurdle_title = "阵营核心最终验证"
			hurdle_reason = "升星只有在战斗行为和过关方式改变时才有意义。"
			recovery = "保留新被动的技能窗口；失败不损失角色、碎片或保底。"
		else:
			return {"active": false}
	var hierarchy := {
		"macro": "用自己的角色池形成%s阵营" % faction_name,
		"medium": "阵营核心：%s · %s" % [role_name, _faction_phase_title(phase)],
		"small": small,
		"hurdle": {
			"scale": "阵营成长",
			"title": hurdle_title,
			"reason": hurdle_reason,
			"recovery": recovery,
		},
		"finished": false,
		"actionable": true,
		"cta_label": cta_label,
		"target": target,
		"stage_id": stage_id,
		"hero_id": hero_id,
		"archetype_id": archetype_id,
	}
	return {
		"active": true,
		"phase": phase,
		"title": {
			"primary_label": cta_label,
			"objective": "阵营成形 · %s" % small,
		},
		"hierarchy": hierarchy,
		"factory_task": {
			"finished": false,
			"onboarding_finished": true,
			"title": "阵营成形：%s" % _faction_phase_title(phase),
			"lesson": "%s属于你的%s路线；每一步都由当前存档事实恢复。" % [
				role_name,
				faction_name,
			],
			"cta_label": cta_label,
			"target": target,
			"stage_id": stage_id,
			"hero_id": hero_id,
			"archetype_id": archetype_id,
			"progress": 0,
			"target_value": 1,
			"completed": false,
			"claimed": true,
			"objectives": [{
				"id": "form_faction_%s" % phase,
				"label": small,
				"completed": false,
			}],
		},
	}


static func _faction_phase_title(phase: String) -> String:
	var titles := {
		"research": "研发新角色",
		"formation": "建立阵营编队",
		"prove_one_star": "证明核心打法",
		"star": "解锁2★质变",
		"breakthrough": "突破第二章",
	}
	return String(titles.get(phase, "形成阵营"))


static func _title_view(
	no_clears: bool,
	campaign_complete: bool,
	chapter_one_cleared: int,
	stage_config: Dictionary,
	report: Dictionary,
	needs_growth: bool,
	challenge_gap: int
) -> Dictionary:
	if no_clears:
		return {
			"primary_label": "唤醒 Gman · 启动反攻",
			"objective": "当前目标 · 摧毁联盟前哨 1-1",
		}
	if campaign_complete:
		return {
			"primary_label": "重返前线",
			"objective": "五章战役已完成，继续无尽攻城",
		}
	if chapter_one_cleared >= CHAPTER_ONE_STAGE_IDS.size() and needs_growth:
		var chapter_copy := _chapter_campaign_copy(stage_config)
		return {
			"primary_label": "返回指挥室",
			"objective": "%s备战 · 还差 %d 战力到挑战线" % [
				String(chapter_copy["chapter_name"]),
				challenge_gap,
			],
		}
	var action := report.get("next_action", {}) as Dictionary
	return {
		"primary_label": "返回指挥室",
		"objective": (
			"下一行动 · %s" % String(action.get("title", "继续观察"))
			if chapter_one_cleared >= CHAPTER_ONE_STAGE_IDS.size()
			else "前线等待命令 · %s" % String(stage_config.get("display_name", "未知前线"))
		),
	}


static func _onboarding_hierarchy(onboarding: Dictionary, cleared: Array) -> Dictionary:
	var first_incomplete: Dictionary = {}
	for objective_value in onboarding.get("objectives", []):
		var objective := objective_value as Dictionary
		if not bool(objective.get("completed", false)):
			first_incomplete = objective
			break
	var finished := bool(onboarding.get("finished", false))
	return {
		"macro": (
			"推进第二章，扩大战争工厂"
			if cleared.has("stage_1_5")
			else "摧毁灰镜核心，完成第一章"
		),
		"medium": String(onboarding.get("title", "建立下一条战线")),
		"small": (
			"选择下一座未占领城镇"
			if finished
			else String(first_incomplete.get("label", onboarding.get("cta_label", "继续推进")))
		),
		"hurdle": ObjectiveHurdleCatalogScript.hurdle_view(String(onboarding.get("task_id", ""))),
		"finished": finished,
		"actionable": not finished,
		"cta_label": String(onboarding.get("cta_label", "继续")),
		"target": String(onboarding.get("target", "expedition")),
		"stage_id": String(onboarding.get("stage_id", "")),
	}


static func _faction_recruit_hierarchy() -> Dictionary:
	return {
		"macro": "形成自己的马桶人阵营",
		"medium": "第二阶段：接收阵营起手信号",
		"small": "领取免费十连，选择优先研发的新马桶人",
		"hurdle": {
			"scale": "中目标",
			"title": "军团扩编",
			"reason": "首章基础三人已经证明核心职责；下一步由抽取结果形成不同玩家的阵营路线。",
			"recovery": "免费十连不消耗招募券，并保证至少一名新型号和一次对应专属碎片。",
		},
		"finished": true,
		"actionable": true,
		"cta_label": "领取阵营起手十连",
		"target": "legion",
		"stage_id": "stage_2_1",
	}


static func _faction_recruit_factory_task() -> Dictionary:
	return {
		"finished": false,
		"onboarding_finished": true,
		"title": "阵营成形：接收起手信号",
		"lesson": "免费十连保证新型号与其重复碎片；先看抽取结果，再决定研发和升星路线。",
		"cta_label": "领取阵营起手十连",
		"target": "legion",
		"stage_id": "stage_2_1",
		"progress": 0,
		"target_value": 1,
		"completed": false,
		"claimed": true,
		"objectives": [{
			"id": "claim_faction_starter",
			"label": "领取免费十连，选择优先研发的新马桶人",
			"completed": false,
		}],
	}


static func _next_chapter_hierarchy(
	stage_id: String,
	stage_config: Dictionary,
	needs_growth: bool,
	challenge_gap: int
) -> Dictionary:
	var chapter_copy := _chapter_campaign_copy(stage_config)
	return {
		"macro": String(chapter_copy["macro"]),
		"medium": String(chapter_copy["medium"]),
		"small": (
			"将军团提升至挑战线（还差 %d 战力）" % challenge_gap
			if needs_growth
			else "侦察并准备进攻 %s" % String(stage_config.get("display_name", stage_id))
		),
		"hurdle": {
			"scale": "中坎",
			"title": String(chapter_copy["hurdle_title"]),
			"reason": String(chapter_copy["hurdle_reason"]),
			"recovery": (
				String(chapter_copy["growth_recovery"])
				if needs_growth
				else String(chapter_copy["recon_recovery"])
			),
		},
		"finished": true,
		"actionable": true,
		"cta_label": (
			"先培养军团"
			if needs_growth
			else "侦察 %s" % String(stage_config.get("display_name", stage_id))
		),
		"target": "legion" if needs_growth else "map",
		"stage_id": stage_id,
	}


static func _next_chapter_factory_task(
	stage_id: String,
	stage_config: Dictionary,
	needs_growth: bool,
	challenge_gap: int
) -> Dictionary:
	var chapter_copy := _chapter_campaign_copy(stage_config)
	return {
		"finished": false,
		"onboarding_finished": true,
		"title": "%s备战：%s" % [
			String(chapter_copy["chapter_name"]),
			String(chapter_copy["front_name"]),
		],
		"lesson": String(chapter_copy["lesson"]),
		"cta_label": (
			"先培养军团"
			if needs_growth
			else "侦察 %s" % String(stage_config.get("display_name", stage_id))
		),
		"target": "legion" if needs_growth else "map",
		"stage_id": stage_id,
		"progress": 0 if needs_growth else 1,
		"target_value": 1,
		"completed": false,
		"claimed": true,
		"objectives": [{
			"id": "reach_next_challenge_line",
			"label": (
				"将军团提升至挑战线（还差 %d 战力）" % challenge_gap
				if needs_growth
				else "侦察并准备进攻 %s" % String(stage_config.get("display_name", stage_id))
			),
			"completed": false,
		}],
	}


static func _chapter_campaign_copy(stage_config: Dictionary) -> Dictionary:
	var chapter := int(stage_config.get("chapter", 2))
	var chapters := {
		2: {
			"chapter_name": "第二章",
			"front_name": "震荡封锁线",
			"macro": "推进第二章，扩大战争工厂",
			"medium": "第二章：突破震荡封锁线",
			"hurdle_title": "第二章声波防线",
			"hurdle_reason": "首章队伍已证明基础职责，但第二章要求更高的永久成长与后勤供给。",
			"growth_recovery": "先培养现有军团；所有首章资产保留，不需要付费解锁路线。",
			"recon_recovery": "先侦察敌方声波结构，再决定阵容和技能时机。",
			"lesson": "首章资产全部保留；先跨过新的成长坎，再侦察声波防线。",
		},
		3: {
			"chapter_name": "第三章",
			"front_name": "电视控制区",
			"macro": "破解电视控制链，扩展阵营组合",
			"medium": "第三章：保护核心成员脱离点杀",
			"hurdle_title": "电视控制与点杀链",
			"hurdle_reason": "第二章证明了2★核心；第三章会控制关键成员并制造连续点杀窗口。",
			"growth_recovery": "优先培养维修、装甲或干扰成员，保住被控制的阵营核心。",
			"recon_recovery": "先侦察控制目标与爆发窗口，再决定保护、打断或召唤牵制路线。",
			"lesson": "阵营核心已经成形；第三章要求围绕它补充续航与反控制职责。",
		},
		4: {
			"chapter_name": "第四章",
			"front_name": "联合精英防线",
			"macro": "击穿联合精英防线，完善六人阵营",
			"medium": "第四章：处理护盾、集火与多线压力",
			"hurdle_title": "联合精英协同",
			"hurdle_reason": "敌军开始把护盾、集火和多线结构组合起来，单一核心无法包办全部职责。",
			"growth_recovery": "补齐破盾、承伤与牵制角色，并把资源集中到实际参战成员。",
			"recon_recovery": "先辨认本关主压力，再从爆发、续航或增殖路线中选择反制。",
			"lesson": "用已形成的阵营核心带动第二、第三职责，而不是只追逐最高战力数字。",
		},
		5: {
			"chapter_name": "第五章",
			"front_name": "联盟总指挥部",
			"macro": "摧毁联盟总指挥部，完成五章战役",
			"medium": "第五章：证明完整阵营的最终解法",
			"hurdle_title": "联盟最终防御协议",
			"hurdle_reason": "最终章连续复用此前的控制、护盾、炮击和结构压力，检验完整阵营理解。",
			"growth_recovery": "只强化当前阵营的关键短板；不需要推翻已经验证的核心路线。",
			"recon_recovery": "读取敌方组合后安排技能顺序，把每个成员的职责用在明确窗口。",
			"lesson": "五章终局检验阵营组合与技能时机；失败保留全部永久成长。",
		},
	}
	return (chapters.get(chapter, chapters[2]) as Dictionary).duplicate(true)


static func _count_cleared(cleared: Array, stage_ids: Array[String]) -> int:
	var count := 0
	for stage_id in stage_ids:
		if cleared.has(stage_id):
			count += 1
	return count
