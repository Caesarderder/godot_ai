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
	state.factory.eligible_facilities["research_lab"] = true
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	_seed_foundational_research(main)
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
	state.economy.toilet_coins = 500
	state.economy.industrial_tech = 20
	state.economy.skill_chips = 3
	state.factory.materials = {"porcelain": 100, "parts": 100, "sludge": 100}
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
	var faction_recruit := _button_with_text(main, "领取阵营起手十连")
	if faction_recruit == null or not _tree_has_text(main, "冲锋压炮"):
		_fail("chapter completion mastery result unavailable")
		return
	if not await _save_at_size(
		Vector2i(844, 390),
		"res://artifacts/ui-chapter-one-complete-844x390.png"
	):
		return
	if not await _save_at_size(
		Vector2i(568, 320),
		"res://artifacts/ui-chapter-one-complete-568x320.png"
	):
		return
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	for _frame in 6:
		await process_frame
	faction_recruit = _button_with_text(main, "领取阵营起手十连")
	faction_recruit.pressed.emit()
	for _frame in 10:
		await process_frame
	if (
		String(main.get("legion_tab")) != "recruit"
		or _button_with_text(main, "领取免费阵营十连") == null
	):
		_fail("chapter completion does not hand off to the real free faction ten-pull")
		return
	if not await _save_at_size(
		Vector2i(844, 390),
		"res://artifacts/ui-chapter-one-faction-recruit-844x390.png"
	):
		return
	if not await _save_at_size(
		Vector2i(568, 320),
		"res://artifacts/ui-chapter-one-faction-recruit-568x320.png"
	):
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


func _seed_foundational_research(main: Node) -> void:
	main.call("_command", "claim_foundational_signal", {})
	for entry in [["ordinary.assault", 1000, 1045], ["heavy.armored", 1045, 1090]]:
		main.call("_command", "unlock_foundational_blueprint", {
			"recipe_id": String(entry[0]),
			"now_unix": int(entry[1]),
		})
		main.call("_command", "claim_blueprint_research", {
			"now_unix": int(entry[2]),
		})


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


func _save_at_size(viewport_size: Vector2i, path: String) -> bool:
	DisplayServer.window_set_size(viewport_size)
	root.size = viewport_size
	for _frame in 6:
		await process_frame
	return _save(path)


func _fail(reason: String) -> void:
	push_error("BOSS VALIDATION FLOW CAPTURE FAIL: %s" % reason)
	quit(1)
