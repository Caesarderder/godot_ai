extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/screens/main.tscn")
	for _frame in 8:
		await process_frame
	var main := current_scene
	var game: Node = main.get("game")
	var audio_director: Node = main.get("audio_director")
	if audio_director != null:
		audio_director.call("set_playback_enabled", false)
	game.reset_game(20260727, 1000)
	var state: RefCounted = game.current_state()
	state.factory.eligible_facilities["research_lab"] = true
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	_seed_foundational_research(main)
	await _wait_frames(3)
	state = game.current_state()
	var assault := _hero_for(state, "assault")
	var armored := _hero_for(state, "armored")
	assault.star = 2
	state.formation.slots["troop_1"] = armored.hero_id
	state.formation.slots["troop_2"] = assault.hero_id
	state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
	]
	state.stage_progress["highest_unlocked_stage"] = "stage_2_1"
	state.onboarding["active_index"] = 7
	state.meta_progression.commander_xp = 450
	state.economy.toilet_coins = 500
	state.economy.hero_shards = 20
	state.factory.materials = {"porcelain": 100, "parts": 0, "sludge": 0}
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_1_5",
			"next_stage_id": "stage_2_1",
			"reward": {"gold": 58},
			"hero_shards": 16,
			"onboarding_settlement": {
				"task_id": "operation.chapter_boss",
				"next_index": 7,
				"auto_settled": true,
			},
		},
	})
	main.set("last_battle_runtime_result", {
		"ticks": 385,
		"structures_destroyed": 7,
		"enemies_defeated": 8,
		"cannon_hit_count": 1,
		"cannon_suppressed_count": 4,
		"ally_damage_dealt_by_unit": {assault.hero_id: 1840},
	})
	main.call("_show_result")
	await _wait_frames(4)
	_check(_tree_has_text(main, "第一章完成 · 灰镜核心已摧毁"), "chapter boss gets a distinct completion title")
	_check(_tree_has_text(main, "你的成长选择通过实战验证"), "chapter result closes the player-choice promise")
	_check(_tree_has_text(main, "冲锋压炮 4 次"), "assault mastery proof uses runtime cannon facts")
	_check(_tree_has_text(main, "首章解锁 · 第2章战线 · 信号招募 · 免费战役战令"), "completion lists only actual unlocked systems")
	_check(_tree_has_text(main, "首章训练闭环达成"), "the seven-action onboarding loop visibly settles")
	var faction_recruit := _button_with_text(main, "领取阵营起手十连")
	_check(faction_recruit != null, "completion exposes the faction-starter recruitment goal")
	if faction_recruit != null:
		faction_recruit.pressed.emit()
		await _wait_frames(4)
	_check(String(main.get("legion_tab")) == "recruit", "faction CTA lands on recruitment")
	_check(_tree_has_text(main, "阵营起手十连"), "faction CTA opens recruitment and explains the starter draw")
	var free_ten := main.find_child("FoundationalSignalTenButton", true, false) as Button
	_check(free_ten != null, "faction recruitment exposes the actual free ten-pull")
	if free_ten != null:
		free_ten.pressed.emit()
		await _wait_frames(4)
	_check(
		main.find_child("RecruitFactionCoreChoice", true, false) != null,
		"post-ten-pull first asks the player to choose their faction identity"
	)
	var core_choice := _button_with_text(main, "作为阵营核心")
	_check(core_choice != null, "chapter completion exposes an executable faction-core choice")
	if core_choice != null:
		core_choice.pressed.emit()
		await _wait_frames(4)
	main.set("legion_tab", "roster")
	main.call("_show_legion")
	await _wait_frames(4)
	_check(main.find_child("LegionFormationTab", true, false) != null, "post-chapter player can still open the legion voluntarily")
	_check(
		main.find_child("LegionContentScroll_roster", true, false) != null,
		"chapter-two growth opens permanent hero growth instead of an unrelated formation overview"
	)
	_check(
		main.find_child("CultivationAction_star", true, false) != null,
		"post-chapter roster exposes permanent character star growth"
	)

	main.call("_show_goals")
	await _wait_frames(4)
	_check(_tree_has_text(main, "用自己的角色池形成"), "post-ten-pull goals replace generic chapter growth with faction identity")
	_check(_tree_has_text(main, "阵营核心"), "post-ten-pull goals preserve the drawn faction core")
	_check(_tree_has_text(main, "图纸研发为永久角色"), "post-ten-pull goals name the immediate research gap")
	var goal_growth := main.find_child("GoalHierarchyPrimaryCTA", true, false) as Button
	_check(goal_growth != null and goal_growth.text.contains("研发"), "post-ten-pull goals retain one executable research action")
	if goal_growth != null:
		goal_growth.pressed.emit()
		await _wait_frames(4)
	_check(main.find_child("BlueprintScreen", true, false) != null, "post-ten-pull goal action opens the exact blueprint system")

	main.call("_show_title")
	await _wait_frames(4)
	_check(_tree_has_text(main, "阵营成形"), "returning title restores the same faction journey")
	var resume := _button_with_text(main, "研发")
	_check(resume != null, "returning chapter-one save names its exact faction action")
	if resume != null:
		resume.pressed.emit()
		await _wait_frames(4)
	_check(_tree_has_text(main, "阵营成形：研发新角色"), "resumed factory restores the faction research phase")
	_check(_tree_has_text(main, "图纸研发为永久角色"), "resumed factory preserves the exact research objective")
	var task_panel := main.find_child("OnboardingMissionPanel", true, false)
	var resumed_growth := _button_with_text(task_panel, "研发") if task_panel != null else null
	_check(resumed_growth != null, "resumed factory keeps faction research as its primary action")
	if resumed_growth != null:
		resumed_growth.pressed.emit()
		await _wait_frames(4)
	_check(main.find_child("BlueprintScreen", true, false) != null, "resumed factory action opens the exact blueprint system")

	state = game.current_state()
	assault = _hero_for(state, "assault")
	armored = _hero_for(state, "armored")
	assault.star = 1
	armored.star = 2
	var armored_proof := String(main.call("_boss_mastery_proof_copy", {
		"cannon_guarded_count": 2,
		"cannon_guard_counter_damage": 120,
	}))
	_check(armored_proof.contains("装甲格挡") and armored_proof.contains("反震 120"), "defensive route receives an equivalent runtime mastery proof")

	if audio_director != null:
		audio_director.call("stop_all")
	assault = null
	armored = null
	state = null
	game = null
	main.queue_free()
	await _wait_frames(4)
	if failures.is_empty():
		print("CHAPTER_ONE_COMPLETION_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("CHAPTER_ONE_COMPLETION_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _hero_for(state: RefCounted, archetype_id: String) -> RefCounted:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			return hero
	return null


func _seed_foundational_research(main: Node) -> void:
	main.call("_command", "claim_foundational_signal", {})
	var state: RefCounted = main.get("game").current_state()
	state.factory.discovered_blueprints["ordinary.assault"] = true
	state.factory.discovered_blueprints["heavy.armored"] = true
	for entry in [["ordinary.assault", 1000, 1045], ["heavy.armored", 1045, 1090]]:
		main.call("_command", "unlock_foundational_blueprint", {
			"recipe_id": String(entry[0]), "now_unix": int(entry[1]),
		})
		main.call("_command", "claim_blueprint_research", {"now_unix": int(entry[2])})


func _button_with_text(node: Node, fragment: String) -> Button:
	if node is Button and (node as Button).text.contains(fragment):
		return node as Button
	for child in node.get_children():
		var match := _button_with_text(child, fragment)
		if match != null:
			return match
	return null


func _tree_has_button(node: Node, fragment: String) -> bool:
	return _button_with_text(node, fragment) != null


func _tree_has_text(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment):
		return true
	if node is Button and (node as Button).text.contains(fragment):
		return true
	for child in node.get_children():
		if _tree_has_text(child, fragment):
			return true
	return false


func _wait_frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
