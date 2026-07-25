extends SceneTree

const StageCatalog := preload("res://game/scripts/domain/content/stage_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_settings("user://settings.cfg")
	_cleanup_settings("user://save_v1.json")
	var game_autoload := root.get_node_or_null("/root/Game")
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if game_autoload != null and save_manager != null:
		game_autoload.bootstrap_with_manager(save_manager, 20260725, 1000)
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	var scene := load("res://scenes/screens/main.tscn") as PackedScene
	if scene == null:
		_fail("main scene loads")
		_finish()
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	for _frame in 20:
		await process_frame
	_ok(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 1280, "project uses 1280 web design canvas width")
	_ok(int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 720, "project uses 720 web design canvas height")
	_ok(int(ProjectSettings.get_setting("display/window/size/window_width_override")) == 1280, "project keeps 1280 window width override")
	_ok(int(ProjectSettings.get_setting("display/window/size/window_height_override")) == 720, "project keeps 720 window height override")
	_ok(String(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility", "project keeps Compatibility renderer")
	_ok(root.size == Vector2i(844, 390), "viewport remains 844x390")
	var mobile_canvas_scale := 390.0 / float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	_ok(instance.get_node_or_null("WorldHost") != null, "main scene has 3D host")
	_ok(instance.get_node_or_null("Interface/UIRoot") != null, "main scene has UI root")
	_ok(root.get_child_count() > 0, "main scene stays alive for mobile landscape smoke")
	_ok(instance.find_child("TitleSettingsButton", true, false) != null, "title screen exposes settings entry")
	instance.call("_show_camp")
	for _frame in 4:
		await process_frame
	_ok(instance.find_child("CampSettingsButton", true, false) != null, "camp actions expose settings entry")
	_ok(instance.find_child("TopBarSettingsButton", true, false) != null, "camp top bar exposes settings entry")
	var goal_entry := instance.find_child("QuestEntryButton", true, false) as Button
	var legacy_goal_entry := instance.find_child("GoalEntryButton", true, false) as Button
	_ok(goal_entry != null or legacy_goal_entry != null, "camp exposes one goal center entry")
	if goal_entry != null:
		_ok(goal_entry.text == "目标", "camp goal entry is labeled target")
		_ok(goal_entry.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "camp goal entry is touch-sized")
		_ok(instance.find_child("GoalEntryButton", true, false) == null, "camp keeps a single target entry node")
	var top_resources := instance.find_child("TopResourceSummaryLabel", true, false) as Label
	_ok(top_resources != null and top_resources.text.contains("残"), "top resource summary displays salvage")
	_ok(top_resources != null and top_resources.text.contains("战功Lv"), "top resource summary displays war merit rank")
	var objective_title := instance.find_child("ObjectiveTitle", true, false) as Label
	var objective_body := instance.find_child("ObjectiveBody", true, false) as Label
	var objective_button := instance.find_child("CampObjectiveButton", true, false) as Button
	_ok(objective_title != null and objective_title.text == "出征侦察", "new save objective points to scout expedition")
	_ok(objective_body != null and objective_body.text.contains("失败不会卡死"), "new save objective explains first-failure recovery")
	var game: Node = instance.get("game")
	var revision_before_cta := int(game.current_state().revision) if game != null else -1
	if objective_button != null:
		objective_button.pressed.emit()
	for _frame in 4:
		await process_frame
	var revision_after_cta := int(game.current_state().revision) if game != null else -2
	_ok(revision_after_cta == revision_before_cta, "camp objective CTA only navigates and does not change revision")
	if game != null:
		var revision_before_quests := int(game.current_state().revision)
		instance.call("_show_quests")
		for _frame in 6:
			await process_frame
		var revision_after_first_quests := int(game.current_state().revision)
		instance.call("_show_camp")
		for _frame in 4:
			await process_frame
		instance.call("_show_quests")
		for _frame in 6:
			await process_frame
		_ok(int(game.current_state().revision) == revision_after_first_quests, "opening quests again does not repeat revision changes after initialization")
		_ok(revision_after_first_quests >= revision_before_quests, "quest initialization does not move revision backwards")
		var quests_scroll := instance.find_child("QuestsScrollContainer", true, false) as ScrollContainer
		var quest_tab := instance.find_child("GoalTabQuestsButton", true, false) as Button
		var achievement_tab := instance.find_child("GoalTabAchievementsButton", true, false) as Button
		var war_merit := instance.find_child("QuestWarMeritLabel", true, false) as Label
		var campaign_card := instance.find_child("CampaignQuestCard", true, false) as Control
		var campaign_summary := instance.find_child("CampaignQuestSummaryLabel", true, false) as Label
		var no_daily := instance.find_child("QuestNoDailyCountdownLabel", true, false) as Label
		var quest_top_settings := instance.find_child("TopBarSettingsButton", true, false) as Button
		var quest_back := instance.find_child("ManagementBackButton", true, false) as Button
		var loop_cards: Array[Node] = []
		_collect_name_prefix(instance, "LoopQuestCard", loop_cards)
		_ok(quests_scroll != null and quests_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "quests page disables horizontal scrolling")
		_ok(quest_tab != null and quest_tab.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "quests tab is touch-sized")
		_ok(achievement_tab != null and achievement_tab.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "achievements tab is touch-sized")
		_ok(war_merit != null and war_merit.text.contains("当前等级"), "quests page displays war merit level")
		_ok(campaign_card != null, "quests page renders current campaign quest card")
		_ok(campaign_summary != null and campaign_summary.text.contains("25"), "campaign quest summarizes 25-task progress without long list")
		_ok(no_daily != null and no_daily.text.contains("无每日倒计时"), "quests page explicitly has no daily countdown")
		_ok(quest_top_settings != null and quest_top_settings.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "quests page top settings control is touch-sized")
		_ok(quest_back != null and quest_back.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "quests page back control is touch-sized")
		_ok(loop_cards.size() == 3, "quests page renders three loop quest cards")
		var quest_state := game.current_state().quests as Dictionary
		var inventory := game.current_state().inventory as Dictionary
		var inventory_items := inventory.get("items", {}) as Dictionary
		inventory_items["war_merit"] = 135
		inventory["items"] = inventory_items
		var active := quest_state.get("active", {}) as Dictionary
		var minor_slots := active.get("minor_slots", []) as Array
		var claim_entry := minor_slots[0] as Dictionary
		claim_entry["progress"] = int(claim_entry.get("target", 1))
		minor_slots[0] = claim_entry
		active["minor_slots"] = minor_slots
		quest_state["active"] = active
		quest_state["completed"] = {
			String(claim_entry["quest_id"]): {
				"quest_id": String(claim_entry["quest_id"]),
				"kind": "minor",
				"slot": int(claim_entry["slot"]),
				"generation": int(claim_entry["generation"]),
				"reward": (claim_entry["reward"] as Dictionary).duplicate(true),
			}
		}
		quest_state["claimed"] = {}
		instance.call("_show_quests")
		for _frame in 6:
			await process_frame
		var quest_rank := instance.find_child("QuestWarMeritLabel", true, false) as Label
		var claim_node_name := ("QuestClaimButton_%s" % String(claim_entry["quest_id"])).replace(".", "_")
		var active_node_name := ("QuestClaimButton_%s" % String((minor_slots[1] as Dictionary)["quest_id"])).replace(".", "_")
		var claim_button := instance.find_child(claim_node_name, true, false) as Button
		var active_button := instance.find_child(active_node_name, true, false) as Button
		_ok(quest_rank != null and quest_rank.text.contains("Lv2") and quest_rank.text.contains("35/140"), "quests page derives war merit rank and escalating next progress")
		_ok(claim_button != null and not claim_button.disabled and claim_button.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "completed quest exposes touch-sized claim button")
		_ok(active_button != null and active_button.disabled and active_button.text == "进行中", "active quest shows disabled progress action")
		var revision_before_achievements := int(game.current_state().revision)
		instance.call("_show_achievements")
		for _frame in 6:
			await process_frame
		var revision_after_first_achievements := int(game.current_state().revision)
		instance.call("_show_quests")
		for _frame in 4:
			await process_frame
		instance.call("_show_achievements")
		for _frame in 6:
			await process_frame
		_ok(int(game.current_state().revision) == revision_after_first_achievements, "opening achievements again does not repeat revision changes after initialization")
		_ok(revision_after_first_achievements >= revision_before_achievements, "achievement initialization does not move revision backwards")
		var achievements_scroll := instance.find_child("AchievementsScrollContainer", true, false) as ScrollContainer
		var achievements_tab := instance.find_child("GoalTabAchievementsButton", true, false) as Button
		var achievements_quest_tab := instance.find_child("GoalTabQuestsButton", true, false) as Button
		var overview := instance.find_child("AchievementOverviewLabel", true, false) as Label
		var category_all := instance.find_child("AchievementCategoryButton_all", true, false) as Button
		var category_campaign := instance.find_child("AchievementCategoryButton_campaign", true, false) as Button
		var category_factory := instance.find_child("AchievementCategoryButton_factory", true, false) as Button
		var category_cultivation := instance.find_child("AchievementCategoryButton_cultivation", true, false) as Button
		var category_collection := instance.find_child("AchievementCategoryButton_collection", true, false) as Button
		var achievement_cards: Array[Node] = []
		_collect_name_prefix(instance, "AchievementCard", achievement_cards)
		_ok(achievements_scroll != null and achievements_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "achievements page disables horizontal scrolling")
		_ok(achievements_tab != null and achievements_tab.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "achievements tab remains touch-sized")
		_ok(achievements_quest_tab != null and achievements_quest_tab.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "quests tab remains touch-sized on achievements page")
		_ok(overview != null and overview.text.contains("/24"), "achievements overview displays 24 definitions")
		_ok(category_campaign != null and category_factory != null and category_cultivation != null and category_collection != null, "achievements page renders four category controls")
		for category_button in [category_campaign, category_factory, category_cultivation, category_collection]:
			_ok(category_button != null and category_button.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "achievement category control is touch-sized")
		_ok(achievement_cards.size() == 24, "achievements page renders a single vertical list of 24 cards")
		if category_campaign != null and category_all != null:
			category_campaign.pressed.emit()
			for _frame in 4:
				await process_frame
			var campaign_cards: Array[Node] = []
			_collect_name_prefix(instance, "AchievementCard", campaign_cards)
			_ok(campaign_cards.size() == 6, "campaign category filters the achievement list")
			category_all = instance.find_child("AchievementCategoryButton_all", true, false) as Button
			category_all.pressed.emit()
			for _frame in 4:
				await process_frame
		if _state_has_achievements(game.current_state()):
			var achievement_definitions: Array = instance.call("_achievement_definitions")
			var claimable_id := String((achievement_definitions[0] as Dictionary).get("achievement_id", (achievement_definitions[0] as Dictionary).get("id", "")))
			var active_id := String((achievement_definitions[1] as Dictionary).get("achievement_id", (achievement_definitions[1] as Dictionary).get("id", "")))
			var claimed_id := String((achievement_definitions[2] as Dictionary).get("achievement_id", (achievement_definitions[2] as Dictionary).get("id", "")))
			var achievement_state := game.current_state().achievements as Dictionary
			achievement_state["progress"] = {
				claimable_id: 1,
				active_id: 0,
				claimed_id: 1,
			}
			achievement_state["completed"] = {
				claimable_id: {"achievement_id": claimable_id},
				claimed_id: {"achievement_id": claimed_id},
			}
			achievement_state["claimed"] = {
				claimed_id: {"achievement_id": claimed_id},
			}
			instance.call("_show_achievements")
			for _frame in 6:
				await process_frame
			var claimable_button := instance.find_child("AchievementClaimButton_%s" % _safe_node_suffix(claimable_id), true, false) as Button
			var active_achievement_button := instance.find_child("AchievementClaimButton_%s" % _safe_node_suffix(active_id), true, false) as Button
			var claimed_achievement_button := instance.find_child("AchievementClaimButton_%s" % _safe_node_suffix(claimed_id), true, false) as Button
			_ok(claimable_button != null and not claimable_button.disabled and claimable_button.text == "领取", "completed achievement exposes claim button")
			_ok(active_achievement_button != null and active_achievement_button.disabled and active_achievement_button.text == "进行中", "active achievement exposes disabled progress state")
			_ok(claimed_achievement_button != null and claimed_achievement_button.disabled and claimed_achievement_button.text == "已领取", "claimed achievement exposes claimed state")
	instance.call("_show_expedition")
	for _frame in 4:
		await process_frame
	var counter_hint := instance.find_child("StageCounterHint", true, false) as Label
	var unlock_preview := instance.find_child("StageUnlockPreview", true, false) as Label
	var chapter_feedback := instance.find_child("StageChapterFeedback", true, false) as Label
	var expedition_map_panel := instance.find_child("ExpeditionMapPanel", true, false) as Control
	var expedition_detail_panel := instance.find_child("ExpeditionDetailPanel", true, false) as Control
	var map_scroll := instance.find_child("MapScrollContainer", true, false) as ScrollContainer
	var expedition_back_button := instance.find_child("ExpeditionBackButton", true, false) as Button
	var start_battle_button := instance.find_child("StartBattleButton", true, false) as Button
	_ok(expedition_map_panel != null, "expedition exposes map panel node")
	_ok(expedition_detail_panel != null, "expedition exposes detail panel node")
	_ok(map_scroll != null and map_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "expedition map disables horizontal scrolling")
	_ok(map_scroll != null and map_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "expedition map keeps vertical scrolling")
	_ok(start_battle_button != null, "expedition exposes start battle button")
	_ok(expedition_back_button != null and expedition_back_button.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "expedition back button is touch sized at mobile landscape")
	_ok(start_battle_button != null and start_battle_button.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "expedition start button is touch sized at mobile landscape")
	if expedition_map_panel != null and expedition_detail_panel != null:
		_ok(expedition_map_panel.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "expedition map expands horizontally")
		_ok(expedition_detail_panel.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "expedition detail expands horizontally")
		_ok(absf(expedition_map_panel.size_flags_stretch_ratio - 0.45) <= 0.01, "expedition map uses 45 percent stretch ratio")
		_ok(absf(expedition_detail_panel.size_flags_stretch_ratio - 0.55) <= 0.01, "expedition detail uses 55 percent stretch ratio")
	var chapter_rows: Array[Node] = []
	_collect_name_prefix(instance, "ChapterStageRow", chapter_rows)
	_ok(chapter_rows.size() == 5, "expedition renders five chapter rows, got %d" % chapter_rows.size())
	for row_node in chapter_rows:
		var row := row_node as HBoxContainer
		if row == null:
			_fail("chapter row is an HBoxContainer")
			continue
		var stage_buttons := _stage_buttons_in_row(row)
		_ok(stage_buttons.size() == 5, "chapter row keeps five stage buttons visible, got %d in %s" % [stage_buttons.size(), String(row.name)])
		if map_scroll != null:
			_ok(_combined_child_min_width(row) <= map_scroll.size.x + 1.0, "chapter row combined minimum fits map scroll width")
		for stage_button in stage_buttons:
			_ok(stage_button.custom_minimum_size.y * 390.0 / 720.0 >= 44.0, "stage button remains touch sized at 390px landscape height")
	_ok(counter_hint != null and not counter_hint.text.is_empty(), "expedition detail shows counter hint")
	_ok(unlock_preview != null and not unlock_preview.text.is_empty(), "expedition detail shows unlock preview")
	_ok(chapter_feedback != null and not chapter_feedback.text.is_empty(), "expedition detail shows chapter feedback")
	if game != null:
		var failed_state: RefCounted = game.current_state().deep_clone()
		failed_state.stage_progress["cleared_stages"] = []
		failed_state.stage_progress["highest_unlocked_stage"] = "stage_1_1"
		failed_state.attempt_counters["stage_1_1"] = 1
		failed_state.factory.blueprints["heavy.armored"] = true
		failed_state.factory.production_queue.clear()
		var failed_action: Dictionary = instance.call("_derive_next_action", failed_state, 2000)
		_ok(failed_action["target"] == "factory", "first failure with counter blueprint routes to factory production")
		failed_state.factory.production_queue.append({
			"order_id": "production_test_ready",
			"recipe_id": "heavy.armored",
			"started_at_unix": 1000,
			"completes_at_unix": 1001,
		})
		var ready_action: Dictionary = instance.call("_derive_next_action", failed_state, 2000)
		_ok(String(ready_action["title"]).contains("领取"), "ready production takes priority over other guidance")
		var next_stage_state: RefCounted = game.current_state().deep_clone()
		next_stage_state.stage_progress["cleared_stages"] = ["stage_1_1"]
		next_stage_state.stage_progress["highest_unlocked_stage"] = "stage_1_2"
		next_stage_state.attempt_counters.clear()
		var next_stage_action: Dictionary = instance.call("_derive_next_action", next_stage_state, 2000)
		_ok(next_stage_action["target"] == "expedition", "unattempted unlocked stage still routes to expedition")
		_ok(next_stage_action["title"] == "推进下一关", "unattempted unlocked stage keeps explicit progression guidance")
		_ok(next_stage_action["stage_id"] == "stage_1_2", "unattempted unlocked stage keeps highest stage id")
		next_stage_state.attempt_counters["stage_1_2"] = 1
		next_stage_state.factory.blueprints["heavy.armored"] = true
		next_stage_state.factory.production_queue.clear()
		var stuck_stage_action: Dictionary = instance.call("_derive_next_action", next_stage_state, 2000)
		_ok(stuck_stage_action["target"] == "factory", "failed highest stage routes to factory guidance")
		_ok(stuck_stage_action["stage_id"] == "stage_1_2", "failed highest stage keeps highest stage id for guidance")
		var bomber_stage_config := StageCatalog.stage("stage_2_4")
		var bomber_recipe_ids := _recipe_ids_from_stage_config(bomber_stage_config)
		if bomber_recipe_ids.has("flying.bomber"):
			var bomber_state: RefCounted = game.current_state().deep_clone()
			bomber_state.stage_progress["cleared_stages"] = ["stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5", "stage_2_1", "stage_2_2", "stage_2_3"]
			bomber_state.stage_progress["highest_unlocked_stage"] = "stage_2_4"
			bomber_state.attempt_counters.clear()
			bomber_state.attempt_counters["stage_2_4"] = 1
			bomber_state.factory.blueprints["heavy.armored"] = true
			bomber_state.factory.blueprints["flying.bomber"] = true
			bomber_state.factory.production_queue.clear()
			var bomber_action: Dictionary = instance.call("_derive_next_action", bomber_state, 2000)
			_ok(bomber_action["target"] == "factory", "stage 2-4 bomber guidance routes to factory when bomber count is short")
			_ok(String(bomber_action["title"]).contains("自爆飞行") or String(bomber_action["body"]).contains("自爆飞行"), "stage 2-4 bomber metadata recommends bomber instead of armor")
		instance.call("_show_result", {
			"outcome": "victory",
			"reason": "core_destroyed",
			"stage_id": "stage_1_1",
			"stage_reached": 2,
			"structures_destroyed": 7,
			"cannon_suppression_count": 2,
			"cannon_hit_count": 3,
		}, {
			"stage_id": "stage_1_1",
			"reward": {"gold": 80, "xp_books": 1, "porcelain": 24, "parts": 16, "sludge": 12, "salvage": 9},
			"unlocked_blueprints": [],
			"next_stage_id": "stage_1_2",
		})
		for _frame in 4:
			await process_frame
		var victory_report_title := instance.find_child("ResultReportTitle", true, false) as Label
		var victory_salvage := instance.find_child("ResultSalvageLabel", true, false) as Label
		var victory_cannon_report := instance.find_child("ResultCannonReportLabel", true, false) as Label
		_ok(victory_report_title != null and victory_report_title.text == "战术战报", "victory result labels tactical battle report")
		_ok(victory_cannon_report != null and victory_cannon_report.text.contains("本局压制巨炮 2 次 / 炮击命中 3 次"), "victory result displays cannon tactical report")
		_ok(victory_salvage != null and victory_salvage.text.contains("+9"), "first victory result displays current salvage reward")
		var revision_before_result_cta := int(game.current_state().revision)
		instance.call("_show_result", {
			"outcome": "defeat",
			"reason": "timeout",
			"stage_id": "stage_1_1",
			"stage_reached": 1,
			"structures_destroyed": 1,
			"cannon_suppression_count": 1,
			"cannon_hit_count": 4,
		}, {})
		for _frame in 4:
			await process_frame
		var result_panel := instance.find_child("ResultPanel", true, false) as Control
		var result_report_title := instance.find_child("ResultReportTitle", true, false) as Label
		var result_cannon_report := instance.find_child("ResultCannonReportLabel", true, false) as Label
		var result_recommended := instance.find_child("ResultRecommendedButton", true, false) as Button
		var result_camp := instance.find_child("ResultCampButton", true, false) as Button
		_ok(result_panel != null, "result screen exposes result panel")
		_ok(result_report_title != null and result_report_title.text == "战术战报", "defeat result labels tactical battle report")
		_ok(result_cannon_report != null and result_cannon_report.text.contains("本局压制巨炮 1 次 / 炮击命中 4 次"), "defeat result displays cannon tactical report")
		_ok(result_recommended != null and not result_recommended.text.is_empty(), "defeat result renders one recommended action")
		_ok(result_camp != null, "result screen keeps camp action")
		if result_recommended != null and result_camp != null:
			_ok(result_recommended.custom_minimum_size.y >= 44.0, "result recommended action is touch sized")
			_ok(result_camp.custom_minimum_size.y >= 44.0, "result camp action is touch sized")
		if result_recommended != null:
			result_recommended.pressed.emit()
		for _frame in 4:
			await process_frame
		_ok(int(game.current_state().revision) == revision_before_result_cta, "defeat result recommendation only navigates and does not change revision")
	instance.call("_show_camp")
	for _frame in 4:
		await process_frame
	instance.call("_show_settings", 1)
	for _frame in 4:
		await process_frame
	var volume_slider := instance.find_child("SettingsMasterVolumeSlider", true, false) as HSlider
	var quality_option := instance.find_child("SettingsEffectsQualityOption", true, false) as OptionButton
	var reduced_toggle := instance.find_child("SettingsReducedMotionToggle", true, false) as CheckButton
	var global_auto_toggle := instance.find_child("SettingsGlobalAutoSkillToggle", true, false) as CheckButton
	var save_button := instance.find_child("SettingsSaveButton", true, false) as Button
	_ok(volume_slider != null and volume_slider.custom_minimum_size.y >= 44.0, "settings volume slider is mobile touch sized")
	_ok(quality_option != null and quality_option.item_count == 3, "settings quality selector exposes low/medium/high")
	_ok(reduced_toggle != null and reduced_toggle.custom_minimum_size.y >= 44.0, "reduced-motion toggle is mobile touch sized")
	_ok(global_auto_toggle != null and not global_auto_toggle.button_pressed, "global auto skill defaults off in settings UI")
	if volume_slider != null:
		volume_slider.value = 37.0
	if quality_option != null:
		quality_option.select(2)
		quality_option.item_selected.emit(2)
	if reduced_toggle != null:
		reduced_toggle.button_pressed = true
	if global_auto_toggle != null:
		global_auto_toggle.button_pressed = true
	if save_button != null:
		save_button.pressed.emit()
	var settings_store: RefCounted = instance.get("settings_store")
	_ok(settings_store != null, "main owns SettingsStore")
	if settings_store != null:
		_ok(settings_store.master_volume == 37, "settings UI writes master volume into store")
		_ok(settings_store.effects_quality == "high", "settings UI writes effects quality into store")
		_ok(settings_store.reduced_motion, "settings UI writes reduced motion into store")
		_ok(settings_store.global_auto_skill, "settings UI writes global auto skill into store")
	instance.call("_start_battle")
	for _frame in 8:
		await process_frame
	var battle_bottom_hud := instance.find_child("BattleBottomHud", true, false) as Control
	var battle_skill_grid := instance.find_child("BattleSkillGrid", true, false) as GridContainer
	var cannon_label := instance.find_child("CannonSuppressionLabel", true, false) as Label
	_ok(battle_bottom_hud != null, "battle exposes bottom HUD")
	_ok(battle_skill_grid != null and battle_skill_grid.columns == 6, "battle skill grid uses six columns")
	_ok(cannon_label != null, "battle exposes cannon suppression label")
	if cannon_label != null:
		instance.call("_apply_cannon_suppression_hud", {
			"stage_id": "stage_1_5",
			"tick": 120,
			"warnings": [{"suppression_current": 2, "suppression_target": 4, "impact_tick": 125}],
		})
		_ok(cannon_label.text.contains("巨炮压制 2/4 · 1.0秒"), "boss cannon suppression warning renders current target and seconds")
		instance.call("_apply_cannon_suppression_hud", {"stage_id": "stage_1_5", "warnings": []})
		_ok(cannon_label.text == "巨炮待机", "boss cannon clears to standby after warning resolves")
		instance.call("_apply_cannon_suppression_hud", {"stage_id": "stage_1_1", "warnings": [{"impact_tick": 90, "tick": 60}]})
		_ok(cannon_label.text == "炮击预警 1", "normal stage keeps compact bombardment warning")
	_ok(instance.find_child("CannonSuppressButton", true, false) == null, "cannon suppression HUD adds no new battle operation button")
	var skill_buttons: Array[Node] = []
	var auto_toggles: Array[Node] = []
	_collect_named(instance, "SkillButton", skill_buttons)
	_collect_named(instance, "AutoSkillToggle", auto_toggles)
	_ok(skill_buttons.size() == 6, "battle exposes six manual skill buttons")
	_ok(auto_toggles.size() == 6, "battle exposes six auto skill toggles")
	for button_node in skill_buttons:
		var skill_button := button_node as Control
		_ok(
			skill_button != null and skill_button.custom_minimum_size.y * mobile_canvas_scale >= 44.0,
			"manual skill button remains at least 44px after 844x390 canvas scaling"
		)
	for toggle_node in auto_toggles:
		var auto_toggle := toggle_node as Control
		_ok(
			auto_toggle != null and auto_toggle.custom_minimum_size.y * mobile_canvas_scale >= 44.0,
			"auto skill toggle remains at least 44px after 844x390 canvas scaling"
		)
	var battle_world: Node = instance.get("battle_world")
	_ok(battle_world != null, "battle starts from UI smoke with settings applied")
	if battle_world != null and battle_world.has_method("get_battle_snapshot"):
		var snapshot: Dictionary = battle_world.get_battle_snapshot()
		var all_auto := true
		for unit_value in snapshot.get("units", []):
			var unit := unit_value as Dictionary
			if int(unit.get("team", 0)) == 0 and int(unit.get("slot", 99)) < 6:
				all_auto = all_auto and bool(unit.get("auto_skill", false))
		_ok(all_auto, "global auto skill is explicitly applied to battle units")
	var web_runtime: Node = instance.get("web_runtime")
	if web_runtime != null:
		web_runtime.set_focus_state(false)
		for _frame in 2:
			await process_frame
		_ok(bool(instance.get("battle_is_paused")), "runtime focus loss pauses battle")
		web_runtime.set_focus_state(true)
		for _frame in 2:
			await process_frame
		_ok(bool(instance.get("battle_is_paused")), "runtime focus return does not auto-resume battle")
	instance.call("_show_factory")
	for _frame in 4:
		await process_frame
	var machine := instance.get_node_or_null("WorldHost/FactoryMachine_0")
	var factory_ui := instance.get_node("Interface/UIRoot").get_child(-1)
	var salvage_panel := instance.find_child("SalvageExchangePanel", true, false) as Control
	var salvage_summary := instance.find_child("SalvageSummaryLabel", true, false) as Label
	var porcelain_exchange := instance.find_child("SalvageExchangeButton_porcelain_resupply", true, false) as Button
	var mixed_exchange := instance.find_child("SalvageExchangeButton_mixed_parts", true, false) as Button
	var training_exchange := instance.find_child("SalvageExchangeButton_training_cache", true, false) as Button
	_ok(salvage_panel != null, "factory exposes salvage exchange panel")
	_ok(salvage_summary != null and salvage_summary.text.contains("残骸"), "factory shows salvage balance")
	_ok(porcelain_exchange != null and mixed_exchange != null and training_exchange != null, "factory renders three fixed salvage exchanges")
	if game != null:
		var salvage_before := _current_salvage_balance(game.current_state())
		if porcelain_exchange != null:
			_ok(porcelain_exchange.disabled == (salvage_before < 8), "porcelain salvage exchange disabled state follows balance")
			if _state_has_salvage(game.current_state()) and salvage_before >= 8 and not porcelain_exchange.disabled:
				porcelain_exchange.pressed.emit()
				for _frame in 6:
					await process_frame
				var refreshed_summary := instance.find_child("SalvageSummaryLabel", true, false) as Label
				_ok(refreshed_summary != null and _current_salvage_balance(game.current_state()) < salvage_before, "salvage exchange command refreshes balance")
	_ok(machine != null, "factory view builds its 3D production machinery")
	await create_timer(0.65).timeout
	_ok(is_instance_valid(machine) and machine == instance.get_node_or_null("WorldHost/FactoryMachine_0"), "factory countdown refresh preserves machine and tween instances")
	_ok(is_instance_valid(factory_ui) and factory_ui.get_parent() != null, "factory countdown refresh preserves the current UI tree and interaction state")
	instance.call("_play_factory_claim_feedback", "smoke_hero", "ordinary.assault")
	await create_timer(0.22).timeout
	_ok(is_instance_valid(machine) and machine == instance.get_node_or_null("WorldHost/FactoryMachine_0"), "claim feedback runs against the existing factory world")
	_ok(instance.get_node_or_null("WorldHost/FactoryReveal") != null, "claim feedback exposes the produced hero before refresh")
	await create_timer(0.55).timeout
	_ok(is_instance_valid(machine), "full claim tween completes without an intermediate factory rebuild")
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("UI SMOKE TESTS PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("UI SMOKE TESTS FAIL: %d failure(s)" % failures.size())
	quit(1)


func _ok(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fail(message: String) -> void:
	failures.append(message)


func _collect_named(node: Node, target_name: String, output: Array[Node]) -> void:
	if node.name == target_name:
		output.append(node)
	for child in node.get_children():
		_collect_named(child, target_name, output)


func _collect_name_prefix(node: Node, target_prefix: String, output: Array[Node]) -> void:
	if String(node.name).contains(target_prefix):
		output.append(node)
	for child in node.get_children():
		_collect_name_prefix(child, target_prefix, output)


func _stage_buttons_in_row(row: HBoxContainer) -> Array[Button]:
	var buttons: Array[Button] = []
	for child in row.get_children():
		if String(child.name).contains("StageButton") and child is Button:
			buttons.append(child as Button)
	return buttons


func _combined_child_min_width(row: HBoxContainer) -> float:
	var total := 0.0
	var controls := 0
	for child in row.get_children():
		var control := child as Control
		if control == null:
			continue
		total += control.custom_minimum_size.x
		controls += 1
	if controls > 1:
		total += float(row.get_theme_constant("separation")) * float(controls - 1)
	return total


func _recipe_ids_from_stage_config(stage_config: Dictionary) -> Array[String]:
	var recipe_ids: Array[String] = []
	for key in ["recommended_recipe_ids", "fallback_recipe_ids"]:
		for recipe_value in stage_config.get(key, []):
			var recipe_id := String(recipe_value)
			if not recipe_ids.has(recipe_id):
				recipe_ids.append(recipe_id)
	return recipe_ids


func _state_has_salvage(state: RefCounted) -> bool:
	if state == null:
		return false
	if state.get("inventory") != null:
		var inventory := state.inventory as Dictionary
		var items := inventory.get("items", {}) as Dictionary
		if items.has("alliance_scrap"):
			return true
	if state.get("salvage") != null:
		return true
	if state.get("economy") != null and state.economy.get("salvage") != null:
		return true
	if state.get("factory") != null and state.factory.get("salvage") != null:
		return true
	return false


func _current_salvage_balance(state: RefCounted) -> int:
	if state == null:
		return 0
	if state.get("inventory") != null:
		var inventory := state.inventory as Dictionary
		var items := inventory.get("items", {}) as Dictionary
		if items.has("alliance_scrap"):
			return int(items["alliance_scrap"])
	if state.get("salvage") != null:
		return int(state.get("salvage"))
	if state.get("economy") != null and state.economy.get("salvage") != null:
		return int(state.economy.get("salvage"))
	if state.get("factory") != null and state.factory.get("salvage") != null:
		return int(state.factory.get("salvage"))
	return 0


func _state_has_achievements(state: RefCounted) -> bool:
	return state != null and state.get("achievements") != null


func _safe_node_suffix(value: String) -> String:
	return value.replace(".", "_").replace(":", "_").replace("/", "_")


func _cleanup_settings(path: String) -> void:
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
