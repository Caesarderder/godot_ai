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
	state.onboarding["active_index"] = 3
	state.factory.eligible_facilities["research_lab"] = true
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	state.onboarding["active_index"] = 1
	state.onboarding["progress"]["operation.keep_advancing/capture_1_2"] = 1
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_1_2",
			"next_stage_id": "stage_1_3",
			"reward": {"gold": 35},
			"unlocked_blueprints": [{
				"kind": "blueprint",
				"recipe_id": "ordinary.assault",
			}],
		},
	})
	main.set("last_battle_runtime_result", {
		"stage_reached": 2,
		"structures_destroyed": 5,
		"enemies_defeated": 6,
	})
	main.call("_show_result")
	await _wait_frames(4)
	var next_stage_cta := main.find_child("PrimaryAction", true, false) as Button
	_check(
		next_stage_cta != null
			and next_stage_cta.text.contains("继续进攻 1-3"),
		"stage 1-2 banks its blueprint without interrupting the authored two-stage advance"
	)
	state.onboarding["active_index"] = 3
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "defeat",
			"stage_id": "stage_1_4",
			"reward": {},
		},
	})
	main.set("last_battle_runtime_result", {
		"stage_reached": 1,
		"structures_destroyed": 2,
		"enemies_defeated": 3,
	})
	main.call("_show_result")
	await _wait_frames(4)
	var research_cta := main.find_child("PrimaryAction", true, false) as Button
	_check(
		research_cta != null
			and research_cta.text.contains("研发冲锋马桶人"),
		"1-4 defeat points to the exact first blueprint instead of generic cultivation (got: %s)" % (
			research_cta.text if research_cta != null else "missing"
		)
	)
	if research_cta != null:
		research_cta.pressed.emit()
		await _wait_frames(4)
	_check(
		String(main.get("blueprint_branch")) == "ordinary"
			and main.find_child("FactionTechPreview", true, false) != null,
		"1-4 recovery CTA opens the authored blueprint branch through the UI action boundary"
	)
	await _seed_foundational_research(main)
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
	var gman := _hero_for(state, "gman")
	var proof := String(main.call("_counterattack_proof_copy", {
		"deployed_unit_ids": [gman.hero_id, armored.hero_id, assault.hero_id],
		"troop_damage_share_percent": 68,
		"ally_damage_dealt_by_unit": {
			gman.hero_id: 100,
			armored.hero_id: 40,
			assault.hero_id: 60,
		},
	}, "victory", "stage_1_4"))
	_check(proof.contains("单人首战失败 → 三人反攻成功"), "counterattack result closes the hurdle narrative")
	_check(proof.contains("68% 承伤") and proof.contains("50% 输出"), "counterattack proof derives both percentages from runtime facts")
	if audio_director != null:
		audio_director.call("stop_all")
	gman = null
	armored = null
	assault = null
	state = null
	game = null
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


func _seed_foundational_research(main: Node) -> void:
	main.call("_command", "claim_foundational_signal", {})
	main.call("_command", "unlock_foundational_blueprint", {
		"recipe_id": "ordinary.assault", "now_unix": 1000,
	})
	main.call("_claim_foundational_blueprint")
	await _wait_frames(4)
	_check(
		String(main.get("blueprint_branch")) == "heavy",
		"claiming the first foundational hero keeps the player on the remaining research objective"
	)
	main.call("_command", "unlock_foundational_blueprint", {
		"recipe_id": "heavy.armored", "now_unix": 1045,
	})
	main.call("_claim_foundational_blueprint")


func _wait_frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
