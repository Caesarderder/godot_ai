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
	var next_chapter := _button_with_text(main, "开启第2章 · 侦察 2-1")
	_check(next_chapter != null, "completion exposes one next autonomous campaign goal")
	if next_chapter != null:
		next_chapter.pressed.emit()
		await _wait_frames(4)
	_check(String(main.get("selected_stage_id")) == "stage_2_1", "next-chapter action selects the exact unlocked stage")
	_check(_tree_has_text(main, "2-1 震荡封锁线"), "next-chapter action opens reconnaissance instead of forcing another battle")
	_check(_tree_has_text(main, "我方") and _tree_has_text(main, "推荐"), "second-chapter reconnaissance compares current and recommended power")
	_check(_tree_has_button(main, "立即出击"), "post-growth squad may immediately test the 2-1 opening stage")
	main.set("legion_tab", "roster")
	main.call("_show_legion")
	await _wait_frames(4)
	_check(main.find_child("LegionFormationTab", true, false) != null, "post-chapter player can still open the legion voluntarily")
	_check(
		main.find_child("LegionContentScroll_roster", true, false) != null,
		"chapter-two growth opens permanent hero growth instead of an unrelated formation overview"
	)
	_check(
		_tree_has_text(main, "80 金币 · 4 军团数据"),
		"the first skill sink exposes its exact canonical cost"
	)
	var skill_research := main.find_child("ResearchSkill_assault", true, false) as Button
	_check(
		skill_research != null and not skill_research.disabled,
		"Boss rewards make active-skill level two an immediately actionable post-chapter option"
	)

	main.call("_show_goals")
	await _wait_frames(4)
	_check(_tree_has_text(main, "第二章：突破震荡封锁线"), "post-onboarding goals replace the completed training label with the next chapter")
	_check(_tree_has_text(main, "侦察并准备进攻"), "post-onboarding goals name the immediately actionable reconnaissance")
	_check(_tree_has_text(main, "第二章声波防线"), "post-onboarding goals name the new medium hurdle")
	_check(_tree_has_button(main, "侦察 2-1"), "post-onboarding goals retain one executable campaign action")
	var goal_scout := _button_with_text(main, "侦察 2-1")
	if goal_scout != null:
		goal_scout.pressed.emit()
		await _wait_frames(4)
	_check(_tree_has_text(main, "2-1 震荡封锁线"), "post-onboarding goal action opens the target reconnaissance")

	main.call("_show_title")
	await _wait_frames(4)
	_check(_tree_has_text(main, "下一行动"), "returning title summarizes the same chapter-two action")
	var resume := _button_with_text(main, "返回指挥室")
	_check(resume != null, "returning chapter-one save exposes a safe command-room resume")
	if resume != null:
		resume.pressed.emit()
		await _wait_frames(4)
	_check(_tree_has_text(main, "第二章备战：震荡封锁线"), "resumed factory replaces the completed onboarding card with the next campaign task")
	_check(_tree_has_text(main, "侦察并准备进攻"), "resumed factory preserves the executable reconnaissance objective")
	var resumed_scout := _button_with_text(main, "侦察 2-1")
	_check(resumed_scout != null, "resumed factory keeps the campaign route as its primary action")
	if resumed_scout != null:
		resumed_scout.pressed.emit()
		await _wait_frames(4)
	_check(_tree_has_text(main, "2-1 震荡封锁线"), "resumed factory campaign action opens the exact map target")

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
