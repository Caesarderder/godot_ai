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
	game.reset_game(20260727, 1000)
	var state: RefCounted = game.current_state()
	state.onboarding["active_index"] = 3
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	main.call("_claim_research_breakthrough")
	await _wait_frames(4)
	state = game.current_state()
	main.call("_open_breakthrough_formation")
	await _wait_frames(4)
	_check(String(main.get("formation_edit_slot")) == "troop_1", "breakthrough CTA selects the first empty front slot")
	_check(main.find_child("FirstFormationGuide", true, false) != null, "first formation guide is visible")
	var armored := _hero_for(state, "armored")
	var assault := _hero_for(state, "assault")
	var armored_button := main.find_child("FormationCandidate_%s" % armored.hero_id, true, false) as Button
	_check(armored_button != null and armored_button.text.contains("推荐下一步"), "armored reinforcement is recommended first")
	if armored_button != null:
		armored_button.pressed.emit()
		await _wait_frames(4)
	state = game.current_state()
	_check(String(state.formation.slots.get("troop_1", "")) == String(armored.hero_id), "armored assignment persists through the command boundary")
	_check(String(main.get("formation_edit_slot")) == "troop_2", "accepted first assignment advances to the next empty slot")
	var assault_button := main.find_child("FormationCandidate_%s" % assault.hero_id, true, false) as Button
	_check(assault_button != null and assault_button.text.contains("推荐下一步"), "assault reinforcement becomes the second recommendation")
	if assault_button != null:
		assault_button.pressed.emit()
		await _wait_frames(4)
	state = game.current_state()
	_check(String(state.formation.slots.get("troop_2", "")) == String(assault.hero_id), "assault assignment persists through the command boundary")
	var counterattack := main.find_child("FormationCounterattackButton", true, false) as Button
	_check(counterattack != null and counterattack.text.contains("立即反攻 1-4"), "completed formation exposes the exact hurdle retry")
	var audio_director: Node = main.get("audio_director")
	if audio_director != null:
		audio_director.call("stop_all")
	main.queue_free()
	await _wait_frames(4)
	if failures.is_empty():
		print("FIRST_FORMATION_FLOW_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("FIRST_FORMATION_FLOW_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _hero_for(state: RefCounted, archetype_id: String) -> RefCounted:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			return hero
	return null


func _wait_frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
