class_name WarReadinessReport
extends RefCounted

const CombatPowerScript := preload("res://game/scripts/domain/progression/combat_power.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")


static func derive(state: RefCounted, stage_config: Dictionary) -> Dictionary:
	if state == null or stage_config.is_empty():
		return {}
	var full_power := 0
	var ready_power := 0
	var ready_count := 0
	var readiness_total := 0
	var lowest_readiness := 100
	var most_damaged_hero_id := ""
	var most_damaged_name := ""
	for hero_id in state.formation.hero_ids():
		var hero: RefCounted = state.hero_by_id(String(hero_id))
		if hero == null:
			continue
		var hero_power := CombatPowerScript.hero_power(hero)
		var readiness := 100
		full_power += hero_power
		ready_power += int(hero_power * readiness / 100)
		readiness_total += readiness
		if readiness > 0:
			ready_count += 1
		if readiness < lowest_readiness:
			lowest_readiness = readiness
			most_damaged_hero_id = String(hero.hero_id)
			most_damaged_name = String(hero.display_name)
	var formation_size: int = int(state.formation.hero_ids().size())
	var average_readiness: int = 0 if formation_size <= 0 else int(round(float(readiness_total) / formation_size))
	var recommended := maxi(1, int(stage_config.get("recommended_power", 1)))
	var minimum := maxi(1, int(stage_config.get("minimum_power", int(recommended * 0.85))))
	var ratio := float(ready_power) / float(recommended)
	var risk := _risk(ratio)
	var weakest_resource := _weakest_resource(state)
	var next_action := _next_action(
		ready_count,
		formation_size,
		lowest_readiness,
		ready_power,
		minimum,
		recommended,
		most_damaged_hero_id
	)
	var stage_id := String(stage_config.get("stage_id", ""))
	var cleared_stages := state.stage_progress.get("cleared_stages", []) as Array
	var formation_plan := _formation_plan(state, stage_config)
	if (
		int(stage_config.get("chapter", 1)) >= 2
		and not cleared_stages.has(stage_id)
		and String(formation_plan.get("status_id", "")) == "missing"
		and bool(formation_plan.get("can_prepare", false))
	):
		next_action = {
			"id": "formation",
			"title": "调整本关阵容",
			"detail": "仓库已有本关建议角色但尚未上阵；先换阵可让抽取与培养选择在战斗中得到验证。",
			"hero_id": "",
		}
	if stage_id == "stage_1_4" and not cleared_stages.has(stage_id):
		var attempts := int(state.attempt_counters.get(stage_id, 0))
		if attempts == 0:
			next_action = {
				"id": "discover",
				"title": "先试探炮台防线",
				"detail": "这是设计好的首次情报战；先亲自观察单人职责缺口，失败不会损失永久资产。",
				"hero_id": "",
			}
		elif int(state.factory.facilities.get("research_lab", 0)) <= 0:
			next_action = {
				"id": "research",
				"title": "建造研究所",
				"detail": "研究所应在开局完成建设；它会把关卡获得的设计图纸转化为永久援军。",
				"hero_id": "",
			}
		elif not (_has_archetype(state, "assault") and _has_archetype(state, "armored")):
			next_action = {
				"id": "research",
				"title": "研发冲锋与装甲图纸",
				"detail": "研究所已经就绪；依次研发 1-2、1-3 首通获得的两张图纸，完成后永久角色才会入列。",
				"hero_id": "",
			}
		elif not (
			_formation_has_archetype(state, "assault")
			and _formation_has_archetype(state, "armored")
		):
			next_action = {
				"id": "formation",
				"title": "把两名援军编入队伍",
				"detail": "永久援军已经到位；让装甲承伤、冲锋压制，再发动反攻。",
				"hero_id": "",
			}
		else:
			next_action = {
				"id": "attack",
				"title": "三人小队可以反攻",
				"detail": "装甲与冲锋已经入队；立即返回 1-4 验证新职责组合。",
				"hero_id": "",
			}
	return {
		"stage_id": stage_id,
		"stage_name": String(stage_config.get("display_name", "")),
		"cp_full": full_power,
		"cp_ready": ready_power,
		"recommended_power": recommended,
		"minimum_power": minimum,
		"power_gap": maxi(0, recommended - ready_power),
		"capability_ratio": ratio,
		"risk_id": String(risk["id"]),
		"risk_label": String(risk["label"]),
		"risk_detail": String(risk["detail"]),
		"ready_count": ready_count,
		"formation_size": formation_size,
		"average_readiness": average_readiness,
		"lowest_readiness": lowest_readiness if formation_size > 0 else 0,
		"repair_burden": 0,
		"most_damaged_hero_id": most_damaged_hero_id,
		"most_damaged_name": most_damaged_name,
		"weakest_resource_id": String(weakest_resource["id"]),
		"weakest_resource_label": String(weakest_resource["label"]),
		"weakest_resource_percent": int(weakest_resource["percent"]),
		"formation_plan": formation_plan,
		"next_action": next_action,
	}


static func _foundational_signal_claimed(state: RefCounted) -> bool:
	var claimed := state.onboarding.get("claimed", {}) as Dictionary
	return (
		claimed.has("reward.foundational_signal_ten")
		or claimed.has("reward.research_breakthrough_ten")
	)


static func _risk(ratio: float) -> Dictionary:
	if ratio < 0.80:
		return {"id": "extreme", "label": "极高风险", "detail": "建议先培养角色或升级工厂；失败不会造成永久损失。"}
	if ratio < 0.95:
		return {"id": "challenge", "label": "挑战", "detail": "可以放心试攻；失败只损失本次时间，不会削弱角色。"}
	if ratio < 1.10:
		return {"id": "target", "label": "目标区间", "detail": "强度接近目标线，适合通过阵容和技能时机突破。"}
	if ratio < 1.30:
		return {"id": "stable", "label": "稳定", "detail": "常规阵容应能稳定推进，可连续挑战关卡。"}
	return {"id": "overwhelming", "label": "碾压", "detail": "当前军团明显高于关卡需求，可快速回收战果。"}


static func _weakest_resource(state: RefCounted) -> Dictionary:
	var capacity := maxi(1, int(state.factory.capacities.get("porcelain", 1)))
	var current := maxi(0, int(state.factory.materials.get("porcelain", 0)))
	return {
		"id": "porcelain",
		"label": "工业材料",
		"percent": clampi(int(current * 100 / capacity), 0, 100),
	}


static func _next_action(
	ready_count: int,
	formation_size: int,
	lowest_readiness: int,
	ready_power: int,
	minimum_power: int,
	recommended_power: int,
	hero_id: String
) -> Dictionary:
	if ready_power < minimum_power:
		return {
			"id": "upgrade",
			"title": "培养军团并扩建后勤",
			"detail": "当前出征战力尚未达到挑战线；升级角色或研究技能更稳妥。",
			"hero_id": "",
		}
	if ready_power < recommended_power:
		return {
			"id": "challenge",
			"title": "可试攻，保留撤退余地",
			"detail": "已越过挑战线但低于稳定推荐值，关注战斗中的撤退时机。",
			"hero_id": "",
		}
	return {
		"id": "attack",
		"title": "军团已适合继续攻城",
		"detail": "当前战力和战备均达到推荐线，可以主动推进。",
		"hero_id": "",
	}


static func _has_archetype(state: RefCounted, archetype_id: String) -> bool:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			return true
	return false


static func _formation_has_archetype(state: RefCounted, archetype_id: String) -> bool:
	for hero_id in state.formation.hero_ids():
		var hero: RefCounted = state.hero_by_id(String(hero_id))
		if hero != null and String(hero.archetype_id) == archetype_id:
			return true
	return false


static func _formation_plan(state: RefCounted, stage_config: Dictionary) -> Dictionary:
	if int(stage_config.get("chapter", 1)) < 2:
		return {}
	var recommended := stage_config.get("recommended_recipe_ids", []) as Array
	var fallback := stage_config.get("fallback_recipe_ids", []) as Array
	if recommended.is_empty():
		return {}
	var deployed: Dictionary = {}
	for hero_id in state.formation.hero_ids():
		var hero: RefCounted = state.hero_by_id(String(hero_id))
		if hero != null:
			deployed[String(hero.archetype_id)] = true
	var primary_names: Array[String] = []
	var fallback_names: Array[String] = []
	var missing_names: Array[String] = []
	var owned_candidate := false
	for recipe_value in recommended:
		var recipe_id := String(recipe_value)
		var recipe := FactoryCatalogScript.recipe(recipe_id)
		var archetype_id := String(recipe.get("archetype_id", ""))
		if deployed.has(archetype_id):
			primary_names.append(_short_recipe_name(recipe_id))
		else:
			missing_names.append(_short_recipe_name(recipe_id))
			owned_candidate = owned_candidate or _has_archetype(state, archetype_id)
	for recipe_value in fallback:
		var recipe_id := String(recipe_value)
		var recipe := FactoryCatalogScript.recipe(recipe_id)
		var archetype_id := String(recipe.get("archetype_id", ""))
		if deployed.has(archetype_id):
			fallback_names.append(_short_recipe_name(recipe_id))
		else:
			owned_candidate = owned_candidate or _has_archetype(state, archetype_id)
	var status_id := "missing"
	if missing_names.is_empty():
		status_id = "covered"
	elif not primary_names.is_empty() or not fallback_names.is_empty():
		status_id = "partial"
	var covered_copy := "无"
	if not primary_names.is_empty():
		covered_copy = "、".join(primary_names)
	if not fallback_names.is_empty():
		covered_copy = "%s备选 %s" % [
			"" if covered_copy == "无" else "%s；" % covered_copy,
			"、".join(fallback_names),
		]
	return {
		"status_id": status_id,
		"covered_copy": covered_copy,
		"missing_copy": "无" if missing_names.is_empty() else "、".join(missing_names),
		"covered_count": primary_names.size(),
		"recommended_count": recommended.size(),
		"can_prepare": owned_candidate,
	}


static func _short_recipe_name(recipe_id: String) -> String:
	return String({
		"ordinary.assault": "冲锋",
		"ordinary.sonic": "音波",
		"flying.rocket": "火箭",
		"flying.bomber": "自爆",
		"heavy.armored": "装甲",
		"heavy.saw": "双锯",
		"special.repair": "维修",
		"special.parasite": "寄生",
	}.get(recipe_id, recipe_id))
