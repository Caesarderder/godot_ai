class_name AchievementCatalog
extends RefCounted

const QuestCatalogScript := preload("res://game/scripts/domain/quest/quest_catalog.gd")

const MAX_GENERATION: int = 0
const ALLOWED_CATEGORIES: Array[String] = ["campaign", "factory", "cultivation", "collection"]
const ALLOWED_METRICS: Array[String] = [
	"cleared_stages",
	"boss_clears",
	"stage_5_5_cleared",
	"production_started",
	"production_claimed",
	"archetype_count",
	"max_hero_level",
	"formation_level_3_count",
	"roster_star_2_count",
	"roster_star_3_count",
	"first_victory_salvage_earned",
	"salvage_exchange_count",
	"salvage_offer_kinds",
	"war_merit_rank",
	"war_merit",
]

const DEFINITIONS: Array[Dictionary] = [
	{"achievement_id": "ach.campaign.clear_1", "category": "campaign", "metric": "cleared_stages", "target": 1, "title": "攻破第一处联盟据点", "reward": {"merit": 40, "gold": 10, "xp_books": 0}},
	{"achievement_id": "ach.campaign.clear_5", "category": "campaign", "metric": "cleared_stages", "target": 5, "title": "清空第一条街区战线", "reward": {"merit": 80, "gold": 20, "xp_books": 0}},
	{"achievement_id": "ach.campaign.clear_25", "category": "campaign", "metric": "cleared_stages", "target": 25, "title": "完成第一幕攻城", "reward": {"merit": 240, "gold": 80, "xp_books": 2}},
	{"achievement_id": "ach.boss.destroy_1", "category": "campaign", "metric": "boss_clears", "target": 1, "title": "击破首个联盟核心", "reward": {"merit": 80, "gold": 20, "xp_books": 0}},
	{"achievement_id": "ach.boss.destroy_5", "category": "campaign", "metric": "boss_clears", "target": 5, "title": "五座联盟核心全毁", "reward": {"merit": 260, "gold": 80, "xp_books": 2}},
	{"achievement_id": "ach.boss.last_gate", "category": "campaign", "metric": "stage_5_5_cleared", "target": 1, "title": "审判之门倒塌", "reward": {"merit": 200, "gold": 0, "xp_books": 0}},
	{"achievement_id": "ach.factory.start_3", "category": "factory", "metric": "production_started", "target": 3, "title": "工厂轰鸣三次", "reward": {"merit": 40, "gold": 10, "xp_books": 0}},
	{"achievement_id": "ach.factory.claim_6", "category": "factory", "metric": "production_claimed", "target": 6, "title": "补齐一支预备队", "reward": {"merit": 80, "gold": 20, "xp_books": 0}},
	{"achievement_id": "ach.factory.all_archetypes", "category": "factory", "metric": "archetype_count", "target": 8, "title": "八类单位全收集", "reward": {"merit": 180, "gold": 0, "xp_books": 1}},
	{"achievement_id": "ach.training.level_3", "category": "cultivation", "metric": "max_hero_level", "target": 3, "title": "首名单位升至三级", "reward": {"merit": 60, "gold": 20, "xp_books": 0}},
	{"achievement_id": "ach.training.level_5", "category": "cultivation", "metric": "max_hero_level", "target": 5, "title": "首名单位满级", "reward": {"merit": 120, "gold": 0, "xp_books": 1}},
	{"achievement_id": "ach.training.squad_ready", "category": "cultivation", "metric": "formation_level_3_count", "target": 6, "title": "六名三级主力上阵", "reward": {"merit": 180, "gold": 60, "xp_books": 0}},
	{"achievement_id": "ach.merge.first_2star", "category": "cultivation", "metric": "roster_star_2_count", "target": 1, "title": "第一名二星单位", "reward": {"merit": 60, "gold": 20, "xp_books": 0}},
	{"achievement_id": "ach.merge.three_2star", "category": "cultivation", "metric": "roster_star_2_count", "target": 3, "title": "二星小队成型", "reward": {"merit": 120, "gold": 30, "xp_books": 0}},
	{"achievement_id": "ach.merge.first_3star", "category": "cultivation", "metric": "roster_star_3_count", "target": 1, "title": "第一名三星单位", "reward": {"merit": 180, "gold": 0, "xp_books": 1}},
	{"achievement_id": "ach.merge.elite_core", "category": "cultivation", "metric": "roster_star_3_count", "target": 3, "title": "三星精锐核心成型", "reward": {"merit": 260, "gold": 80, "xp_books": 2}},
	{"achievement_id": "ach.salvage.earn_25", "category": "collection", "metric": "first_victory_salvage_earned", "target": 25, "title": "累计回收二十五份残骸", "reward": {"merit": 60, "gold": 10, "xp_books": 0}},
	{"achievement_id": "ach.salvage.exchange_1", "category": "collection", "metric": "salvage_exchange_count", "target": 1, "title": "第一次兑换联盟残骸", "reward": {"merit": 60, "gold": 0, "xp_books": 0}},
	{"achievement_id": "ach.salvage.exchange_5", "category": "collection", "metric": "salvage_exchange_count", "target": 5, "title": "完成五次残骸兑换", "reward": {"merit": 140, "gold": 40, "xp_books": 0}},
	{"achievement_id": "ach.salvage.clean_recycler", "category": "collection", "metric": "salvage_offer_kinds", "target": 3, "title": "三类残骸补给全兑换", "reward": {"merit": 160, "gold": 0, "xp_books": 0}},
	{"achievement_id": "ach.merit.rank_5", "category": "collection", "metric": "war_merit_rank", "target": 5, "title": "战功等级五", "reward": {"merit": 40, "gold": 0, "xp_books": 0}},
	{"achievement_id": "ach.merit.rank_15", "category": "collection", "metric": "war_merit_rank", "target": 15, "title": "战功等级十五", "reward": {"merit": 100, "gold": 30, "xp_books": 0}},
	{"achievement_id": "ach.merit.rank_30", "category": "collection", "metric": "war_merit_rank", "target": 30, "title": "战功等级三十", "reward": {"merit": 200, "gold": 0, "xp_books": 0}},
	{"achievement_id": "ach.merit.after_cap_1000", "category": "collection", "metric": "war_merit", "target": 20140, "title": "满阶后再立千功", "reward": {"merit": 200, "gold": 0, "xp_books": 0}},
]


static func all() -> Array[Dictionary]:
	return DEFINITIONS.duplicate(true)


static func definitions() -> Array[Dictionary]:
	return all()


static func ids() -> Array[String]:
	var values: Array[String] = []
	for definition in DEFINITIONS:
		values.append(String(definition["achievement_id"]))
	return values


static func definition(achievement_id: String) -> Dictionary:
	for item in DEFINITIONS:
		if String(item["achievement_id"]) == achievement_id:
			return item.duplicate(true)
	return {}


static func reward_for(achievement_id: String) -> Dictionary:
	var item := definition(achievement_id)
	return (item.get("reward", {}) as Dictionary).duplicate(true)


static func validate_definitions() -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for item in DEFINITIONS:
		var achievement_id := String(item.get("achievement_id", ""))
		if achievement_id.is_empty():
			errors.append("achievement_id is required")
		elif seen.has(achievement_id):
			errors.append("duplicate achievement_id %s" % achievement_id)
		seen[achievement_id] = true
		if not achievement_id.begins_with("ach."):
			errors.append("%s must use the ach. namespace" % achievement_id)
		for required in ["category", "metric", "target", "title", "reward"]:
			if not item.has(required):
				errors.append("%s missing %s" % [achievement_id, required])
		if not ALLOWED_CATEGORIES.has(String(item.get("category", ""))):
			errors.append("%s category is unsupported" % achievement_id)
		if not ALLOWED_METRICS.has(String(item.get("metric", ""))):
			errors.append("%s metric is unsupported" % achievement_id)
		if typeof(item.get("target", 0)) != TYPE_INT or int(item.get("target", 0)) <= 0:
			errors.append("%s target must be positive int" % achievement_id)
		for forbidden in ["daily", "weekly", "season", "starts_at", "ends_at", "expires_at", "reset_at"]:
			if item.has(forbidden):
				errors.append("%s contains FOMO field %s" % [achievement_id, forbidden])
		errors.append_array(QuestCatalogScript.validate_reward_definition(item.get("reward", {}), achievement_id))
	return errors
