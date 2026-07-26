extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	change_scene_to_file("res://scenes/screens/main.tscn")
	for _frame in 8:
		await process_frame
	var main := current_scene
	var game: Node = root.get_node_or_null("Game")
	if main == null or game == null:
		_fail("app shell unavailable")
		return
	var audio_director: Node = main.get("audio_director")
	if audio_director != null:
		audio_director.call("set_playback_enabled", false)
	game.reset_game(20260727, 1000)
	var state: RefCounted = game.current_state()
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	main.call("_claim_research_breakthrough")
	for _frame in 4:
		await process_frame
	state = game.current_state()
	state.onboarding["active_index"] = 6
	var assault := _hero_for(state, "assault")
	var armored := _hero_for(state, "armored")
	if assault == null or armored == null:
		_fail("assault route unavailable")
		return
	assault.star = 2
	state.formation.slots["troop_1"] = armored.hero_id
	state.formation.slots["troop_2"] = assault.hero_id
	main.call("_show_legion")
	for _frame in 10:
		await process_frame
	var attack := main.find_child("BossReadyAttackButton", true, false) as Button
	if attack == null or not attack.is_visible_in_tree():
		_fail("boss verification action unavailable")
		return
	if not _save("res://artifacts/ui-boss-ready-844x390.png"):
		return
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "defeat",
			"stage_id": "stage_1_5",
			"reward": {"gold": 0, "porcelain": 0, "parts": 0, "sludge": 0},
			"industrial_tech": 0,
		},
	})
	main.set("last_battle_runtime_result", {
		"ticks": 280,
		"structures_destroyed": 3,
		"enemies_defeated": 5,
		"deployed_unit_ids": state.formation.hero_ids(),
		"cannon_hit_count": 2,
		"cannon_suppressed_count": 0,
	})
	main.call("_show_result")
	for _frame in 10:
		await process_frame
	var retry := _button_with_text(main, "掌握巨炮时机 · 再战 1-5")
	if retry == null or not _tree_has_text(main, "巨炮机制/技能时机"):
		_fail("timing recovery result unavailable")
		return
	if not _save("res://artifacts/ui-boss-timing-recovery-844x390.png"):
		return
	state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
	]
	state.stage_progress["highest_unlocked_stage"] = "stage_2_1"
	state.onboarding["active_index"] = 7
	state.meta_progression.commander_xp = 450
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_1_5",
			"next_stage_id": "stage_2_1",
			"reward": {"gold": 58, "porcelain": 27, "parts": 23, "sludge": 21},
			"industrial_tech": 4,
			"hero_shards": 8,
			"skill_chips": 2,
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
		"deployed_unit_ids": state.formation.hero_ids(),
		"cannon_hit_count": 1,
		"cannon_suppressed_count": 4,
		"ally_damage_dealt_by_unit": {assault.hero_id: 1840},
	})
	main.call("_show_result")
	for _frame in 10:
		await process_frame
	var chapter_two := _button_with_text(main, "开启第2章 · 侦察 2-1")
	if chapter_two == null or not _tree_has_text(main, "冲锋压炮"):
		_fail("chapter completion mastery result unavailable")
		return
	if not _save("res://artifacts/ui-chapter-one-complete-844x390.png"):
		return
	chapter_two.pressed.emit()
	for _frame in 10:
		await process_frame
	if not _tree_has_text(main, "下一步 · 培养军团并扩建后勤"):
		_fail("chapter two growth handoff unavailable")
		return
	if not _save("res://artifacts/ui-chapter-two-handoff-844x390.png"):
		return
	main.call("_show_goals")
	for _frame in 10:
		await process_frame
	if not _tree_has_text(main, "第二章：突破震荡封锁线"):
		_fail("post-onboarding chapter goal unavailable")
		return
	if not _save("res://artifacts/ui-chapter-two-goal-844x390.png"):
		return
	main.call("_show_title")
	for _frame in 10:
		await process_frame
	if not _tree_has_text(main, "第二章备战 · 还差"):
		_fail("chapter two resume title unavailable")
		return
	if not _save("res://artifacts/ui-chapter-two-resume-title-844x390.png"):
		return
	var resume := _button_with_text(main, "返回指挥室")
	if resume == null:
		_fail("chapter two resume action unavailable")
		return
	resume.pressed.emit()
	for _frame in 10:
		await process_frame
	if not _tree_has_text(main, "第二章备战：震荡封锁线"):
		_fail("chapter two resumed factory task unavailable")
		return
	if not _save("res://artifacts/ui-chapter-two-resume-base-844x390.png"):
		return
	main.queue_free()
	await process_frame
	print("BOSS VALIDATION FLOW CAPTURE PASS")
	quit(0)


func _hero_for(state: RefCounted, archetype_id: String) -> RefCounted:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			return hero
	return null


func _button_with_text(node: Node, fragment: String) -> Button:
	if node is Button and (node as Button).text.contains(fragment):
		return node as Button
	for child in node.get_children():
		var match := _button_with_text(child, fragment)
		if match != null:
			return match
	return null


func _tree_has_text(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment):
		return true
	if node is Button and (node as Button).text.contains(fragment):
		return true
	for child in node.get_children():
		if _tree_has_text(child, fragment):
			return true
	return false


func _save(path: String) -> bool:
	var error := root.get_texture().get_image().save_png(path)
	if error == OK:
		return true
	_fail(error_string(error))
	return false


func _fail(reason: String) -> void:
	push_error("BOSS VALIDATION FLOW CAPTURE FAIL: %s" % reason)
	quit(1)
