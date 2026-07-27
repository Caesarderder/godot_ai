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

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(844, 390)
	change_scene_to_file("res://scenes/screens/main.tscn")
	await _wait_frames(8)
	var main := current_scene
	var game: Node = main.get("game")
	var audio_director: Node = main.get("audio_director")
	if audio_director != null:
		audio_director.call("set_playback_enabled", false)
	game.reset_game(20260727, 1000)
	_prepare_post_chapter_state(main)
	await _wait_frames(4)

	main.set("legion_tab", "recruit")
	main.call("_show_legion")
	await _wait_frames(4)
	var free_ten := main.find_child("FoundationalSignalTenButton", true, false) as Button
	_check(free_ten != null and not free_ten.disabled, "post-chapter recruit tab exposes the free faction ten-pull")
	if free_ten != null:
		free_ten.pressed.emit()
		await _wait_frames(8)
	_check(main.find_child("SignalRecruitResultPanel", true, false) != null, "ten-pull renders its real result panel")
	_check(main.find_child("RecruitFactionFocus", true, false) != null, "ten-pull identifies one faction core")
	var recruit_scroll := main.find_child("LegionContentScroll_recruit", true, false) as ScrollContainer
	_check(
		recruit_scroll != null and recruit_scroll.scroll_vertical > 0,
		"ten-pull automatically reveals its reward instead of leaving it below the fold"
	)

	var state: RefCounted = game.current_state()
	var event := RecruitmentResultProjectionScript.latest_event_for_command(
		state,
		"claim_faction_signal"
	)
	var archetype_id := String(event.get("guaranteed_duplicate_archetype", ""))
	var recipe := FactoryCatalogScript.recipe_for_archetype(archetype_id)
	var recipe_id := String(recipe.get("recipe_id", ""))
	_check(not archetype_id.is_empty() and not recipe_id.is_empty(), "durable ten-pull receipt identifies an exact research target")
	var focus_action := main.find_child("RecruitFocusActionButton", true, false) as Button
	_check(focus_action != null and not focus_action.disabled, "faction result provides one executable research action")
	if focus_action != null:
		focus_action.pressed.emit()
		await _wait_frames(4)
	_check(
		String(main.get("blueprint_branch")) == recipe_id.get_slice(".", 0),
		"result action opens the branch containing the drawn faction core"
	)
	var blueprint_node_name := "BlueprintNode_%s" % recipe_id.replace(".", "_")
	var focused_blueprint := main.find_child(blueprint_node_name, true, false)
	_check(focused_blueprint != null, "drawn blueprint is visible without another navigation guess")
	_check(
		focused_blueprint != null and _tree_has_text(focused_blueprint, "本轮十连阵营核心"),
		"drawn blueprint is visually distinguished from its branch neighbor"
	)
	var research_button_name := "UnlockFoundationalBlueprint_%s" % recipe_id.replace(".", "_")
	var research := main.find_child(research_button_name, true, false) as Button
	_check(research != null and not research.disabled, "drawn blueprint exposes its five-second research action")
	if research != null:
		research.pressed.emit()
		await _wait_frames(3)

	state = game.current_state()
	var active_research := state.factory.blueprint_research as Dictionary
	_check(String(active_research.get("recipe_id", "")) == recipe_id, "research action persists the exact drawn blueprint")
	# The real timer contract is covered separately; expire it here so this UI journey stays fast.
	active_research["started_at_unix"] = 0
	active_research["completes_at_unix"] = 0
	main.call("_show_blueprints")
	await _wait_frames(4)
	var claim := main.find_child("ClaimFoundationalBlueprint", true, false) as Button
	_check(claim != null and not claim.disabled, "completed research exposes a claim action on the same node")
	if claim != null:
		claim.pressed.emit()
		await _wait_frames(8)

	state = game.current_state()
	var faction_hero := _hero_for(state, archetype_id)
	_check(faction_hero != null, "claim creates one permanent hero for the drawn archetype")
	if faction_hero == null:
		await _finish(main, game, audio_director)
		return
	var hero_id := String(faction_hero.hero_id)
	_check(String(main.get("legion_tab")) == "formation", "claim lands directly in formation instead of the roster")
	_check(String(main.get("formation_edit_slot")) == "troop_3", "claim selects the first empty formation slot")
	var candidate := main.find_child("FormationCandidate_%s" % hero_id, true, false) as Button
	_check(candidate != null and not candidate.disabled, "new faction hero is immediately visible as a formation candidate")
	_check(candidate != null and candidate.text.contains("阵营核心"), "formation preserves the ten-pull core identity")
	var formation_scroll := main.find_child("LegionContentScroll_formation", true, false) as ScrollContainer
	_check(
		formation_scroll != null and formation_scroll.scroll_vertical > 0,
		"research claim automatically reveals the new formation candidate"
	)
	if candidate != null:
		candidate.pressed.emit()
		await _wait_frames(4)
	state = game.current_state()
	_check(String(state.formation.slots.get("troop_3", "")) == hero_id, "candidate click persists the faction hero in formation")

	main.call("_show_goals")
	await _wait_frames(4)
	_check(_tree_has_text(main, "实战证明 0/3"), "formation completion advances to a visible three-battle proof goal")
	var proof_cta := main.find_child("GoalHierarchyPrimaryCTA", true, false) as Button
	_check(proof_cta != null and proof_cta.text.contains("验证"), "proof goal retains one clear map action")
	if proof_cta != null:
		proof_cta.pressed.emit()
		await _wait_frames(4)
	_check(String(main.get("selected_stage_id")) == "stage_2_1", "proof action focuses the exact next second-chapter stage")

	state = game.current_state()
	state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
		"stage_2_1", "stage_2_2", "stage_2_3",
	]
	state.stage_progress["highest_unlocked_stage"] = "stage_2_4"
	main.call("_show_goals")
	await _wait_frames(4)
	_check(_tree_has_text(main, "专属碎片升至2★"), "three battle clears advance to the promised qualitative star goal")
	var star_cta := main.find_child("GoalHierarchyPrimaryCTA", true, false) as Button
	_check(star_cta != null and star_cta.text.contains("升至2★"), "star phase exposes the exact faction core action")
	if star_cta != null:
		star_cta.pressed.emit()
		await _wait_frames(4)
	_check(String(main.get("legion_tab")) == "roster", "star action opens the cultivation roster")
	_check(String(main.get("legion_selected_hero_id")) == hero_id, "star action focuses the exact hero from the durable ten-pull")
	var star := main.find_child("CultivationAction_star", true, false) as Button
	_check(star != null and not star.disabled, "guaranteed duplicate fragments fund the focused hero's two-star action")
	var fragments_before := int(state.meta_progression.hero_fragments.get(archetype_id, 0))
	if star != null:
		star.pressed.emit()
		await _wait_frames(4)
	_check(_tree_has_text(main, "质变解锁"), "star success immediately names the unlocked qualitative effect")
	state = game.current_state()
	faction_hero = state.hero_by_id(hero_id)
	_check(faction_hero != null and int(faction_hero.star) == 2, "star click applies the faction core's qualitative two-star state")
	_check(
		int(state.meta_progression.hero_fragments.get(archetype_id, 0)) < fragments_before,
		"star click consumes only the focused archetype's dedicated fragments"
	)
	main.call("_show_goals")
	await _wait_frames(4)
	_check(_tree_has_text(main, "击毁2-5核心"), "two-star completion reveals the final chapter-two proof instead of losing the journey")

	await _finish(main, game, audio_director)


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


func _finish(main: Node, game: Node, audio_director: Node) -> void:
	if audio_director != null:
		audio_director.call("stop_all")
	game = null
	main.queue_free()
	await _wait_frames(4)
	if failures.is_empty():
		print("POST_30M_UI_JOURNEY_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("POST_30M_UI_JOURNEY_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)
