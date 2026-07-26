class_name CampaignObjectiveProjection
extends RefCounted

const ObjectiveHurdleCatalogScript := preload("res://game/scripts/content/objective_hurdle_catalog.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")
const WarReadinessReportScript := preload("res://game/scripts/domain/progression/war_readiness_report.gd")

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
	var hierarchy := _onboarding_hierarchy(onboarding, cleared)
	if onboarding_finished:
		hierarchy = _next_chapter_hierarchy(
			stage_id,
			stage_config,
			needs_growth,
			challenge_gap
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
		"title": _title_view(
			cleared.is_empty(),
			campaign_cleared >= StageCatalogScript.ACT1_STAGE_IDS.size(),
			chapter_one_cleared,
			stage_config,
			report,
			needs_growth,
			challenge_gap
		),
		"hierarchy": hierarchy,
		"factory_task": (
			_next_chapter_factory_task(
				stage_id,
				stage_config,
				needs_growth,
				challenge_gap
			)
			if onboarding_finished
			else onboarding
		),
	}


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
		return {
			"primary_label": "返回指挥室",
			"objective": "第二章备战 · 还差 %d 战力到挑战线" % challenge_gap,
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


static func _next_chapter_hierarchy(
	stage_id: String,
	stage_config: Dictionary,
	needs_growth: bool,
	challenge_gap: int
) -> Dictionary:
	return {
		"macro": "推进第二章，扩大战争工厂",
		"medium": "第二章：突破震荡封锁线",
		"small": (
			"将军团提升至挑战线（还差 %d 战力）" % challenge_gap
			if needs_growth
			else "侦察并准备进攻 %s" % String(stage_config.get("display_name", stage_id))
		),
		"hurdle": {
			"scale": "中坎",
			"title": "第二章声波防线",
			"reason": "首章队伍已证明基础职责，但第二章要求更高的永久成长与后勤供给。",
			"recovery": (
				"先培养现有军团；所有首章资产保留，不需要付费解锁路线。"
				if needs_growth
				else "先侦察敌方声波结构，再决定阵容和技能时机。"
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
	return {
		"finished": false,
		"onboarding_finished": true,
		"title": "第二章备战：震荡封锁线",
		"lesson": "首章资产全部保留；先跨过新的成长坎，再侦察声波防线。",
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


static func _count_cleared(cleared: Array, stage_ids: Array[String]) -> int:
	var count := 0
	for stage_id in stage_ids:
		if cleared.has(stage_id):
			count += 1
	return count
