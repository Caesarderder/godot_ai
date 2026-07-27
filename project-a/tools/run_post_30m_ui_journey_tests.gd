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
	var proof_runtime := {
		"deployed_unit_ids": [hero_id],
	}
	proof_runtime[_qualitative_metric_for(archetype_id)] = 3
	var mastery_proof := String(
		main.call("_faction_mastery_proof_copy", proof_runtime, "victory", "stage_2_5")
	)
	_check(
		mastery_proof.contains("阵营质变验证")
			and mastery_proof.contains(String(faction_hero.display_name))
			and mastery_proof.contains("3 次"),
		"chapter-two result attributes the breakthrough to the exact drawn hero's two-star mechanic"
	)
	var resonance_debrief := String(main.call("_battle_debrief_copy", {
		"resonance_pulse_count": 8,
		"resonance_energy_drained": 320,
		"cannon_hit_count": 4,
	}, "defeat", "stage_2_4"))
	_check(
		resonance_debrief.contains("共振冲击 8 次")
			and resonance_debrief.contains("紫色预警"),
		"chapter-two non-boss defeat explains the authored resonance mechanic instead of mislabeling ordinary artillery as the boss cannon"
	)
	var reinforcement_debrief := String(main.call("_battle_debrief_copy", {
		"speaker_reinforcement_waves": 2,
		"resonance_pulse_count": 7,
	}, "victory", "stage_2_3"))
	_check(
		reinforcement_debrief.contains("击穿 2 波临时增援")
			and reinforcement_debrief.contains("优先清理广播车"),
		"stage 2-3 result teaches the visible reinforcement counter instead of collapsing back into resonance copy"
	)
	var echo_debrief := String(main.call("_battle_debrief_copy", {
		"speaker_echo_impact_count": 3,
		"speaker_echo_damage_dealt": 72,
		"resonance_pulse_count": 9,
	}, "defeat", "stage_2_4"))
	_check(
		echo_debrief.contains("双塔交替轰击 3 次")
			and echo_debrief.contains("72 伤害")
			and echo_debrief.contains("前排或后排"),
		"stage 2-4 defeat names the alternating-rank lesson and its measured cost"
	)
	var tv_debrief := String(main.call("_battle_debrief_copy", {
		"tv_shield_count": 4,
		"tv_control_count": 5,
	}, "defeat", "stage_3_4"))
	_check(
		tv_debrief.contains("精英护盾启动 4 次")
			and tv_debrief.contains("屏幕控制 5 次")
			and tv_debrief.contains("先击穿护盾"),
		"stage 3-4 result explains its combined TV modules and next target priority"
	)
	state.stage_progress["cleared_stages"].append("stage_2_4")
	state.stage_progress["cleared_stages"].append("stage_2_5")
	state.stage_progress["highest_unlocked_stage"] = "stage_3_1"
	main.set("last_battle_runtime_result", proof_runtime)
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_2_5",
			"next_stage_id": "stage_3_1",
			"reward": {"gold": 78},
			"hero_shards": 12,
		},
	})
	main.call("_show_result")
	await _wait_frames(4)
	_check(_tree_has_text(main, "第2章胜利"), "chapter-two boss receives a chapter-completion celebration")
	_check(_tree_has_text(main, "电视控制"), "chapter-two result previews the next chapter's distinct threat")
	_check(
		_tree_has_text(main, "阵营未来")
			and _tree_has_text(main, "第三章推进后开放")
			and _tree_has_text(main, "当前不增加战力"),
		"chapter-two result previews the player's durable faction technology without granting hidden power"
	)
	var next_chapter := main.find_child("PrimaryAction", true, false) as Button
	_check(next_chapter != null and next_chapter.text.contains("第3章新战线"), "chapter transition offers one reorientation action instead of blind auto-battle")
	_check(
		next_chapter != null
			and next_chapter.get_global_rect().end.x <= float(root.size.x)
			and next_chapter.get_global_rect().end.y <= float(root.size.y),
		"chapter-transition CTA remains fully visible inside the 844x390 viewport"
	)
	if next_chapter != null:
		next_chapter.pressed.emit()
		await _wait_frames(4)
	_check(String(main.get("selected_stage_id")) == "stage_3_1", "chapter transition focuses the exact next stage")
	_check(int(main.get("selected_chapter")) == 3, "chapter transition opens chapter three rather than the stale chapter-two tab")
	_check(
		_tree_has_text(main, "阵容核对")
			and _tree_has_text(main, "已覆盖")
			and _tree_has_text(main, "待补"),
		"next-chapter reconnaissance translates static recommendations into the player's current formation plan"
	)
	main.call("_show_blueprints")
	await _wait_frames(4)
	var tech_preview := main.find_child("FactionTechPreview", true, false) as Control
	_check(
		tech_preview != null
			and tech_preview.visible
			and _tree_has_text(tech_preview, "阵营科技预览")
			and _tree_has_text(tech_preview, "预览不增加当前战力"),
		"blueprint screen persistently reconstructs the core faction's read-only technology preview"
	)
	_check(
		tech_preview != null
			and tech_preview.get_global_rect().end.x <= float(root.size.x)
			and tech_preview.get_global_rect().end.y <= float(root.size.y),
		"faction technology preview remains visible inside the 844x390 viewport"
	)

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
