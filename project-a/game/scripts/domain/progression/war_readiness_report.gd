class_name WarReadinessReport
extends RefCounted

const CombatPowerScript := preload("res://game/scripts/domain/progression/combat_power.gd")


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
	if (
		stage_id == "stage_1_4"
		and int(state.attempt_counters.get(stage_id, 0)) == 0
		and not cleared_stages.has(stage_id)
	):
		next_action = {
			"id": "discover",
			"title": "先试探炮台防线",
			"detail": "这是设计好的首次情报战；先亲自观察单人职责缺口，失败不会损失永久资产。",
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
		"next_action": next_action,
	}


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
	var names := {"porcelain": "陶瓷", "parts": "零件", "sludge": "能源"}
	var result := {"id": "porcelain", "label": "陶瓷", "percent": 100}
	for material_id in names.keys():
		var capacity := maxi(1, int(state.factory.capacities.get(material_id, 1)))
		var current := maxi(0, int(state.factory.materials.get(material_id, 0)))
		var percent := clampi(int(current * 100 / capacity), 0, 100)
		if percent < int(result["percent"]):
			result = {"id": material_id, "label": names[material_id], "percent": percent}
	return result


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
