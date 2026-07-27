class_name MetaCatalog
extends RefCounted

const PASS_MAX_LEVEL: int = 30
const PASS_MERIT_PER_LEVEL: int = 100
const COMMANDER_THRESHOLDS: Array[int] = [
	0, 40, 100, 180, 300, 450, 630, 840, 1080, 1350,
	1680, 2040, 2430, 2850, 3300, 3780, 4290, 4830, 5400, 6000,
	6650, 7340, 8070, 8840, 9500, 10500, 11300, 12150, 13050, 14000,
]

const DAILY: Array[Dictionary] = [
	{"id": "daily.collect", "title": "收取两座资源建筑", "metric": "facility_claims", "target": 2, "xp": 15, "merit": 10, "gold": 10},
	{"id": "daily.siege", "title": "完成一次城镇攻坚", "metric": "battles", "target": 1, "xp": 15, "merit": 10, "gold": 15},
	{"id": "daily.growth", "title": "完成一次永久成长", "metric": "growth_actions", "target": 1, "xp": 15, "merit": 15, "gold": 20},
]
const WEEKLY: Array[Dictionary] = [
	{"id": "weekly.siege_7", "title": "完成 7 次攻城", "metric": "battles", "target": 7, "xp": 50, "merit": 80, "tickets": 0},
	{"id": "weekly.win_4", "title": "赢得 4 次攻城", "metric": "victories", "target": 4, "xp": 50, "merit": 80, "tickets": 1},
	{"id": "weekly.collect_15", "title": "收取 15 次建筑", "metric": "facility_claims", "target": 15, "xp": 50, "merit": 80, "tickets": 0},
	{"id": "weekly.grow_3", "title": "完成 3 次培养", "metric": "cultivation_actions", "target": 3, "xp": 50, "merit": 80, "tickets": 0},
	{"id": "weekly.repair_4", "title": "完成 4 次角色培养", "metric": "cultivation_actions", "target": 4, "xp": 50, "merit": 80, "tickets": 1},
]
const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "meta.campaign.first", "title": "第一座城", "metric": "first_clears", "target": 1, "xp": 25, "tickets": 0},
	{"id": "meta.campaign.five", "title": "第一章战线", "metric": "first_clears", "target": 5, "xp": 60, "tickets": 1},
	{"id": "meta.campaign.ten", "title": "十城推进", "metric": "first_clears", "target": 10, "xp": 60, "tickets": 0},
	{"id": "meta.campaign.fifteen", "title": "战线中枢", "metric": "first_clears", "target": 15, "xp": 80, "tickets": 1},
	{"id": "meta.campaign.twenty", "title": "终局在望", "metric": "first_clears", "target": 20, "xp": 80, "tickets": 0},
	{"id": "meta.campaign.twenty_five", "title": "地球战役", "metric": "first_clears", "target": 25, "xp": 100, "tickets": 2},
	{"id": "meta.factory.claim_1", "title": "第一次入库", "metric": "facility_claims", "target": 1, "xp": 10, "tickets": 0},
	{"id": "meta.factory.claim_10", "title": "工厂轰鸣", "metric": "facility_claims", "target": 10, "xp": 25, "tickets": 0},
	{"id": "meta.factory.claim_30", "title": "稳定产线", "metric": "facility_claims", "target": 30, "xp": 40, "tickets": 0},
	{"id": "meta.factory.upgrade_1", "title": "第一次扩建", "metric": "facility_upgrades", "target": 1, "xp": 25, "tickets": 0},
	{"id": "meta.factory.upgrade_6", "title": "六次扩建", "metric": "facility_upgrades", "target": 6, "xp": 60, "tickets": 1},
	{"id": "meta.factory.upgrade_12", "title": "工业城区", "metric": "facility_upgrades", "target": 12, "xp": 80, "tickets": 0},
	{"id": "meta.legion.level_2", "title": "第一次强化", "metric": "max_hero_level", "target": 2, "xp": 10, "tickets": 0},
	{"id": "meta.legion.level_3", "title": "主力成型", "metric": "max_hero_level", "target": 3, "xp": 25, "tickets": 0},
	{"id": "meta.legion.level_5", "title": "五级主力", "metric": "max_hero_level", "target": 5, "xp": 60, "tickets": 1},
	{"id": "meta.legion.star_2", "title": "首次二星", "metric": "max_hero_star", "target": 2, "xp": 40, "tickets": 0},
	{"id": "meta.legion.star_3", "title": "首次三星", "metric": "max_hero_star", "target": 3, "xp": 80, "tickets": 1},
	{"id": "meta.legion.six", "title": "完整编队", "metric": "roster_size", "target": 6, "xp": 60, "tickets": 0},
	{"id": "meta.repair.first", "title": "首次培养", "metric": "cultivation_actions", "target": 1, "xp": 25, "tickets": 0},
	{"id": "meta.repair.three", "title": "成长起步", "metric": "cultivation_actions", "target": 3, "xp": 25, "tickets": 0},
	{"id": "meta.repair.five", "title": "主力强化", "metric": "cultivation_actions", "target": 5, "xp": 40, "tickets": 0},
	{"id": "meta.repair.ten", "title": "培养专家", "metric": "cultivation_actions", "target": 10, "xp": 60, "tickets": 1},
	{"id": "meta.repair.twenty", "title": "精锐军团", "metric": "cultivation_actions", "target": 20, "xp": 80, "tickets": 0},
	{"id": "meta.repair.thirty", "title": "完全体军团", "metric": "cultivation_actions", "target": 30, "xp": 100, "tickets": 1},
	{"id": "meta.collection.five", "title": "第五名永久英雄", "metric": "roster_size", "target": 5, "xp": 25, "tickets": 0},
	{"id": "meta.collection.six", "title": "六人军团", "metric": "roster_size", "target": 6, "xp": 40, "tickets": 1},
	{"id": "meta.collection.seven", "title": "战术替补", "metric": "roster_size", "target": 7, "xp": 60, "tickets": 0},
	{"id": "meta.collection.eight", "title": "八种选择", "metric": "roster_size", "target": 8, "xp": 80, "tickets": 1},
	{"id": "meta.collection.nine", "title": "全型军团", "metric": "roster_size", "target": 9, "xp": 100, "tickets": 1},
	{"id": "meta.collection.signal_10", "title": "十次信号响应", "metric": "recruit_draws", "target": 10, "xp": 40, "tickets": 0},
]


static func commander_level(xp: int) -> int:
	var level := 1
	for index in COMMANDER_THRESHOLDS.size():
		if xp >= COMMANDER_THRESHOLDS[index]:
			level = index + 1
	return mini(30, level)


static func pass_level(merit: int) -> int:
	return clampi(merit / PASS_MERIT_PER_LEVEL, 0, PASS_MAX_LEVEL)


static func pass_reward(level: int) -> Dictionary:
	if level < 1 or level > PASS_MAX_LEVEL:
		return {}
	var reward := {"toilet_coins": 30, "porcelain": 0, "recruit_tickets": 0, "hero_shards": 0}
	if level % 3 == 0:
		reward["porcelain"] = 30
	if level in [5, 10, 15, 20, 25, 30]:
		reward["recruit_tickets"] = 2
	if level in [8, 18, 28]:
		reward["hero_shards"] = int(reward["hero_shards"]) + 4
	if level in [7, 14, 21, 28]:
		reward["hero_shards"] = int(reward["hero_shards"]) + 4
	return reward


static func commander_reward(level: int) -> Dictionary:
	if level < 2 or level > 30:
		return {}
	var reward := {"toilet_coins": 20, "porcelain": 0, "recruit_tickets": 0, "hero_shards": 0}
	if level % 3 == 0:
		reward["porcelain"] = 24
	if level == 6:
		reward["porcelain"] = 56
	if level == 8:
		reward["recruit_tickets"] = 1
	if level == 10:
		reward["toilet_coins"] = 100
	if level == 15:
		reward["hero_shards"] = 4
	if level == 20:
		reward["recruit_tickets"] = 2
	if level == 25:
		reward["toilet_coins"] = 200
	if level == 30:
		reward["recruit_tickets"] = 3
		reward["hero_shards"] = 8
	return reward


static func unlocks(state: RefCounted) -> Dictionary:
	var cleared: Array = state.stage_progress.get("cleared_stages", [])
	var level := commander_level(int(state.meta_progression.commander_xp))
	return {
		"commander_level": level,
		"missions": level >= 2 and cleared.has("stage_1_1"),
		"achievements": level >= 3 and cleared.has("stage_1_2"),
			"recruitment": level >= 4 and cleared.has("stage_1_5"),
		"pass": level >= 5 and cleared.has("stage_1_5"),
		"weekly": level >= 10,
	}


static func mission_def(mission_id: String) -> Dictionary:
	for definition in DAILY + WEEKLY:
		if String(definition["id"]) == mission_id:
			return definition.duplicate(true)
	return {}


static func achievement_def(achievement_id: String) -> Dictionary:
	for definition in ACHIEVEMENTS:
		if String(definition["id"]) == achievement_id:
			return definition.duplicate(true)
	return {}
