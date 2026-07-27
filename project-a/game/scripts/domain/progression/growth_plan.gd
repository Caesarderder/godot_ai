class_name GrowthPlan
extends RefCounted

const CombatPowerScript := preload("res://game/scripts/domain/progression/combat_power.gd")
const EconomyValuationScript := preload("res://game/scripts/domain/economy/economy_valuation.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const LogisticsServiceScript := preload("res://game/scripts/domain/factory/logistics_service.gd")
const HeroProgressionScript := preload("res://game/scripts/domain/progression/hero_progression.gd")


static func for_stage(state: RefCounted, stage_config: Dictionary) -> Dictionary:
	var team_power := CombatPowerScript.formation_power(state)
	var minimum_power := int(stage_config.get("minimum_power", 0))
	var recommended_power := int(stage_config.get("recommended_power", minimum_power))
	var target_power := recommended_power if team_power >= minimum_power else minimum_power
	var gap := maxi(0, target_power - team_power)
	var result := {
		"team_power": team_power,
		"minimum_power": minimum_power,
		"recommended_power": recommended_power,
		"target_power": target_power,
		"power_gap": gap,
		"estimated_gold_value": 0,
		"estimate_label": "无需新增金币投入",
		"action": "ready",
		"title": "战力已达到挑战线",
		"detail": "当前军团可以出征；推荐战力仍代表更稳定的通关条件。",
		"hero_id": "",
		"recipe_id": "",
	}
	if gap <= 0:
		return result
	var stage_id := String(stage_config.get("stage_id", ""))
	if stage_id == "stage_1_4" and int(state.attempt_counters.get(stage_id, 0)) == 0:
		result["action"] = "challenge"
		result["title"] = "先侦察炮台防线"
		result["detail"] = "本次首战用于发现真实威胁；失败后回到研究所，研发 1-2、1-3 首通获得的装甲与冲锋图纸。"
		result["estimated_gold_value"] = 0
		result["estimate_label"] = "无需新增金币投入"
		return result
	var merge := _best_merge(state)
	if not merge.is_empty():
		result["action"] = "merge"
		result["title"] = "优先升星 %s" % String(merge["display_name"])
		result["detail"] = "已有可安全合成的 3 个同星同原型单位；本次不新增金币成本，并会保留合法阵容。"
		result["estimated_gold_value"] = 0
		result["estimate_label"] = "无需新增金币投入"
		return result
	var active_research := state.factory.blueprint_research as Dictionary
	if not active_research.is_empty():
		var active_recipe_id := String(active_research.get("recipe_id", ""))
		var active_recipe := FactoryCatalogScript.recipe(active_recipe_id)
		result["action"] = "research_wait"
		result["recipe_id"] = active_recipe_id
		result["title"] = "完成 %s 研究" % String(active_recipe.get("display_name", active_recipe_id))
		result["detail"] = "博士已有研究任务；先等待并领取结果，再安排下一张图纸。"
		result["estimated_gold_value"] = 0
		result["estimate_label"] = "无需新增金币投入"
		return result
	var research := _best_research(state, stage_config)
	if not research.is_empty():
		result["action"] = "research"
		result["recipe_id"] = String(research["recipe_id"])
		result["title"] = "研究 %s" % String(research["display_name"])
		result["detail"] = "已有价值约 %d 金的设计图；研究只消耗时间，不重复计算图纸资产成本。" % int(research["blueprint_value_gold"])
		result["estimated_gold_value"] = 0
		result["estimate_label"] = "无需新增金币投入"
		return result
	var production := _best_production(state, stage_config)
	if not production.is_empty():
		result["action"] = "produce"
		result["recipe_id"] = String(production["recipe_id"])
		result["title"] = "生产 %s" % String(production["display_name"])
		result["detail"] = "当前缺少可继续训练的主力，按本关机制补充新单位或升星素材。"
		result["estimated_gold_value"] = int(production["cost_gold"])
		result["estimate_label"] = "消耗已有材料≈%d金价值" % int(result["estimated_gold_value"])
		return result
	var upgrade := _best_upgrade(state)
	if not upgrade.is_empty():
		var coin_cost := int(upgrade["coin_cost"])
		var gain := maxi(1, int(upgrade["power_gain"]))
		var missing_coin := maxi(0, coin_cost - int(state.economy.toilet_coins))
		var missing_xp := maxi(0, int(upgrade["xp_required"]) - int(upgrade["xp_current"]))
		if missing_coin > 0 or missing_xp > 0:
			result["action"] = "collect"
			result["hero_id"] = String(upgrade["hero_id"])
			result["title"] = "补足 %s 的升级条件" % String(upgrade["display_name"])
			result["detail"] = "升到 L%d 预计 +%d 战力；还缺出战经验%d、金币%d。" % [
				int(upgrade["target_level"]),
				gain,
				missing_xp,
				missing_coin,
			]
			result["estimated_gold_value"] = 0
			result["estimate_label"] = "出战经验与训练金币分别校验"
			return result
		result["action"] = "upgrade"
		result["hero_id"] = String(upgrade["hero_id"])
		result["title"] = "训练 %s" % String(upgrade["display_name"])
		result["detail"] = "出战经验已达标；支付金币%d升到 L%d，预计 +%d 战力。" % [
			coin_cost,
			int(upgrade["target_level"]),
			gain,
		]
		result["estimated_gold_value"] = 0
		result["estimate_label"] = "等级成长不消耗工业材料"
		return result
	result["action"] = "collect"
	result["title"] = "先获取永久成长资源"
	result["detail"] = "当前没有可立即执行的培养；攻城获取马桶币，工厂提供工业资源。"
	result["estimated_gold_value"] = 0
	result["estimate_label"] = "当前路径不足，暂无法可靠估价"
	return result


static func _best_upgrade(state: RefCounted) -> Dictionary:
	var best: Dictionary = {}
	var best_efficiency := -1
	for hero_id in state.formation.hero_ids():
		var hero: RefCounted = state.hero_by_id(String(hero_id))
		var cost := LogisticsServiceScript.hero_upgrade_cost(hero)
		if cost.is_empty():
			continue
		var before := CombatPowerScript.hero_power(hero)
		var preview: RefCounted = hero.deep_clone()
		HeroProgressionScript.upgrade_to_level(preview, int(cost["target_level"]))
		var gain := CombatPowerScript.hero_power(preview) - before
		var efficiency := int(gain * 1000 / maxi(1, int(cost["coin_cost"])))
		if efficiency > best_efficiency:
			best_efficiency = efficiency
			best = {
				"hero_id": String(hero.hero_id),
				"display_name": String(hero.display_name),
				"power_gain": gain,
				"coin_cost": int(cost["coin_cost"]),
				"xp_current": int(cost["xp_current"]),
				"xp_required": int(cost["xp_required"]),
				"target_level": int(cost["target_level"]),
			}
	return best


static func _best_merge(state: RefCounted) -> Dictionary:
	var groups: Dictionary = {}
	var deployed_ids: Array[String] = state.formation.hero_ids()
	for hero in state.roster:
		if String(hero.archetype_id) == "gman" or int(hero.star) >= 5:
			continue
		var key := "%s:%d" % [String(hero.archetype_id), int(hero.star)]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(hero)
	for key in groups.keys():
		var heroes := groups[key] as Array
		if heroes.size() < 3:
			continue
		var deployed_in_group := 0
		for hero in heroes:
			if deployed_ids.has(String(hero.hero_id)):
				deployed_in_group += 1
		var nondeployed_in_group := heroes.size() - deployed_in_group
		var consumed_nondeployed := mini(3, nondeployed_in_group)
		var consumed_deployed := 3 - consumed_nondeployed
		var vacancies_after_merged := maxi(0, consumed_deployed - 1)
		var total_nondeployed := maxi(0, state.roster.size() - deployed_ids.size())
		var remaining_nondeployed := total_nondeployed - consumed_nondeployed
		if remaining_nondeployed < vacancies_after_merged:
			continue
		var exemplar: RefCounted = heroes[0]
		return {
			"display_name": String(exemplar.display_name).split(" · ")[0],
		}
	return {}


static func _best_production(state: RefCounted, stage_config: Dictionary) -> Dictionary:
	if state.factory.production_queue.size() >= 3:
		return {}
	var candidates: Array = (stage_config.get("recommended_recipe_ids", []) as Array).duplicate()
	candidates.append_array(stage_config.get("fallback_recipe_ids", []))
	for recipe_id_value in candidates:
		var recipe_id := String(recipe_id_value)
		if not bool(state.factory.blueprints.get(recipe_id, false)):
			continue
		var recipe := FactoryCatalogScript.recipe(recipe_id)
		if state.factory.can_spend(recipe.get("cost", {}) as Dictionary):
			return {
				"recipe_id": recipe_id,
				"display_name": String(recipe.get("display_name", recipe_id)),
				"cost_gold": EconomyValuationScript.recipe_cost_gold(recipe_id),
			}
	return {}


static func _best_research(state: RefCounted, stage_config: Dictionary) -> Dictionary:
	var candidates: Array = (stage_config.get("recommended_recipe_ids", []) as Array).duplicate()
	candidates.append_array(stage_config.get("fallback_recipe_ids", []))
	for recipe_id_value in candidates:
		var recipe_id := String(recipe_id_value)
		if not bool(state.factory.discovered_blueprints.get(recipe_id, false)):
			continue
		var recipe := FactoryCatalogScript.recipe(recipe_id)
		return {
			"recipe_id": recipe_id,
			"display_name": String(recipe.get("display_name", recipe_id)),
			"blueprint_value_gold": EconomyValuationScript.blueprint_value_gold(recipe_id),
		}
	return {}
