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

	if audio_director != null:
		audio_director.call("stop_all")
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
