extends SceneTree

const GameState := preload("res://game/scripts/state/game_state.gd")
const CommandExecutor := preload("res://game/scripts/commands/command_executor.gd")
const FactoryCatalog := preload("res://game/scripts/domain/factory/factory_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	var state: RefCounted = GameState.create_new(20260726, 1000, false)
	_check(int(state.factory.facilities["research_lab"]) == 0, "研究所开局应锁定")
	_check(state.factory.blueprints.is_empty(), "开局不应预解锁马桶人蓝图")
	var executor := CommandExecutor.new(state, func(_candidate: RefCounted) -> bool: return true)

	var early_defeat := _execute(executor, "battle:early-defeat", "settle_battle", {
		"battle_id": "battle:early-defeat",
		"stage_id": "stage_1_1",
		"outcome": "defeat",
		"ticks": 30,
		"deployed_unit_ids": executor.state.formation.hero_ids(),
		"dead_unit_ids": [],
	})
	_check(bool(early_defeat.get("ok", false)), "早期战败应正常结算")
	_check(int(executor.state.factory.facilities["research_lab"]) == 0, "1-4 之前的失败不得提前解锁研究所")

	var defeat := _execute(executor, "battle:first-high-wall-defeat", "settle_battle", {
		"battle_id": "battle:first-high-wall-defeat",
		"stage_id": "stage_1_4",
		"outcome": "defeat",
		"ticks": 30,
		"deployed_unit_ids": executor.state.formation.hero_ids(),
		"dead_unit_ids": [],
	})
	_check(bool(defeat.get("ok", false)), "首次战败应成功结算：%s" % str(defeat))
	_check(int(executor.state.factory.facilities["research_lab"]) == 0, "首次战败只应开放资格，不得自动建立研究所")
	_check((defeat.get("event", {}) as Dictionary).get("eligible_facilities", []).has("research_lab"), "1-4 首败应开放研究所建造资格")
	_check(executor.state.factory.discovered_blueprints.is_empty(), "研究所建成前不得提前开放基础蓝图")
	var construct := _execute(executor, "construct:research-lab", "construct_facility", {
		"facility_id": "research_lab",
		"now_unix": 1000,
		"grid_x": 2,
		"grid_z": 1,
	})
	_check(bool(construct.get("ok", false)), "玩家应能在首败后主动建立研究所：%s" % str(construct))
	_check(int(executor.state.factory.facilities["research_lab"]) == 0, "建造命令只开始施工，不应立即落成")
	_check(not bool(_execute(executor, "construct:research-lab:early", "claim_facility_work", {"now_unix": 1074}).get("ok", false)), "研究所不得提前验收")
	_check(bool(_execute(executor, "construct:research-lab:claim", "claim_facility_work", {"now_unix": 1075}).get("ok", false)), "研究所到时后应可验收")
	_check(int(executor.state.factory.facilities["research_lab"]) == 1, "验收完成后研究所才应落成")
	_check(bool(executor.state.factory.discovered_blueprints.get("ordinary.assault", false)), "研究所建成后应提供冲锋基础蓝图")
	_check(bool(executor.state.factory.discovered_blueprints.get("heavy.armored", false)), "研究所建成后应提供装甲基础蓝图")
	_check(FactoryCatalog.recipes().size() == 8, "科技蓝图应列出全部八种马桶人")

	var roster_before: int = executor.state.roster.size()
	var unlock := _execute(executor, "blueprint:foundational:assault", "unlock_foundational_blueprint", {
		"recipe_id": "ordinary.assault",
		"now_unix": 1100,
	})
	_check(bool(unlock.get("ok", false)), "基础蓝图应可开始研发")
	_check(executor.state.roster.size() == roster_before, "开始研发时不应立即授予永久角色")
	_check(not bool(_execute(executor, "blueprint:assault:early", "claim_blueprint_research", {"now_unix": 1144}).get("ok", false)), "基础蓝图不得提前领取")
	var research_claim := _execute(executor, "blueprint:assault:claim", "claim_blueprint_research", {"now_unix": 1145})
	_check(bool(research_claim.get("ok", false)), "基础蓝图到时后应可领取")
	_check(executor.state.roster.size() == roster_before + 1, "领取完成的基础蓝图应授予一个永久角色")
	var hero_id := String((research_claim.get("event", {}) as Dictionary).get("hero_id", ""))
	_check(not hero_id.is_empty() and executor.state.hero_by_id(hero_id) != null, "授予角色应使用稳定 hero_id")

	var duplicate := _execute(executor, "blueprint:duplicate", "unlock_foundational_blueprint", {
		"recipe_id": "ordinary.assault",
		"now_unix": 1200,
	})
	_check(not bool(duplicate.get("ok", false)), "基础蓝图不得重复授予角色")
	_check(executor.state.roster.size() == roster_before + 1, "重复解锁不得复制永久角色")

	var deploy := _execute(executor, "formation:basic", "assign_formation_slot", {
		"slot": "troop_1",
		"hero_id": hero_id,
	})
	_check(bool(deploy.get("ok", false)), "基础马桶人应可通过编队命令上阵")
	_check(String(executor.state.formation.slots["troop_1"]) == hero_id, "编队槽应保存新角色 hero_id")
	var armored_unlock := _execute(executor, "blueprint:foundational:armored", "unlock_foundational_blueprint", {
		"recipe_id": "heavy.armored",
		"now_unix": 1200,
	})
	_check(bool(armored_unlock.get("ok", false)), "装甲基础蓝图应可开始研发")
	var armored_claim := _execute(executor, "blueprint:armored:claim", "claim_blueprint_research", {"now_unix": 1245})
	_check(bool(armored_claim.get("ok", false)), "装甲基础蓝图到时后应可领取")
	var armored_hero_id := String((armored_claim.get("event", {}) as Dictionary).get("hero_id", ""))
	var armored_deploy := _execute(executor, "formation:armored", "assign_formation_slot", {
		"slot": "troop_2",
		"hero_id": armored_hero_id,
	})
	_check(bool(armored_deploy.get("ok", false)), "装甲马桶人应可通过编队命令上阵")
	_check(executor.state.formation.hero_ids().size() == 3, "G-Man 与两个蓝图角色应组成三人编队")

	var second_defeat := _execute(executor, "battle:second-defeat", "settle_battle", {
		"battle_id": "battle:second-defeat",
		"stage_id": "stage_1_4",
		"outcome": "defeat",
		"ticks": 30,
		"deployed_unit_ids": executor.state.formation.hero_ids(),
		"dead_unit_ids": [],
	})
	_check(bool(second_defeat.get("ok", false)), "后续战败仍应正常结算")
	_check((second_defeat.get("event", {}) as Dictionary).get("eligible_facilities", []) == [], "后续战败不得重复触发研究所引导")
	_check(executor.state.validate().is_empty(), "完整引导链结束后状态不变量应成立")

	if failures.is_empty():
		print("RESEARCH ONBOARDING TESTS PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("RESEARCH ONBOARDING TESTS FAIL: %d" % failures.size())
		quit(1)


func _execute(executor: RefCounted, key: String, type: String, payload: Dictionary) -> Dictionary:
	return executor.execute({
		"command_id": key,
		"type": type,
		"payload": payload,
		"business_key": key,
		"expected_revision": executor.state.revision,
		"requested_at": 1000,
	})


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
