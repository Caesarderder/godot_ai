extends SceneTree

const FactoryCatalogScript := preload(
	"res://game/scripts/domain/factory/factory_catalog.gd"
)
const OnboardingCatalogScript := preload(
	"res://game/scripts/domain/onboarding/onboarding_catalog.gd"
)
const RecruitmentResultProjectionScript := preload(
	"res://game/scripts/domain/recruitment/recruitment_result_projection.gd"
)


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	change_scene_to_file("res://scenes/screens/main.tscn")
	await _wait_frames(20)
	var main := current_scene
	if main == null:
		_fail("main scene unavailable")
		return
	var game: Node = main.get("game")
	var audio_director: Node = main.get("audio_director")
	if audio_director != null:
		audio_director.call("set_playback_enabled", false)
	game.reset_game(20260727, 1000)
	_prepare_post_chapter_state(main)

	main.set("legion_tab", "recruit")
	main.call("_show_legion")
	await _wait_frames(6)
	var free_ten := main.find_child("FoundationalSignalTenButton", true, false) as Button
	if free_ten == null:
		_fail("free faction ten-pull unavailable")
		return
	free_ten.pressed.emit()
	await _wait_frames(8)
	if not _save("res://artifacts/ui-faction-recruit-result-844x390.png"):
		return

	var state: RefCounted = game.current_state()
	var event := RecruitmentResultProjectionScript.latest_event_for_command(
		state,
		"claim_faction_signal"
	)
	var archetype_id := String(event.get("guaranteed_duplicate_archetype", ""))
	var recipe := FactoryCatalogScript.recipe_for_archetype(archetype_id)
	var recipe_id := String(recipe.get("recipe_id", ""))
	var focus_action := main.find_child("RecruitFocusActionButton", true, false) as Button
	if focus_action == null or recipe_id.is_empty():
		_fail("faction core result unavailable")
		return
	focus_action.pressed.emit()
	await _wait_frames(8)
	if not _save("res://artifacts/ui-faction-blueprint-focus-844x390.png"):
		return

	var research_name := "UnlockFoundationalBlueprint_%s" % recipe_id.replace(".", "_")
	var research := main.find_child(research_name, true, false) as Button
	if research == null:
		_fail("focused blueprint research unavailable")
		return
	research.pressed.emit()
	await _wait_frames(4)
	state = game.current_state()
	var active_research := state.factory.blueprint_research as Dictionary
	active_research["started_at_unix"] = 0
	active_research["completes_at_unix"] = 0
	main.call("_show_blueprints")
	await _wait_frames(4)
	var claim := main.find_child("ClaimFoundationalBlueprint", true, false) as Button
	if claim == null:
		_fail("completed research claim unavailable")
		return
	claim.pressed.emit()
	await _wait_frames(8)
	if not _save("res://artifacts/ui-faction-formation-focus-844x390.png"):
		return

	state = game.current_state()
	var faction_hero: RefCounted = _hero_for(state, archetype_id)
	if faction_hero == null:
		_fail("researched faction hero unavailable")
		return
	var hero_id := String(faction_hero.hero_id)
	var candidate := main.find_child("FormationCandidate_%s" % hero_id, true, false) as Button
	if candidate == null:
		_fail("faction formation candidate unavailable")
		return
	candidate.pressed.emit()
	await _wait_frames(5)
	state = game.current_state()
	state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
		"stage_2_1", "stage_2_2", "stage_2_3",
	]
	state.stage_progress["highest_unlocked_stage"] = "stage_2_4"
	main.call("_show_goals")
	await _wait_frames(4)
	var star_cta := main.find_child("GoalHierarchyPrimaryCTA", true, false) as Button
	if star_cta == null:
		_fail("faction star goal unavailable")
		return
	star_cta.pressed.emit()
	await _wait_frames(8)
	if not _save("res://artifacts/ui-faction-star-ready-844x390.png"):
		return
	var star := main.find_child("CultivationAction_star", true, false) as Button
	if star == null or star.disabled:
		_fail("faction star action unavailable")
		return
	star.pressed.emit()
	await _wait_frames(2)
	if not _save("res://artifacts/ui-faction-star-unlocked-844x390.png"):
		return
	state = game.current_state()
	faction_hero = state.hero_by_id(hero_id)
	state.stage_progress["cleared_stages"].append("stage_2_4")
	state.stage_progress["cleared_stages"].append("stage_2_5")
	state.stage_progress["highest_unlocked_stage"] = "stage_3_1"
	var metric_key := _qualitative_metric_for(archetype_id)
	var runtime_result := {
		"ticks": 612,
		"structures_destroyed": 7,
		"enemies_defeated": 9,
		"deployed_unit_ids": state.formation.hero_ids(),
		"troop_damage_share_percent": 84,
		"ally_damage_dealt_by_unit": {hero_id: 2380},
	}
	runtime_result[metric_key] = 7
	main.set("last_battle_runtime_result", runtime_result)
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_2_5",
			"next_stage_id": "stage_3_1",
			"reward": {"gold": 78, "porcelain": 35, "parts": 31, "sludge": 26},
			"industrial_tech": 5,
			"hero_shards": 12,
			"skill_chips": 3,
		},
	})
	main.call("_show_result")
	await _wait_frames(10)
	if not _save("res://artifacts/ui-faction-chapter-two-proof-844x390.png"):
		return
	main.call("_show_blueprints")
	await _wait_frames(8)
	if not _save("res://artifacts/ui-faction-tech-preview-844x390.png"):
		return
	main.call("_show_result")
	await _wait_frames(6)
	var next_chapter := main.find_child("PrimaryAction", true, false) as Button
	if next_chapter == null:
		_fail("chapter-three reorientation action unavailable")
		return
	next_chapter.pressed.emit()
	await _wait_frames(8)
	if not _save("res://artifacts/ui-chapter-three-reorientation-844x390.png"):
		return
	main.set("battle_manual_skills", true)
	main.call("_start_stage_battle", "stage_2_1")
	await _wait_frames(5)
	var battle_world: Node = main.get("battle_world")
	if battle_world == null:
		_fail("chapter-two battle world unavailable")
		return
	battle_world.set_process(false)
	var battle_session: RefCounted = battle_world.get("_session")
	var skill_mode := main.find_child("BattleSkillModeButton", true, false) as Button
	if skill_mode != null and skill_mode.text.contains("自动"):
		skill_mode.pressed.emit()
	for ally in battle_session._living_main_allies():
		ally["energy"] = 100
	battle_session.tick_index = 44
	battle_world.call("_process", 0.2)
	await _wait_frames(2)
	if not _save("res://artifacts/ui-chapter-two-resonance-warning-844x390.png"):
		return
	battle_session.tick_index = 54
	battle_world.call("_process", 0.2)
	await _wait_frames(1)
	if not _save("res://artifacts/ui-chapter-two-resonance-impact-844x390.png"):
		return
	main.call("_start_stage_battle", "stage_2_3")
	await _wait_frames(5)
	battle_world = main.get("battle_world")
	battle_world.set_process(false)
	battle_session = battle_world.get("_session")
	battle_session.tick_index = 64
	battle_world.call("_process", 0.2)
	await _wait_frames(2)
	if not _save("res://artifacts/ui-chapter-two-reinforcement-844x390.png"):
		return
	main.call("_start_stage_battle", "stage_2_4")
	await _wait_frames(5)
	battle_world = main.get("battle_world")
	battle_world.set_process(false)
	battle_session = battle_world.get("_session")
	battle_session.tick_index = 39
	battle_world.call("_process", 0.2)
	await _wait_frames(2)
	if not _save("res://artifacts/ui-chapter-two-echo-warning-844x390.png"):
		return
	battle_session.tick_index = 49
	battle_world.call("_process", 0.2)
	await _wait_frames(1)
	if not _save("res://artifacts/ui-chapter-two-echo-impact-844x390.png"):
		return
	main.call("_start_stage_battle", "stage_3_1")
	await _wait_frames(5)
	battle_world = main.get("battle_world")
	battle_world.set_process(false)
	battle_session = battle_world.get("_session")
	battle_session.tick_index = 59
	battle_world.call("_process", 0.2)
	await _wait_frames(2)
	if not _save("res://artifacts/ui-chapter-three-signal-vanish-844x390.png"):
		return
	main.call("_start_stage_battle", "stage_3_4")
	await _wait_frames(5)
	battle_world = main.get("battle_world")
	battle_world.set_process(false)
	battle_session = battle_world.get("_session")
	battle_session._stage_index = 1
	battle_session.tick_index = 59
	battle_world.call("_process", 0.2)
	await _wait_frames(2)
	if not _save("res://artifacts/ui-chapter-three-overseer-shield-844x390.png"):
		return
	main.call("_start_stage_battle", "stage_4_1")
	await _wait_frames(5)
	battle_world = main.get("battle_world")
	battle_world.set_process(false)
	battle_session = battle_world.get("_session")
	battle_session.tick_index = 49
	battle_world.call("_process", 0.2)
	await _wait_frames(2)
	if not _save("res://artifacts/ui-chapter-four-alliance-mark-844x390.png"):
		return
	main.call("_start_stage_battle", "stage_4_2")
	await _wait_frames(5)
	battle_world = main.get("battle_world")
	battle_world.set_process(false)
	battle_session = battle_world.get("_session")
	battle_session.tick_index = 49
	battle_world.call("_process", 0.2)
	await _wait_frames(2)
	if not _save("res://artifacts/ui-chapter-four-anti-air-844x390.png"):
		return

	if audio_director != null:
		audio_director.call("stop_all")
	main.queue_free()
	await _wait_frames(4)
	print("POST_30M_FACTION_CAPTURE_OK")
	quit(0)


func _prepare_post_chapter_state(main: Node) -> void:
	var game: Node = main.get("game")
	var state: RefCounted = game.current_state()
	state.factory.eligible_facilities["research_lab"] = true
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	main.call("_command", "claim_foundational_signal", {})
	for entry in [["ordinary.assault", 1000, 1045], ["heavy.armored", 1045, 1090]]:
		main.call("_command", "unlock_foundational_blueprint", {
			"recipe_id": String(entry[0]),
			"now_unix": int(entry[1]),
		})
		main.call("_command", "claim_blueprint_research", {"now_unix": int(entry[2])})
	state = game.current_state()
	var assault := _hero_for(state, "assault")
	var armored := _hero_for(state, "armored")
	state.formation.slots["troop_1"] = String(armored.hero_id)
	state.formation.slots["troop_2"] = String(assault.hero_id)
	state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
	]
	state.stage_progress["highest_unlocked_stage"] = "stage_2_1"
	state.onboarding["active_index"] = OnboardingCatalogScript.count()
	state.meta_progression.commander_xp = 450
	state.economy.toilet_coins = 500


func _hero_for(state: RefCounted, archetype_id: String) -> RefCounted:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			return hero
	return null


func _qualitative_metric_for(archetype_id: String) -> String:
	return String({
		"assault": "assault_cleave_extra_hits",
		"sonic": "sonic_cross_lane_extra_targets",
		"rocket": "rocket_salvo_extra_targets",
		"bomber": "bomber_splash_extra_targets",
		"armored": "armored_group_shield_extra_targets",
		"saw": "saw_followup_hits",
		"repair": "repair_group_extra_targets",
		"parasite": "parasite_extra_summons",
	}.get(archetype_id, ""))


func _save(path: String) -> bool:
	var error := root.get_texture().get_image().save_png(path)
	if error == OK:
		return true
	_fail("cannot save %s: %s" % [path, error_string(error)])
	return false


func _wait_frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _fail(message: String) -> void:
	push_error("POST_30M_FACTION_CAPTURE_FAIL: %s" % message)
	quit(1)
