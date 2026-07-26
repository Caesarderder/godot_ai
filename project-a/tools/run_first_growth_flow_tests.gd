extends SceneTree

const OnboardingService := preload("res://game/scripts/domain/onboarding/onboarding_service.gd")

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
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	main.call("_claim_research_breakthrough")
	await _wait_frames(3)
	state = game.current_state()
	var initial_armored := _hero_for(state, "armored")
	var initial_assault := _hero_for(state, "assault")
	main.call("_command", "assign_formation_slot", {
		"slot": "troop_1",
		"hero_id": initial_armored.hero_id,
	})
	main.call("_command", "assign_formation_slot", {
		"slot": "troop_2",
		"hero_id": initial_assault.hero_id,
	})
	state = game.current_state()
	state.onboarding["active_index"] = 5
	main.call("_on_result_action_requested", "factory", {})
	await _wait_frames(3)
	_check(main.find_child("ConstructionPanel", true, false) != null, "industrial result CTA enters construction instead of looping on the mission panel")
	_check(main.find_child("ChooseFacility_porcelain_plant", true, false) != null, "the first industrial step exposes a real resource facility choice")
	_check(main.find_child("ChooseFacility_repair_center", true, false) == null, "unrelated facilities defer during the commissioning choice")
	_check(_tree_has_text(main, "二星升星需要"), "resource choices explain the immediate growth requirement")

	state.factory.facilities["porcelain_plant"] = 1
	state.factory.facility_placements["porcelain_plant"] = [-1, 0]
	OnboardingService.apply_event(state, {
		"type": "facility_constructed",
		"facility_id": "porcelain_plant",
		"request_id": "growth-flow-built",
	})
	main.call("_follow_task", "factory")
	await _wait_frames(3)
	var selected_panel := main.find_child("SelectedFacilityPanel", true, false)
	_check(selected_panel != null, "the commissioning objective routes to the newly built facility")
	_check(_tree_has_text(selected_panel, "收取陶瓷"), "the commissioning objective exposes the exact collection action")

	OnboardingService.apply_event(state, {
		"type": "factory_output_claimed",
		"facility_id": "porcelain_plant",
		"request_id": "growth-flow-collected",
	})
	state.economy.hero_shards = maxi(4, int(state.economy.hero_shards))
	state.factory.materials["porcelain"] = maxi(18, int(state.factory.materials["porcelain"]))
	state.factory.materials["parts"] = maxi(10, int(state.factory.materials["parts"]))
	state.factory.materials["sludge"] = maxi(8, int(state.factory.materials["sludge"]))
	main.call("_follow_task", "legion")
	await _wait_frames(3)
	var choice_panel := main.find_child("FirstGrowthChoice", true, false)
	_check(choice_panel != null, "collected commissioning output opens a focused combat growth choice")
	_check(_tree_has_text(choice_panel, "快攻") and _tree_has_text(choice_panel, "守势"), "both verified boss routes remain visible")
	_check(_tree_has_text(choice_panel, "实测 7/7 通关"), "route evidence is visible before the irreversible choice")
	_check(_tree_has_text(choice_panel, "战力") and _tree_has_text(choice_panel, "消耗"), "the choice exposes power impact and exact cost")
	_check(not (main.find_child("TaskTabs", true, false) as HBoxContainer).visible, "unrelated formation and recruitment tabs defer during the first growth choice")
	var assault_button := main.find_child("ChooseGrowth_assault", true, false) as Button
	var armored_button := main.find_child("ChooseGrowth_armored", true, false) as Button
	_check(assault_button != null and not assault_button.disabled, "the fast route is actionable")
	_check(armored_button != null and not armored_button.disabled, "the defensive route is equally actionable")
	if assault_button != null:
		assault_button.pressed.emit()
		await _wait_frames(4)
	state = game.current_state()
	var assault := _hero_for(state, "assault")
	_check(assault != null and int(assault.star) == 2, "the chosen route commits through the star-up domain command")
	_check(String(OnboardingService.snapshot(state).get("task_id", "")) == "operation.chapter_boss", "accepted growth immediately advances to the chapter boss")
	var boss_ready := main.find_child("BossReadyPanel", true, false)
	_check(boss_ready != null, "accepted growth opens a focused boss verification state")
	_check(_tree_has_text(boss_ready, "快攻路线") and _tree_has_text(boss_ready, "5 秒预警"), "boss verification carries the chosen route and exact tactic")
	_check(_tree_has_text(boss_ready, "军团战力") and _tree_has_text(boss_ready, "推荐"), "boss verification compares canonical team and stage power")
	_check(not (main.find_child("TaskTabs", true, false) as HBoxContainer).visible, "unrelated legion tabs defer until the growth is tested")
	var timing_debrief := String(main.call(
		"_battle_debrief_copy",
		{"cannon_hit_count": 2},
		"defeat",
		"stage_1_5"
	))
	_check(timing_debrief.contains("巨炮机制/技能时机"), "cannon hits produce a mechanism and timing diagnosis")
	var timing_recovery := main.call("_boss_failure_recovery", {"cannon_hit_count": 2}) as Dictionary
	_check(String(timing_recovery.get("label", "")).contains("再战 1-5"), "timing failure offers an immediate mastery retry")
	var formation_recovery := main.call("_boss_failure_recovery", {"cannon_suppressed_count": 1}) as Dictionary
	_check(String(formation_recovery.get("label", "")).contains("阵容与战力"), "a failed run that handled the cannon routes back to formation analysis")
	var guarded_debrief := String(main.call(
		"_battle_debrief_copy",
		{"cannon_guarded_count": 1},
		"defeat",
		"stage_1_5"
	))
	_check(guarded_debrief.contains("阵容/战力"), "guarding the cannon cannot hide a later formation failure")
	assault.star = 1
	var growth_debrief := String(main.call(
		"_battle_debrief_copy",
		{},
		"defeat",
		"stage_1_5"
	))
	_check(growth_debrief.contains("成长未完成"), "missing two-star growth is diagnosed before mechanics")
	assault.star = 2
	var attack := main.find_child("BossReadyAttackButton", true, false) as Button
	_check(attack != null and attack.text.contains("进攻 1-5"), "boss verification exposes one exact test action")
	if attack != null:
		attack.pressed.emit()
		await _wait_frames(4)
	_check(main.find_child("BattleHudScreen", true, false) != null, "boss verification action enters the real battle")

	if audio_director != null:
		audio_director.call("stop_all")
	initial_armored = null
	initial_assault = null
	assault = null
	state = null
	game = null
	main.queue_free()
	await _wait_frames(4)
	if failures.is_empty():
		print("FIRST_GROWTH_FLOW_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("FIRST_GROWTH_FLOW_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _hero_for(state: RefCounted, archetype_id: String) -> RefCounted:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			return hero
	return null


func _tree_has_text(node: Node, fragment: String) -> bool:
	if node == null:
		return false
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
