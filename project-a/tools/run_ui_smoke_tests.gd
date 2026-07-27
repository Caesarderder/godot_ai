extends SceneTree

const MobileViewportAdapter := preload("res://game/scripts/platform/mobile_viewport_adapter.gd")

const StageCatalog := preload("res://game/scripts/domain/content/stage_catalog.gd")
const NotificationSummary := preload("res://game/scripts/presentation/notification_summary.gd")
const HeroGenerator := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const TEST_SAVE_PATH := "user://ui_smoke_test_save.json"

var failures: Array[String] = []
var _test_instance: Node
var _finishing: bool = false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_settings("user://settings.cfg")
	_cleanup_settings("user://local_playtest_session.json")
	_cleanup_settings(TEST_SAVE_PATH)
	var game_autoload := root.get_node_or_null("/root/Game")
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if game_autoload != null and save_manager != null:
		save_manager.configure_save_path(TEST_SAVE_PATH)
		game_autoload.bootstrap_with_manager(save_manager, 20260725, 1000)
	DisplayServer.window_set_size(Vector2i(844, 390))
	var scene := load("res://scenes/screens/main.tscn") as PackedScene
	if scene == null:
		_fail("main scene loads")
		_finish()
		return
	var instance := scene.instantiate()
	_test_instance = instance
	root.add_child(instance)
	for _frame in 20:
		await process_frame
	var audio_director := instance.get_node_or_null("AudioDirector")
	if audio_director != null and audio_director.has_method("set_playback_enabled"):
		audio_director.call("set_playback_enabled", false)
	if instance.has_method("_show_base"):
		await _run_slg_shell_smoke(instance, game_autoload)
		_finish()
		return
	_ok(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 844, "project uses the 844px mobile-landscape design width")
	_ok(int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 390, "project uses the 390px mobile-landscape design height")
	_ok(int(ProjectSettings.get_setting("display/window/size/window_width_override")) == 844, "project previews the 844px target width")
	_ok(int(ProjectSettings.get_setting("display/window/size/window_height_override")) == 390, "project previews the 390px target height")
	_ok(String(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility", "project keeps Compatibility renderer")
	_ok(root.size == Vector2i(844, 390), "viewport remains 844x390")
	var mobile_canvas_scale := 390.0 / float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	_ok(instance.get_node_or_null("WorldHost") != null, "main scene has 3D host")
	_ok(instance.get_node_or_null("Interface/UIRoot") != null, "main scene has UI root")
	_ok(root.get_child_count() > 0, "main scene stays alive for mobile landscape smoke")
	_ok(instance.find_child("TitleSettingsButton", true, false) != null, "title screen exposes settings entry")
	var title_primary := instance.find_child("TitlePrimaryButton", true, false) as Button
	_ok(title_primary != null and title_primary.text == "开始进攻", "fresh title exposes one-click opening battle")
	if title_primary != null:
		title_primary.pressed.emit()
		for _frame in 4:
			await process_frame
		_ok(instance.get("app_state") == 7 and instance.get("battle_world") != null, "title primary action enters the first battle without an intermediate menu")
	instance.call("_show_camp")
	for _frame in 4:
		await process_frame
	_ok(instance.find_child("CampSettingsButton", true, false) != null, "camp actions expose settings entry")
	_ok(instance.find_child("TopBarSettingsButton", true, false) != null, "camp top bar exposes settings entry")
	var global_resources := instance.find_child("GlobalCoreResourceHUD", true, false) as Control
	_ok(global_resources != null and global_resources.is_visible_in_tree(), "management screens keep core resources visible in the global top bar")
	_ok(
		global_resources != null and global_resources.get_global_rect().get_center().x > root.size.x * 0.5,
		"global core resources stay in the right half of the header"
	)
	for resource_id in ["toilet_coins", "hero_shards", "porcelain", "recruit_tickets"]:
		_ok(
			global_resources != null
				and global_resources.find_child("Resource_%s" % resource_id, true, false) != null,
			"global top bar exposes core resource %s" % resource_id
		)
	for retired_id in ["industrial_tech", "skill_chips", "parts", "sludge"]:
		_ok(
			global_resources == null
				or global_resources.find_child("Resource_%s" % retired_id, true, false) == null,
			"global top bar does not project retired resource %s" % retired_id
		)
	var tutorial_step := instance.find_child("TutorialStepLabel", true, false) as Label
	var tutorial_hint := instance.find_child("TutorialHintLabel", true, false) as Label
	var tutorial_progress := instance.find_child("TutorialProgressBar", true, false) as ProgressBar
	var objective_panel := instance.find_child("CampObjectivePanel", true, false) as Control
	var reveal_systems := instance.find_child("CampRevealSystemsButton", true, false) as Button
	var camp_factory := instance.find_child("CampFactoryButton", true, false) as Button
	var camp_cultivation := instance.find_child("CampCultivationButton", true, false) as Button
	var camp_formation := instance.find_child("CampFormationButton", true, false) as Button
	var camp_expedition := instance.find_child("CampExpeditionButton", true, false) as Button
	var goal_entry := instance.find_child("QuestEntryButton", true, false) as Button
	var factory_badge := instance.find_child("FactoryNotificationBadge", true, false) as Control
	var goal_badge := instance.find_child("GoalNotificationBadge", true, false) as Control
	var legacy_goal_entry := instance.find_child("GoalEntryButton", true, false) as Button
	_ok(tutorial_step != null and tutorial_step.text.contains("3/3"), "new save starts ready for the persistent siege loop")
	_ok(tutorial_hint != null and tutorial_hint.text.contains("胜利") and tutorial_hint.text.contains("失败"), "onboarding teaches the core reward-risk rule")
	_ok(tutorial_progress != null and is_equal_approx(tutorial_progress.value, 3.0), "onboarding shows compact visual progress")
	_ok(objective_panel != null and objective_panel.size_flags_stretch_ratio > 0.6, "camp gives the current objective primary visual weight")
	_ok(camp_expedition != null and camp_expedition.visible, "new save exposes the expedition needed by the current lesson")
	_ok(camp_factory != null and not camp_factory.visible, "new save defers factory from the initial action area")
	_ok(camp_cultivation != null and not camp_cultivation.visible, "new save defers cultivation from the initial action area")
	_ok(camp_formation != null and camp_formation.visible, "new save exposes formation as a core factory-loop action")
	_ok(goal_entry != null and goal_entry.visible, "new save exposes tasks and free battle pass as long-term goals")
	_ok(factory_badge != null and not factory_badge.visible, "factory notification badge starts hidden without ready production")
	_ok(goal_badge != null and goal_badge.visible and String(goal_badge.get("text")) == "1", "goal notification badge exposes the level-one starter merit reward")
	if game_autoload != null:
		var notification_state: RefCounted = game_autoload.current_state().deep_clone()
		notification_state.factory.production_queue.append({
			"order_id": "notification_ready",
			"recipe_id": "ordinary.assault",
			"started_at_unix": 1000,
			"completes_at_unix": 1001,
		})
		notification_state.quests["completed"] = {"quest_ready": {}}
		notification_state.quests["claimed"] = {}
		notification_state.achievements["completed"] = {"achievement_ready": {}}
		notification_state.achievements["claimed"] = {}
		var notification_summary: Dictionary = NotificationSummary.derive(notification_state, 2000)
		_ok(int(notification_summary["factory_ready"]) == 1, "notification summary counts ready factory orders")
		_ok(int(notification_summary["quest_claimable"]) == 1, "notification summary counts unclaimed quests")
		_ok(int(notification_summary["achievement_claimable"]) == 1, "notification summary counts unclaimed achievements")
		_ok(int(notification_summary["goal_claimable"]) == 2 and int(notification_summary["total"]) == 3, "notification summary aggregates goal and global counts")
	if camp_factory != null:
		instance.call("_set_notification_badge", camp_factory, 3, "FactoryNotificationBadge")
		factory_badge = instance.find_child("FactoryNotificationBadge", true, false) as Control
		_ok(factory_badge != null and factory_badge.visible and String(factory_badge.get("text")) == "3", "notification badge displays a visible actionable count")
		instance.call("_set_notification_badge", camp_factory, 0, "FactoryNotificationBadge")
		_ok(not factory_badge.visible, "notification badge hides when the actionable count reaches zero")
	var revision_before_reveal := int(instance.get("game").current_state().revision)
	if reveal_systems != null:
		reveal_systems.pressed.emit()
	for _frame in 4:
		await process_frame
	_ok(int(instance.get("game").current_state().revision) == revision_before_reveal, "revealing all systems does not change revision")
	_ok((instance.find_child("CampFactoryButton", true, false) as Button).visible, "revealing systems exposes factory without a hard lock")
	_ok((instance.find_child("QuestEntryButton", true, false) as Button).visible, "revealing systems exposes target center without a hard lock")
	_ok((instance.find_child("CampGoldShopButton", true, false) as Button).visible, "revealing systems exposes blueprint research")
	goal_entry = instance.find_child("QuestEntryButton", true, false) as Button
	_ok(goal_entry != null or legacy_goal_entry != null, "camp exposes one goal center entry")
	if goal_entry != null:
		_ok(goal_entry.text == "目标", "camp goal entry is labeled target")
		_ok(goal_entry.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "camp goal entry is touch-sized")
		_ok(instance.find_child("GoalEntryButton", true, false) == null, "camp keeps a single target entry node")
	var top_resources := instance.find_child("TopResourceSummaryLabel", true, false) as Label
	_ok(top_resources != null and top_resources.text.contains("马桶币") and top_resources.text.contains("马桶钻"), "top resource summary displays both target currencies")
	_ok(top_resources != null and top_resources.text.contains("战功Lv"), "top resource summary displays war merit rank")
	var objective_title := instance.find_child("ObjectiveTitle", true, false) as Label
	var objective_button := instance.find_child("CampObjectiveButton", true, false) as Button
	_ok(objective_title != null and objective_title.text == "推进下一关", "new save objective points to the first factory-loop expedition")
	_ok(instance.find_child("ObjectiveBody", true, false) == null, "camp does not duplicate the objective with explanatory copy")
	instance.call("_show_factory")
	for _frame in 6:
		await process_frame
	var factory_scroll_entry := instance.find_child("FactoryScrollContainer", true, false) as ScrollContainer
	var draw_entry := instance.find_child("BlueprintDrawPanel", true, false) as Control
	_ok(factory_scroll_entry != null and factory_scroll_entry.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "factory research disables horizontal scrolling")
	_ok(draw_entry != null, "research entry routes to the blueprint draw panel")
	var game: Node = instance.get("game")
	if game != null:
		instance.call("_show_factory")
		for _frame in 6:
			await process_frame
		var draw_panel := instance.find_child("BlueprintDrawPanel", true, false) as Control
		var single_draw := instance.find_child("BlueprintDrawSingleButton", true, false) as Button
		var ten_draw := instance.find_child("BlueprintDrawTenButton", true, false) as Button
		_ok(draw_panel != null, "factory renders toilet-gem blueprint research")
		_ok(single_draw != null and single_draw.text.contains("160"), "factory exposes single blueprint draw price")
		_ok(ten_draw != null and ten_draw.text.contains("1440"), "factory exposes ten-draw price")
		var factory_scroll := instance.find_child("FactoryScrollContainer", true, false) as ScrollContainer
		if factory_scroll != null:
			factory_scroll.scroll_vertical = 180
			for _frame in 2:
				await process_frame
			var scroll_before_rebuild := factory_scroll.scroll_vertical
			instance.call("_show_factory")
			for _frame in 6:
				await process_frame
			var rebuilt_scroll := instance.find_child("FactoryScrollContainer", true, false) as ScrollContainer
			_ok(scroll_before_rebuild > 0 and rebuilt_scroll != null and rebuilt_scroll.scroll_vertical == scroll_before_rebuild, "factory rebuild preserves vertical scroll position")
		instance.call("_show_cultivation")
		for _frame in 6:
			await process_frame
		var cultivation_scroll := instance.find_child("CultivationScrollContainer", true, false) as ScrollContainer
		var tech_upgrade := instance.find_child("ModelTechUpgradeButton_ordinary_assault", true, false) as Button
		_ok(cultivation_scroll != null and cultivation_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "model tech disables horizontal overflow")
		_ok(tech_upgrade != null, "model tech renders the unlocked assault model")
		instance.call("_show_camp")
		for _frame in 4:
			await process_frame
		objective_button = instance.find_child("CampObjectiveButton", true, false) as Button
	var revision_before_cta := int(game.current_state().revision) if game != null else -1
	if objective_button != null:
		objective_button.pressed.emit()
	for _frame in 4:
		await process_frame
	var revision_after_cta := int(game.current_state().revision) if game != null else -2
	_ok(revision_after_cta == revision_before_cta, "camp objective CTA only navigates and does not change revision")
	var first_battle_brief := instance.find_child("FirstBattleTutorialBrief", true, false) as Label
	_ok(first_battle_brief != null and first_battle_brief.text.contains("Gman") and first_battle_brief.text.contains("第 4 关"), "first expedition explains the solo opening and turret-wall transition")
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
		var merit_tab := instance.find_child("GoalTabWarMeritButton", true, false) as Button
		var war_merit := instance.find_child("QuestWarMeritLabel", true, false) as Label
		var campaign_card := instance.find_child("CampaignQuestCard", true, false) as Control
		var campaign_summary := instance.find_child("CampaignQuestSummaryLabel", true, false) as Label
		var campaign_title := instance.find_child("CampaignQuestTitleLabel", true, false) as Label
		var quest_top_settings := instance.find_child("TopBarSettingsButton", true, false) as Button
		var quest_back := instance.find_child("ManagementBackButton", true, false) as Button
		var loop_cards: Array[Node] = []
		_collect_name_prefix(instance, "LoopQuestCard", loop_cards)
		_ok(quests_scroll != null and quests_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "quests page disables horizontal scrolling")
		_ok(quest_tab != null and quest_tab.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "quests tab is touch-sized")
		_ok(instance.find_child("GoalTabAchievementsButton", true, false) == null, "legacy achievement economy is absent from the goal center")
		_ok(merit_tab != null and merit_tab.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "war merit reward tab is touch-sized")
		_ok(war_merit != null and war_merit.text.contains("Lv"), "quests page displays war merit level compactly")
		_ok(campaign_card != null, "quests page renders current campaign quest card")
		_ok(campaign_title != null and campaign_title.text.begins_with("大任务"), "campaign objective is visibly labeled as a major quest")
		_ok(campaign_summary != null and campaign_summary.text.contains("/"), "campaign quest keeps progress in one compact line")
		_ok(instance.find_child("QuestNoDailyCountdownLabel", true, false) == null, "quests page omits product-policy explanations")
		_ok(quest_top_settings != null and quest_top_settings.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "quests page top settings control is touch-sized")
		_ok(quest_back != null and quest_back.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "quests page back control is touch-sized")
		_ok(loop_cards.size() == 3, "quests page renders three loop quest cards")
		var first_loop_title := instance.find_child("LoopQuestTitleLabel_1", true, false) as Label
		_ok(first_loop_title != null and first_loop_title.text.begins_with("小任务"), "loop objective is visibly labeled as a minor quest")
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
		instance.call("_show_war_merit_track")
		for _frame in 6:
			await process_frame
		var merit_scroll := instance.find_child("WarMeritScrollContainer", true, false) as ScrollContainer
		var merit_overview := instance.find_child("WarMeritTrackOverviewLabel", true, false) as Label
		var merit_level_one := instance.find_child("WarMeritClaimButton_1", true, false) as Button
		var merit_level_three := instance.find_child("WarMeritClaimButton_3", true, false) as Button
		var merit_cards: Array[Node] = []
		_collect_name_prefix(instance, "WarMeritRewardCard", merit_cards)
		_ok(merit_scroll != null and merit_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "war merit track disables horizontal scrolling")
		_ok(merit_overview != null and merit_overview.text.contains("免费战令 Lv2") and merit_overview.text.contains("可领取 2"), "free battle pass shows reached level and claimable count")
		_ok(merit_level_one != null and not merit_level_one.disabled and merit_level_one.text == "领取", "reached war merit level exposes claim button")
		_ok(merit_level_three != null and merit_level_three.disabled and merit_level_three.text == "未解锁", "future war merit reward remains locked")
		_ok(merit_cards.size() == 30, "war merit track renders all thirty deterministic level rewards")
	instance.call("_show_expedition")
	for _frame in 4:
		await process_frame
	var counter_hint := instance.find_child("StageCounterHint", true, false) as Label
	var stage_power_label := instance.find_child("StagePowerLabel", true, false) as Label
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
			_ok(stage_button.custom_minimum_size.y * mobile_canvas_scale >= 44.0, "stage button remains touch sized at 390px landscape height")
	_ok(counter_hint != null and not counter_hint.text.is_empty(), "expedition detail shows counter hint")
	_ok(stage_power_label != null and stage_power_label.text.contains("军团战力") and stage_power_label.text.contains("推荐"), "expedition shows real formation and recommended power")
	instance.call("_show_camp")
	for _frame in 4:
		await process_frame
	var global_power_label := instance.find_child("GlobalPowerSummaryLabel", true, false) as Label
	_ok(global_power_label != null and global_power_label.text.contains("战力") and global_power_label.text.contains("推荐"), "camp top bar keeps current and target-stage recommended power visible")
	var positive_feedback := String(instance.call("_power_feedback_text", 4000, 4600, {}, {}))
	var reserve_feedback := String(instance.call("_power_feedback_text", 4600, 4600, {"reserve": 300}, {"reserve": 420}))
	var negative_feedback := String(instance.call("_power_feedback_text", 4600, 4300, {}, {}))
	_ok(positive_feedback.contains("+600") and positive_feedback.contains("4000") and positive_feedback.contains("4600"), "power feedback explains formation increase and before-after values")
	_ok(reserve_feedback.contains("单位战力 +120") and reserve_feedback.contains("军团战力 4600"), "reserve progression reports unit gain without overstating formation power")
	_ok(negative_feedback.contains("-300") and negative_feedback.contains("4300"), "formation power decrease is also explained")
	instance.call("_show_expedition")
	for _frame in 4:
		await process_frame
	_ok(instance.find_child("StageUnlockPreview", true, false) == null, "expedition omits secondary unlock copy")
	_ok(instance.find_child("StageChapterFeedback", true, false) == null, "expedition omits post-battle guidance before battle")
	if game != null:
		var failed_state: RefCounted = game.current_state().deep_clone()
		failed_state.stage_progress["cleared_stages"] = ["stage_1_1", "stage_1_2", "stage_1_3"]
		failed_state.stage_progress["highest_unlocked_stage"] = "stage_1_4"
		failed_state.attempt_counters["stage_1_4"] = 1
		failed_state.factory.discovered_blueprints["ordinary.assault"] = true
		failed_state.factory.production_queue.clear()
		var failed_action: Dictionary = instance.call("_derive_next_action", failed_state, 2000)
		_ok(failed_action["target"] == "expedition" and String(failed_action["title"]).contains("整备"), "failed stage routes to casualty-aware preparation")
		var failed_tutorial: Dictionary = instance.call("_derive_tutorial_step", failed_state, failed_action)
		_ok(int(failed_tutorial["step"]) == 3, "failed stage remains in the persistent siege loop")
		failed_state.factory.production_queue.append({
			"order_id": "production_test_ready",
			"recipe_id": "ordinary.assault",
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
		var completed_tutorial: Dictionary = instance.call("_derive_tutorial_step", next_stage_state, next_stage_action)
		_ok(int(completed_tutorial["step"]) == 3, "first victory keeps the player in the persistent siege loop")
		var turret_wall_state: RefCounted = game_autoload.current_state().deep_clone()
		turret_wall_state.stage_progress["highest_unlocked_stage"] = "stage_1_4"
		turret_wall_state.stage_progress["cleared_stages"] = ["stage_1_1", "stage_1_2", "stage_1_3"]
		turret_wall_state.attempt_counters["stage_1_4"] = 1
		turret_wall_state.factory.production_queue.clear()
		turret_wall_state.factory.discovered_blueprints.clear()
		turret_wall_state.factory.blueprint_research.clear()
		turret_wall_state.factory.blueprints["ordinary.assault"] = true
		turret_wall_state.factory.next_hero_sequence = 2
		var turret_wall_action: Dictionary = instance.call("_derive_next_action", turret_wall_state, 2000)
		_ok(turret_wall_action["target"] == "expedition", "stage 1-4 failure remains an explicit retry decision")
		_ok(String(turret_wall_action["body"]).contains("失败不发资源"), "stage 1-4 guidance explains the zero-reward failure rule")
		turret_wall_state.factory.next_hero_sequence = 11
		var reinforced_action: Dictionary = instance.call("_derive_next_action", turret_wall_state, 2000)
		_ok(reinforced_action["target"] == "expedition", "legacy production counters do not reopen removed merge progression")
		turret_wall_state.factory.blueprint_research = {
			"recipe_id": "ordinary.assault",
			"started_at_unix": 2000,
			"completes_at_unix": 2030,
		}
		var research_panel := instance.call("_build_blueprint_research_panel", turret_wall_state, 2010) as Control
		var tactical_debrief := research_panel.find_child("ResearchTacticalDebriefLabel", true, false) as Label
		_ok(tactical_debrief != null and tactical_debrief.text.contains("炮台") and tactical_debrief.text.contains("Gman"), "Doctor research wait includes the stage 1-4 tactical debrief")
		research_panel.free()
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
			_ok(bomber_action["target"] == "expedition", "stage 2-4 keeps the same casualty-aware retry contract")
			_ok(String(bomber_action["body"]).contains("型号科技"), "stage 2-4 guidance points to model technology instead of a scripted unit recipe")
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
			"reward": {"gold": 80, "xp_books": 0, "porcelain": 24, "parts": 16, "sludge": 12, "salvage": 9},
			"reward_tier": "first_victory",
			"unlocked_blueprints": [],
			"next_stage_id": "stage_1_2",
		})
		for _frame in 4:
			await process_frame
		var victory_report_title := instance.find_child("ResultReportTitle", true, false) as Label
		var victory_cannon_report := instance.find_child("ResultCannonReportLabel", true, false) as Label
		var victory_reward_label := instance.find_child("ResultRewardLabel", true, false) as Label
		_ok(victory_report_title != null and victory_report_title.text == "战况", "victory result uses a short player-facing heading")
		_ok(victory_cannon_report != null and victory_cannon_report.text.contains("本局压制巨炮 2 次 / 炮击命中 3 次"), "victory result displays cannon tactical report")
		_ok(victory_reward_label != null and victory_reward_label.text.contains("首次通关全额") and victory_reward_label.text.contains("马桶币"), "result explains reward tier and toilet-coin reward")
		instance.call("_show_result", {
			"outcome": "victory",
			"reason": "core_destroyed",
			"stage_id": "stage_1_4",
			"stage_reached": 2,
			"structures_destroyed": 4,
			"troop_damage_share_percent": 68,
			"assault_cleave_extra_hits": 5,
			"gman_survived": true,
		}, {
			"stage_id": "stage_1_4",
			"reward": {"gold": 71, "xp_books": 2, "porcelain": 29, "parts": 23, "sludge": 19},
			"unlocked_blueprints": ["heavy.armored"],
			"next_stage_id": "stage_1_5",
		})
		for _frame in 4:
			await process_frame
		var armor_choice := instance.find_child("ResultResearchArmorButton", true, false) as Button
		var boss_choice := instance.find_child("ResultChallengeNextButton", true, false) as Button
		_ok(armor_choice != null and boss_choice != null, "stage 1-4 revenge result offers research or immediate boss challenge")
		var revision_before_result_cta := int(game.current_state().revision)
		instance.call("_show_result", {
			"outcome": "defeat",
			"reason": "main_squad_defeated",
			"stage_id": "stage_1_4",
			"stage_reached": 1,
			"structures_destroyed": 1,
			"cannon_suppression_count": 1,
			"cannon_hit_count": 4,
			"gman_hp": 0,
			"gman_max_hp": 370,
		}, {})
		for _frame in 4:
			await process_frame
		var result_panel := instance.find_child("ResultPanel", true, false) as Control
		var result_report_title := instance.find_child("ResultReportTitle", true, false) as Label
		var result_cannon_report := instance.find_child("ResultCannonReportLabel", true, false) as Label
		var result_recommended := instance.find_child("ResultRecommendedButton", true, false) as Button
		var result_camp := instance.find_child("ResultCampButton", true, false) as Button
		var failure_debrief := instance.find_child("FailureDebriefPanel", true, false) as Control
		var gman_health := instance.find_child("ResultGmanHealthLabel", true, false) as Label
		_ok(result_panel != null, "result screen exposes result panel")
		_ok(result_report_title != null and result_report_title.text == "战况", "defeat result uses a short player-facing heading")
		_ok(gman_health != null and gman_health.text == "Gman 已阵亡", "stage failure explicitly explains that Gman was killed")
		_ok(result_cannon_report != null and result_cannon_report.text.contains("本局压制巨炮 1 次 / 炮击命中 4 次"), "defeat result displays cannon tactical report")
		_ok(result_recommended != null and not result_recommended.text.is_empty(), "defeat result renders one recommended action")
		_ok(result_camp != null, "result screen keeps camp action")
		_ok(failure_debrief != null, "stage 1-4 defeat renders a focused tactical debrief")
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
	var delete_save_button := instance.find_child("SettingsDeleteLocalSaveButton", true, false) as Button
	_ok(volume_slider != null and volume_slider.custom_minimum_size.y >= 44.0, "settings volume slider is mobile touch sized")
	_ok(quality_option != null and quality_option.item_count == 3, "settings quality selector exposes low/medium/high")
	_ok(reduced_toggle != null and reduced_toggle.custom_minimum_size.y >= 44.0, "reduced-motion toggle is mobile touch sized")
	_ok(global_auto_toggle != null and not global_auto_toggle.button_pressed, "global auto skill defaults off in settings UI")
	_ok(delete_save_button != null and delete_save_button.text == "删除本地存档", "settings exposes an explicit local-save delete action")
	_ok(delete_save_button != null and delete_save_button.custom_minimum_size.y >= 44.0, "local-save delete action is touch sized")
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
	var unit_hp_bars: Array[Node] = []
	var unit_energy_bars: Array[Node] = []
	_collect_name_prefix(instance, "BattleSkillButton_", skill_buttons)
	_collect_named(instance, "AutoSkillToggle", auto_toggles)
	_collect_named(instance, "BattleUnitHpBar", unit_hp_bars)
	_collect_named(instance, "BattleUnitEnergyBar", unit_energy_bars)
	_ok(skill_buttons.size() == 1, "opening battle exposes only Gman skill control")
	_ok(auto_toggles.size() == 1, "opening battle exposes only Gman auto-skill toggle")
	_ok(unit_hp_bars.size() == 1, "opening battle exposes only Gman health bar")
	_ok(unit_energy_bars.size() == 1, "opening battle exposes only Gman energy bar")
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
			if int(unit.get("team", 0)) == 0 and int(unit.get("slot", 99)) < 7:
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
	var draw_panel := instance.find_child("BlueprintDrawPanel", true, false) as Control
	var model_draw := instance.find_child("BlueprintDrawSingleButton", true, false) as Button
	_ok(draw_panel != null, "factory exposes blueprint draw panel")
	_ok(model_draw != null, "factory exposes toilet-gem research action")
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


func _run_slg_shell_smoke(instance: Node, game_autoload: Node) -> void:
	_ok(String(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility", "SLG shell keeps Compatibility renderer")
	_ok(instance.get_node_or_null("WorldHost") != null, "SLG shell has the 3D world host")
	_ok(instance.get_node_or_null("Interface/UIRoot") != null, "SLG shell has the UI root")
	var viewport_adapter := instance.find_child("MobileViewportAdapter", true, false)
	_ok(viewport_adapter != null, "SLG shell owns one reusable mobile viewport adapter")
	_ok(MobileViewportAdapter.classify(Vector2(568, 320)) == "compact_landscape", "568x320 uses compact landscape rules")
	_ok(MobileViewportAdapter.classify(Vector2(844, 390)) == "standard_landscape", "844x390 uses the design landscape rules")
	_ok(MobileViewportAdapter.classify(Vector2(1280, 540)) == "ultrawide_landscape", "1280x540 uses ultrawide landscape rules")
	_ok(MobileViewportAdapter.classify(Vector2(1024, 768)) == "tablet_landscape", "4:3 tablets use tablet landscape rules")
	var compact_snapshot := MobileViewportAdapter.build_snapshot(
		{"width": 568.0, "height": 320.0, "safe_left": 18.0, "safe_right": 18.0},
		Vector2(844, 390)
	)
	_ok(float(compact_snapshot["touch_target_height"]) > 48.0, "short screens enlarge logical controls to preserve 48 CSS pixels")
	var compact_margins := compact_snapshot["safe_margins"] as Vector4
	_ok(compact_margins.x > 12.0 and compact_margins.z > 12.0, "CSS safe-area insets convert into logical canvas margins")
	var orientation_gate := instance.find_child("LandscapeOrientationGate", true, false) as Control
	_ok(orientation_gate != null, "SLG shell owns a persistent landscape orientation gate")
	_ok(
		not bool(instance.call("_requires_landscape_gate", Vector2(844, 390))),
		"844x390 landscape keeps the game interactive"
	)
	_ok(
		bool(instance.call("_requires_landscape_gate", Vector2(390, 844))),
		"390x844 portrait is blocked with rotate-device guidance"
	)
	_ok(
		not bool(instance.call("_requires_landscape_gate", Vector2(1280, 540))),
		"ultrawide landscape remains supported"
	)
	_ok(game_autoload != null and String(game_autoload.current_state().content_version) == "toilet-factory-slg-v3-factions", "UI boots the faction-progression contract")
	_ok(instance.find_child("TitlePrimaryButton", true, false) != null, "SLG shell boots into a dedicated title screen")
	_ok(instance.find_child("TitleSettingsButton", true, false) != null, "title screen exposes settings before entering the campaign")
	_ok(instance.find_child("TitleHelpButton", true, false) != null, "title screen exposes gameplay help before entering the campaign")
	var music_director := instance.find_child("MusicDirector", true, false)
	_ok(
		music_director != null and music_director.current_state() == &"silent",
		"title stays silent before a player gesture unlocks Web audio"
	)
	var fresh_primary := instance.find_child("TitlePrimaryButton", true, false) as Button
	var title_summary := instance.find_child("TitleProgressSummary", true, false) as Label
	var title_objective := instance.find_child("TitleNextObjective", true, false) as Label
	_ok(fresh_primary != null and fresh_primary.text.contains("启动反攻"), "fresh save opens with an in-world counterattack action")
	_ok(title_summary != null and title_summary.text.contains("已夺回 0 座城镇"), "title summarizes durable progress in player-facing language")
	_ok(title_objective != null and title_objective.text.contains("摧毁联盟前哨 1-1"), "fresh title states the first concrete battle objective")
	var title_state: RefCounted = game_autoload.current_state()
	var original_cleared: Array = (title_state.stage_progress.get("cleared_stages", []) as Array).duplicate()
	var original_highest := String(title_state.stage_progress.get("highest_unlocked_stage", StageCatalog.DEFAULT_STAGE_ID))
	title_state.stage_progress["cleared_stages"] = ["stage_1_1"]
	title_state.stage_progress["highest_unlocked_stage"] = "stage_1_2"
	var returning_title := instance.call("_title_progress_snapshot") as Dictionary
	_ok(returning_title["primary_label"] == "返回指挥室" and String(returning_title["objective"]).contains("1-2"), "returning title routes to the next unlocked town")
	title_state.stage_progress["cleared_stages"] = StageCatalog.ACT1_STAGE_IDS.duplicate()
	title_state.stage_progress["highest_unlocked_stage"] = "endless_1"
	var completed_title := instance.call("_title_progress_snapshot") as Dictionary
	_ok(completed_title["primary_label"] == "重返前线", "completed campaign title exposes its endless continuation")
	title_state.stage_progress["cleared_stages"] = original_cleared
	title_state.stage_progress["highest_unlocked_stage"] = original_highest
	instance.call("_show_help", 1)
	await _wait_frames(3)
	var help_columns := instance.find_child("HelpLandscapeColumns", true, false) as HBoxContainer
	var help_gameplay_scroll := instance.find_child("HelpGameplayScroll", true, false) as ScrollContainer
	var help_info_scroll := instance.find_child("HelpInfoScroll", true, false) as ScrollContainer
	var help_back := instance.find_child("HelpBackButton", true, false) as Button
	_ok(instance.find_child("HelpScreen", true, false) != null, "gameplay help opens as a dedicated readable screen")
	_ok(help_columns != null and help_columns.get_child_count() == 2, "help uses two balanced landscape columns")
	_ok(help_gameplay_scroll != null and help_info_scroll != null, "both help columns scroll independently on short screens")
	_ok(_tree_has_text(instance, "选择建筑") and _tree_has_text(instance, "100%"), "help explains construction and manual battle skills")
	_ok(
		_tree_has_text(instance, "首次攻克 1-2、1-3")
			and _tree_has_text(instance, "冲锋二星")
			and _tree_has_text(instance, "装甲二星")
			and _tree_has_text(instance, "完全恢复"),
		"help explains the first hurdle, both recovery routes, and lossless failure"
	)
	_ok(_tree_has_text(instance, "不使用分析 SDK") and _tree_has_text(instance, "0.11.0-audio-feedback.1"), "help exposes local-data privacy and the running product version")
	_ok(help_back != null and help_back.custom_minimum_size.y >= 48.0, "help exposes a touch-sized return path")
	if help_back != null:
		help_back.pressed.emit()
		await _wait_frames(3)
	_ok(instance.find_child("TitlePrimaryButton", true, false) != null, "help returns to its title-screen entry")
	var title_primary := instance.find_child("TitlePrimaryButton", true, false) as Button
	if title_primary != null:
		var title_base_height := title_primary.custom_minimum_size.y
		instance.call("_apply_mobile_interactive_target_to_branch", instance.get_node("Interface/UIRoot"), 60.0)
		_ok(title_primary.custom_minimum_size.y >= 60.0, "live short-screen changes enlarge existing touch controls without rebuilding")
		instance.call("_apply_mobile_interactive_target_to_branch", instance.get_node("Interface/UIRoot"), 48.0)
		_ok(is_equal_approx(title_primary.custom_minimum_size.y, maxf(48.0, title_base_height)), "touch controls return to their design minimum after viewport recovery")
	instance.call("_show_settings", 2)
	await _wait_frames(3)
	var volume_slider := instance.find_child("SettingsMasterVolumeSlider", true, false) as HSlider
	var music_volume_slider := instance.find_child("SettingsMusicVolumeSlider", true, false) as HSlider
	var quality_option := instance.find_child("SettingsEffectsQualityOption", true, false) as OptionButton
	var reduced_toggle := instance.find_child("SettingsReducedMotionToggle", true, false) as CheckButton
	var global_auto_toggle := instance.find_child("SettingsGlobalAutoSkillToggle", true, false) as CheckButton
	var delete_save_button := instance.find_child("SettingsDeleteLocalSaveButton", true, false) as Button
	var persistence_status := instance.find_child("SettingsPersistenceStatus", true, false) as Label
	var export_save_button := instance.find_child("SettingsExportSaveButton", true, false) as Button
	var import_save_button := instance.find_child("SettingsImportSaveButton", true, false) as Button
	var settings_scroll := instance.find_child("SettingsScroll", true, false) as ScrollContainer
	var settings_data_scroll := instance.find_child("SettingsDataScroll", true, false) as ScrollContainer
	var settings_columns := instance.find_child("SettingsLandscapeColumns", true, false) as HBoxContainer
	var playtest_toggle := instance.find_child("SettingsLocalPlaytestToggle", true, false) as CheckButton
	var settings_help := instance.find_child("SettingsHelpButton", true, false) as Button
	_ok(volume_slider != null and volume_slider.custom_minimum_size.y >= 44.0, "SLG settings volume slider is touch sized")
	_ok(
		music_volume_slider != null and music_volume_slider.custom_minimum_size.y >= 44.0,
		"SLG settings exposes a touch-sized independent music mix"
	)
	_ok(quality_option != null and quality_option.item_count == 3, "SLG settings exposes three effects quality levels")
	_ok(reduced_toggle != null and reduced_toggle.custom_minimum_size.y >= 44.0, "SLG settings exposes reduced motion")
	_ok(global_auto_toggle != null and global_auto_toggle.custom_minimum_size.y >= 44.0, "SLG settings exposes global auto skill")
	_ok(delete_save_button != null and delete_save_button.text == "删除本地存档", "SLG settings exposes explicit local-save deletion")
	_ok(persistence_status != null and persistence_status.text.contains("备份"), "SLG settings explains browser persistence risk")
	_ok(
		String(instance.call("_error_copy", "SAVE_FAILED")).contains("操作未生效")
			and String(instance.call("_error_copy", "SAVE_FAILED")).contains("下载备份"),
		"storage write failure is translated into an actionable no-progress-loss recovery message"
	)
	_ok(export_save_button != null and export_save_button.custom_minimum_size.y >= 44.0, "SLG settings exposes a touch-sized save export")
	_ok(import_save_button != null and import_save_button.text == "选择备份并校验", "SLG settings validates an import before overwrite")
	_ok(settings_scroll != null and settings_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "SLG settings scrolls vertically instead of shrinking touch targets")
	_ok(settings_data_scroll != null and settings_data_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "SLG settings gives local data an independent landscape column")
	_ok(settings_columns != null and settings_columns.get_child_count() == 2, "SLG settings uses two balanced landscape columns")
	_ok(playtest_toggle != null and not playtest_toggle.button_pressed, "local playtest reporting is explicit opt-in")
	_ok(settings_help != null and settings_help.custom_minimum_size.y >= 48.0, "settings exposes the same gameplay and production information")
	var hidden_playtest_export := instance.find_child("SettingsExportPlaytestButton", true, false) as Button
	_ok(hidden_playtest_export != null and not hidden_playtest_export.is_visible_in_tree(), "playtest export stays hidden before opt-in")
	var settings_store: RefCounted = instance.get("settings_store")
	_ok(settings_store != null, "SLG shell owns the persistent SettingsStore")
	if settings_store != null:
		settings_store.set_master_volume(37)
		settings_store.set_music_volume(33)
		settings_store.set_effects_quality("high")
		settings_store.set_reduced_motion(true)
		settings_store.set_global_auto_skill(true)
		instance.call("_apply_settings_to_runtime")
	instance.call("_set_local_playtest_logging", true)
	await _wait_frames(4)
	var playtest_status := instance.find_child("SettingsPlaytestStatus", true, false) as Label
	var export_playtest := instance.find_child("SettingsExportPlaytestButton", true, false) as Button
	var clear_playtest := instance.find_child("SettingsClearPlaytestButton", true, false) as Button
	_ok(playtest_status != null and playtest_status.text.contains("不含设备或账号标识"), "opt-in playtest UI explains the bounded local data")
	_ok(export_playtest != null and export_playtest.custom_minimum_size.y >= 44.0, "opt-in playtest report exposes a touch-sized export")
	_ok(clear_playtest != null and clear_playtest.custom_minimum_size.y >= 44.0, "opt-in playtest report exposes local deletion")
	var journal: RefCounted = instance.get("playtest_journal")
	var journal_export: Dictionary = journal.export_report()
	_ok(bool(journal_export.get("ok", false)), "opt-in UI owns an exportable local playtest report")
	instance.call("_set_local_playtest_logging", false)
	await _wait_frames(4)
	_ok(not FileAccess.file_exists("user://local_playtest_session.json"), "opting out through UI deletes the local playtest report")
	var save_manager := root.get_node_or_null("/root/SaveManager")
	var backup: Dictionary = game_autoload.export_local_save(save_manager)
	_ok(bool(backup.get("ok", false)), "SLG settings smoke can produce a validated backup")
	if bool(backup.get("ok", false)):
		instance.call("_on_save_import_file_loaded", String(backup.get("text", "")))
		await _wait_frames(3)
		var preview := instance.find_child("SettingsImportPreview", true, false) as Label
		var confirm_import := instance.find_child("SettingsImportSaveButton", true, false) as Button
		_ok(preview != null and preview.text.contains("再次点击确认"), "validated import shows a progress preview before overwrite")
		_ok(confirm_import != null and confirm_import.text == "确认覆盖当前进度", "validated import requires a second explicit confirmation")
	instance.call("_return_from_settings")
	await _wait_frames(3)
	var base_camera_before_orbit := (instance.get_node_or_null("WorldHost/FactoryCamera") as Camera3D).position
	var command_marker_before_orbit := instance.find_child("FactoryMarker_command_center", true, false) as Button
	var command_marker_position_before_orbit := (
		command_marker_before_orbit.position
		if command_marker_before_orbit != null
		else Vector2.ZERO
	)
	instance.call("_begin_factory_pointer", Vector2(180, 180), 0)
	instance.call("_drag_factory_pointer", Vector2(240, 180), Vector2(60, 0))
	var base_camera_after_orbit := (instance.get_node_or_null("WorldHost/FactoryCamera") as Camera3D).position
	_ok(base_camera_after_orbit != base_camera_before_orbit, "factory camera orbits outside construction mode")
	_ok(absf(float(instance.get("factory_camera_yaw"))) > 0.1, "horizontal dragging changes the persistent factory orbit angle")
	var command_marker_after_orbit := instance.find_child("FactoryMarker_command_center", true, false) as Button
	var command_building_after_orbit := instance.get_node_or_null("WorldHost/FactoryBuilding_command_center") as Node3D
	if command_marker_after_orbit != null and command_building_after_orbit != null:
		var orbit_camera := instance.get_node_or_null("WorldHost/FactoryCamera") as Camera3D
		var expected_marker_center := orbit_camera.unproject_position(
			command_building_after_orbit.global_position + Vector3(0.0, 3.25, 0.0)
		)
		_ok(
			command_marker_after_orbit.position != command_marker_position_before_orbit,
			"factory building marker moves when the camera rotates"
		)
		_ok(
			command_marker_after_orbit.get_global_rect().has_point(expected_marker_center),
			"factory building marker remains projected over its building after camera rotation"
		)
	instance.call("_drag_factory_pointer", Vector2(240, 800), Vector2(0, 1000))
	_ok(is_equal_approx(float(instance.get("factory_camera_pitch")), deg_to_rad(68.0)), "vertical factory orbit clamps at the safe maximum pitch")
	instance.call("_reset_factory_pointer")
	var compact_layout_snapshot := MobileViewportAdapter.build_snapshot(
		{"width": 568.0, "height": 320.0},
		Vector2(844, 390)
	)
	instance.call("_on_mobile_layout_changed", compact_layout_snapshot)
	await _wait_frames(8)
	_ok(String(instance.call("_layout_profile")) == "compact_landscape", "live resize activates the compact landscape layout profile")
	for node_name in ["AppShellRoot", "AppShellHeader", "FactoryResourceHUD", "FactoryHudFrame", "PrimaryNavigation"]:
		var responsive_control := instance.find_child(node_name, true, false) as Control
		_ok(
			responsive_control != null and _control_inside_viewport(responsive_control, instance.get_viewport()),
			"compact landscape keeps %s inside the visible viewport" % node_name
		)
	var standard_layout_snapshot := MobileViewportAdapter.build_snapshot(
		{"width": 844.0, "height": 390.0},
		Vector2(844, 390)
	)
	instance.call("_on_mobile_layout_changed", standard_layout_snapshot)
	await _wait_frames(8)
	_ok(String(instance.call("_layout_profile")) == "standard_landscape", "restoring the design size restores the standard layout profile")
	var touch_a := InputEventScreenTouch.new()
	touch_a.index = 0
	touch_a.position = Vector2(140, 180)
	touch_a.pressed = true
	var touch_b := InputEventScreenTouch.new()
	touch_b.index = 1
	touch_b.position = Vector2(220, 180)
	touch_b.pressed = true
	instance.call("_handle_factory_pointer", touch_a)
	instance.call("_handle_factory_pointer", touch_b)
	var size_before_pinch := float(instance.get("factory_camera_size"))
	var pinch_drag := InputEventScreenDrag.new()
	pinch_drag.index = 1
	pinch_drag.position = Vector2(280, 180)
	pinch_drag.relative = Vector2(60, 0)
	instance.call("_handle_factory_pointer", pinch_drag)
	_ok(float(instance.get("factory_camera_size")) < size_before_pinch, "two-finger spread zooms the mobile factory camera in")
	_ok(bool(instance.get("factory_pinch_active")), "mobile factory input tracks an explicit two-finger pinch state")
	touch_a.pressed = false
	touch_b.pressed = false
	instance.call("_handle_factory_pointer", touch_a)
	instance.call("_handle_factory_pointer", touch_b)
	_ok(not bool(instance.get("factory_pinch_active")), "releasing both fingers ends pinch without triggering a tap")
	_ok(int(game_autoload.current_state().factory.facilities.get("porcelain_plant", -1)) == 0, "fresh campaign starts with an empty porcelain plot")
	game_autoload.current_state().economy.toilet_coins = 10000
	var mission_tab := instance.find_child("FactoryHudMissionTab", true, false) as Button
	var facility_tab := instance.find_child("FactoryHudFacilityTab", true, false) as Button
	var build_tab := instance.find_child("FactoryHudBuildTab", true, false) as Button
	_ok(mission_tab != null and facility_tab != null and build_tab != null, "factory HUD exposes action, facility, and construction buttons")
	_ok(mission_tab != null and mission_tab.button_group != null and mission_tab.button_group == facility_tab.button_group, "factory HUD buttons form one exclusive toggle group")
	_ok(instance.find_child("FactoryDetailScroll", true, false) == null, "factory HUD does not wrap its systems in a scroll view")
	if build_tab != null:
		build_tab.pressed.emit()
		await _wait_frames(3)
	var choose_porcelain := instance.find_child("ChooseFacility_porcelain_plant", true, false) as Button
	_ok(choose_porcelain != null and not choose_porcelain.disabled, "construction catalog exposes an affordable building type")
	_ok(instance.find_child("ConstructionButtonGrid", true, false) != null, "construction catalog uses a compact button grid")
	_ok(instance.find_child("OnboardingMissionPanel", true, false) == null, "construction button opens one focused panel instead of stacking every factory system")
	var construction_steps := instance.find_child("ConstructionStepGuide", true, false) as Label
	_ok(construction_steps != null and construction_steps.text.contains("选建筑") and construction_steps.text.contains("点地图格子") and construction_steps.text.contains("确认"), "construction panel explains the complete three-step placement flow")
	if choose_porcelain != null:
		choose_porcelain.pressed.emit()
		await _wait_frames(3)
	_ok(instance.get_node_or_null("WorldHost/FactoryGridCell_-1_0") != null, "choosing a building opens the interactive placement grid")
	var camera_before_drag := (instance.get_node_or_null("WorldHost/FactoryCamera") as Camera3D).position
	instance.call("_begin_factory_pointer", Vector2(180, 180), 0)
	instance.call("_drag_factory_pointer", Vector2(240, 180), Vector2(60, 0))
	var camera_after_drag := (instance.get_node_or_null("WorldHost/FactoryCamera") as Camera3D).position
	_ok(camera_after_drag != camera_before_drag, "dragging during placement keeps orbiting the factory camera")
	_ok(bool(instance.get("factory_pointer_dragged")), "camera drag crosses the threshold and suppresses grid selection")
	instance.call("_reset_factory_pointer")
	instance.set("construction_cell", Vector2i(-1, 0))
	instance.call("_show_base")
	await _wait_frames(3)
	_ok(music_director.current_state() == &"base", "factory route selects the low-priority industrial ambience")
	var confirm_porcelain := instance.find_child("ConfirmFacilityConstruction", true, false) as Button
	_ok(confirm_porcelain != null and not confirm_porcelain.disabled, "an empty grid cell enables explicit construction confirmation")
	var cancel_construction := instance.find_child("CancelFacilityConstruction", true, false) as Button
	_ok(
		confirm_porcelain != null and cancel_construction != null
			and confirm_porcelain.get_parent() == cancel_construction.get_parent(),
		"construction confirmation and cancellation share one compact action row"
	)
	_ok(
		confirm_porcelain != null
			and confirm_porcelain.get_global_rect().end.y <= instance.get_viewport().get_visible_rect().end.y + 0.5,
		"844x390 keeps the full construction confirmation inside the visible viewport"
	)
	if confirm_porcelain != null:
		confirm_porcelain.pressed.emit()
		await _wait_frames(5)
		var porcelain_ready_at := int(game_autoload.current_state().factory.facility_work.get("completes_at_unix", 0))
		instance.call("_command", "claim_facility_work", {"now_unix": porcelain_ready_at})
		instance.call("_show_base")
		await _wait_frames(4)
	_ok(int(game_autoload.current_state().factory.facilities.get("porcelain_plant", 0)) == 1, "construction command persists the new level-one facility")
	_ok(game_autoload.current_state().factory.facility_placements.get("porcelain_plant", []) == [-1, 0], "confirmed grid coordinates persist with the facility")
	_ok(instance.find_child("ClaimFactoryOutputButton", true, false) != null, "factory screen exposes its primary collect action")
	_ok(instance.find_child("ResourceMeter_工业材料", true, false) != null, "factory inventory uses one scannable industrial-material meter")
	game_autoload.current_state().factory.facility_work = {
		"work_type": "upgrade",
		"facility_id": "porcelain_plant",
		"started_at_unix": int(Time.get_unix_time_from_system()) - 2,
		"completes_at_unix": int(Time.get_unix_time_from_system()) - 1,
		"target_level": 2,
		"grid_x": 0,
		"grid_z": 0,
	}
	instance.set("selected_facility_id", "porcelain_plant")
	instance.set("factory_hud_panel", "facility")
	instance.call("_show_base")
	await _wait_frames(3)
	var ready_claim := instance.find_child("ClaimFacilityWork", true, false) as Button
	_ok(ready_claim != null and not ready_claim.disabled, "factory shows ready work before timed refresh")
	ready_claim.disabled = true
	instance.call("_refresh_factory_work_ui")
	await _wait_frames(3)
	ready_claim = instance.find_child("ClaimFacilityWork", true, false) as Button
	_ok(ready_claim != null and not ready_claim.disabled, "local factory timer refresh restores the ready claim without navigation")
	game_autoload.current_state().factory.facility_work = {}
	instance.call("_show_base")
	await _wait_frames(3)
	var factory_resource_hud := instance.find_child("FactoryResourceHUD", true, false) as Control
	_ok(factory_resource_hud != null and not (factory_resource_hud.get_parent() is ScrollContainer), "factory resources remain fixed outside scrolling detail")
	_ok(instance.find_child("FactoryDetailScroll", true, false) == null, "factory detail remains scroll-free after construction refreshes")
	_ok(instance.get_node_or_null("WorldHost/FactoryCamera") != null, "factory screen builds an interactive 3D camera")
	for facility_id in ["command_center", "porcelain_plant"]:
		var building := instance.get_node_or_null("WorldHost/FactoryBuilding_%s" % facility_id)
		_ok(building != null and String(building.get_meta("facility_id", "")) == facility_id, "factory builds clickable %s" % facility_id)
	var reduced_activity := instance.get_node_or_null("WorldHost/FactoryBuilding_porcelain_plant/Activity")
	_ok(reduced_activity != null and not bool(reduced_activity.get_meta("motion_enabled", true)), "reduced-motion setting disables looping factory activity tweens")
	_ok(instance.get_node_or_null("WorldHost/FactoryBuilding_porcelain_plant/OutputBubble") != null, "resource building exposes its stored-output marker in world space")
	var factory_camera := instance.get_node_or_null("WorldHost/FactoryCamera") as Camera3D
	var porcelain_building := instance.get_node_or_null("WorldHost/FactoryBuilding_porcelain_plant") as Node3D
	if factory_camera != null and porcelain_building != null:
		var projected := factory_camera.unproject_position(porcelain_building.global_position + Vector3(0.0, 1.0, 0.0))
		var picked := instance.call("_factory_building_at", projected) as CollisionObject3D
		_ok(picked == porcelain_building, "screen ray picking resolves the visible resource building")
	_ok(_tree_has_text(instance, "后勤库存"), "factory screen exposes industrial resources")
	_ok(_tree_has_text(instance, "后存满"), "factory screen exposes time until capacity is full")
	_ok(_tree_has_text(instance, "全员无损"), "factory screen exposes lossless deployment at a glance")
	instance.call("_activate_factory_building", "repair_center")
	await _wait_frames(3)
	_ok(instance.find_child("SelectedFacilityPanel", true, false) != null, "clicking a factory building opens the focused facility panel")
	if int(game_autoload.current_state().factory.facilities.get("repair_center", 0)) <= 0:
		instance.call("_begin_facility_construction", "repair_center")
		instance.set("construction_cell", Vector2i(1, 0))
		instance.call("_confirm_facility_construction")
		await _wait_frames(4)
		var repair_ready_at := int(game_autoload.current_state().factory.facility_work.get("completes_at_unix", 0))
		instance.call("_command", "claim_facility_work", {"now_unix": repair_ready_at})
		instance.call("_show_base")
		await _wait_frames(4)
		_ok(int(game_autoload.current_state().factory.facilities.get("repair_center", 0)) == 1, "grid confirmation constructs the repair center")
	_ok(_tree_has_text(instance, "训练增益"), "clicking the training center opens its permanent-growth panel")
	game_autoload.current_state().factory.eligible_facilities["research_lab"] = true
	instance.call("_activate_factory_building", "research_lab")
	await _wait_frames(3)
	if int(game_autoload.current_state().factory.facilities.get("research_lab", 0)) <= 0:
		instance.call("_begin_facility_construction", "research_lab")
		instance.set("construction_cell", Vector2i(2, 0))
		instance.call("_confirm_facility_construction")
		await _wait_frames(4)
		var research_ready_at := int(game_autoload.current_state().factory.facility_work.get("completes_at_unix", 0))
		instance.call("_command", "claim_facility_work", {"now_unix": research_ready_at})
		instance.call("_show_base")
		await _wait_frames(4)
	_ok(_tree_has_text(instance, "科技蓝图"), "research lab explains its toilet blueprint purpose")
	_ok(_tree_has_button(instance, "进入科技蓝图"), "research lab routes to the blueprint tree")
	instance.call("_show_blueprints")
	await _wait_frames(3)
	var blueprint_local_resources := instance.find_child("BlueprintResourceContext", true, false) as Control
	_ok(
		blueprint_local_resources != null and not blueprint_local_resources.is_visible_in_tree(),
		"blueprint page does not duplicate the globally visible core-resource balance"
	)
	_ok(instance.find_child("GlobalCoreResourceHUD", true, false) != null, "blueprint page retains the global top-right resource bar")
	_ok(instance.find_child("BlueprintTree", true, false) != null, "research lab opens a dedicated blueprint tree UI")
	_ok(instance.find_child("BlueprintTreeRoot", true, false) != null, "blueprint tree exposes a visible research trunk")
	var blueprint_branch_count := 0
	for node in instance.find_children("BlueprintBranchRow_*", "HBoxContainer", true, false):
		if node != null:
			blueprint_branch_count += 1
	_ok(blueprint_branch_count == 1, "blueprint tree shows only the selected branch instead of one long scroll")
	var blueprint_node_count := 0
	for node in instance.find_children("BlueprintNode_*", "Control", true, false):
		if node != null:
			blueprint_node_count += 1
	_ok(blueprint_node_count == 2, "selected blueprint branch keeps its two research nodes visible together")
	_ok(instance.find_child("BlueprintOrdinaryTab", true, false) != null, "blueprint branches use a fixed top toggle group")
	_ok(instance.find_child("BlueprintTreeScroll", true, false) == null, "blueprint tree no longer wraps the whole screen in a scroll view")
	instance.call("_show_base")
	await _wait_frames(3)
	var restored_mission_tab := instance.find_child("FactoryHudMissionTab", true, false) as Button
	if restored_mission_tab != null:
		restored_mission_tab.pressed.emit()
		await _wait_frames(3)
	_ok(_tree_has_text(instance, "前线来电"), "fresh save presents onboarding as an in-world transmission")
	_ok(_tree_has_text(instance, "在基地选址并建成研究所"), "fresh-save mission starts with research-lab construction")
	_ok(not _tree_has_text(instance, "收取一次工厂产出"), "fresh-save mission does not start with factory chores")
	_ok(not _tree_has_text(instance, "选择并升级一名主力"), "fresh-save mission does not require growth before combat")
	_ok(
		_tree_has_button(instance, "先建设研究所") or _tree_has_button(instance, "立即进攻 1-1"),
		"operation CTA routes to construction first, or to 1-1 when the lab is already built"
	)
	var intel_button := instance.find_child("OpenWarIntelligenceButton", true, false) as Button
	_ok(intel_button != null, "factory mission panel exposes the unified war intelligence")
	if intel_button != null:
		intel_button.pressed.emit()
		await _wait_frames(3)
		_ok(instance.find_child("WarIntelligenceScreen", true, false) != null, "war intelligence opens as a dedicated readable screen")
		_ok(_tree_has_text(instance, "当前编队战力"), "war intelligence uses the canonical formation power")
		_ok(not _tree_has_text(instance, "满编战力") and not _tree_has_text(instance, "出征战力"), "war intelligence does not expose obsolete readiness power variants")
		_ok(_tree_has_text(instance, "能力比"), "war intelligence explains stage-relative capability")
		_ok(_tree_has_text(instance, "战后无需维修"), "war intelligence exposes the lossless battle rule")
	instance.call("_show_map")
	await _wait_frames(3)
	_ok(instance.find_child("StageNodeStrip", true, false) != null, "war zone separates stage selection from stage detail")
	_ok(instance.find_child("SelectedStagePanel", true, false) != null, "war zone renders one readable selected-stage detail")
	_ok(_tree_has_text(instance, "1-1 无防备城市"), "war-zone screen exposes the opening town")
	_ok(_tree_has_button(instance, "1-5 灰镜核心巨炮"), "war-zone screen exposes the chapter boss")
	_ok(_tree_has_text(instance, "威胁等级"), "opening town expresses combat readiness as an in-world threat")
	_ok(_tree_has_text(instance, "我方"), "selected stage compares current squad power with the recommendation")
	_ok(_tree_has_text(instance, "能力比"), "selected stage explains risk with a player-readable capability ratio")
	game_autoload.current_state().stage_progress["cleared_stages"] = ["stage_1_1", "stage_1_2", "stage_1_3"]
	game_autoload.current_state().stage_progress["highest_unlocked_stage"] = "stage_1_4"
	instance.call("_select_stage_card", "stage_1_4")
	await _wait_frames(2)
	_ok(_tree_has_text(instance, "威胁等级 · 高"), "fourth town clearly marks the first growth wall")
	_ok(_tree_has_text(instance, "1-2、1-3") and _tree_has_text(instance, "图纸"), "first wall reconnaissance names the stage-earned blueprint recovery")
	_ok(_tree_has_text(instance, "两名永久援军"), "first wall reconnaissance connects researched permanent roles to the counterattack")
	_ok(_tree_has_text(instance, "图纸") and _tree_has_text(instance, "研究所"), "first wall reconnaissance explains the blueprint research path")
	_ok(_tree_has_text(instance, "下一步 · 先试探炮台防线"), "first wall reconnaissance prioritizes discovery over premature growth")
	var wall_attack: Button = null
	var visible_growth := false
	for candidate in instance.find_children("AttackButton", "Button", true, false):
		var button := candidate as Button
		if button.is_visible_in_tree():
			wall_attack = button
			break
	for candidate in instance.find_children("GrowthButton", "Button", true, false):
		visible_growth = visible_growth or (candidate as Button).is_visible_in_tree()
	_ok(wall_attack != null and wall_attack.text == "试探炮台防线" and wall_attack.is_visible_in_tree(), "first wall reconnaissance exposes the authored information battle")
	_ok(not visible_growth, "first wall reconnaissance does not send the player to an unavailable pre-discovery solution")
	game_autoload.current_state().attempt_counters["stage_1_4"] = 1
	game_autoload.current_state().factory.eligible_facilities["research_lab"] = true
	game_autoload.current_state().factory.facilities["research_lab"] = 0
	game_autoload.current_state().factory.facility_placements.erase("research_lab")
	instance.call("_select_stage_card", "stage_1_4")
	await _wait_frames(2)
	var known_wall_preparation: Button = null
	for candidate in instance.find_children("GrowthButton", "Button", true, false):
		if (candidate as Button).is_visible_in_tree():
			known_wall_preparation = candidate as Button
			break
	_ok(known_wall_preparation != null and known_wall_preparation.text == "建造研究所", "known first wall returns to the missing research-lab construction")
	if known_wall_preparation != null:
		known_wall_preparation.pressed.emit()
		await _wait_frames(3)
	_ok(
		instance.find_child("FactoryScreen", true, false) != null
			or instance.find_child("BaseScreen", true, false) != null,
		"map recovery action returns to the factory for laboratory construction"
	)
	instance.call("_show_map")
	await _wait_frames(2)
	instance.call("_select_stage_card", "stage_1_5")
	await _wait_frames(2)
	_ok(_tree_has_text(instance, "威胁等级 · 高"), "chapter boss renders a high-threat mastery target")
	_ok(_tree_has_text(instance, "冲锋马桶人升到二星"), "chapter boss exposes the verified assault reversal route")
	_ok(_tree_has_text(instance, "装甲马桶人升到二星"), "chapter boss exposes the verified armored reversal route")
	_ok(not _tree_has_text(instance, "战后无损"), "war-zone cards avoid exposing implementation-facing settlement rules")
	_ok(_tree_has_button(instance, "第2章"), "war-zone screen exposes chapter navigation")
	game_autoload.current_state().stage_progress["highest_unlocked_stage"] = "stage_2_1"
	instance.call("_select_chapter", 2)
	await _wait_frames(3)
	_ok(_tree_has_text(instance, "2-1 震荡封锁线"), "chapter navigation reaches the second chapter content")
	game_autoload.current_state().stage_progress["cleared_stages"] = ["stage_1_1", "stage_1_2"]
	game_autoload.current_state().meta_progression.commander_xp = 100
	instance.call("_show_goals")
	await _wait_frames(3)
	_ok(_tree_has_text(instance, "目标与里程碑"), "fourth top-level goals screen is reachable")
	_ok(instance.find_child("GoalHierarchyPanel", true, false) != null, "goals screen owns a visible macro-to-micro objective chain")
	_ok(_tree_has_text(instance, "大目标 ·"), "goals screen names the chapter-scale player goal")
	_ok(_tree_has_text(instance, "中目标 ·"), "goals screen names the current operation")
	_ok(_tree_has_text(instance, "小目标 ·"), "goals screen names the next executable action")
	_ok(instance.find_child("CurrentHurdlePanel", true, false) != null, "goals screen explains the current hurdle and recovery")
	_ok(instance.find_child("GoalHierarchyPrimaryCTA", true, false) != null, "goal hierarchy ends in one executable CTA")
	_ok(_tree_has_text(instance, "已占领 2/25 座城镇"), "goals screen exposes durable campaign progress")
	_ok(instance.find_child("MetaGoalsActionTab", true, false) != null, "goals screen exposes action tab")
	_ok(instance.find_child("MetaGoalsPassTab", true, false) != null, "goals screen exposes pass tab")
	_ok(instance.find_child("MetaGoalsAchievementsTab", true, false) != null, "goals screen exposes achievement tab")
	instance.call("_set_goals_tab", "achievements")
	await _wait_frames(3)
	_ok(_tree_has_text(instance, "第一座城"), "goals screen exposes meta-progression permanent achievements")
	_ok(_tree_has_button(instance, "领取"), "completed permanent achievement exposes a claim action")
	instance.call("_set_goals_tab", "pass")
	await _wait_frames(3)
	_ok(_tree_has_text(instance, "免费战役战令 · 尚未解锁"), "pass tab explains its dual unlock before chapter boss")
	game_autoload.current_state().stage_progress["cleared_stages"] = ["stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5"]
	game_autoload.current_state().meta_progression.commander_xp = 300
	game_autoload.current_state().meta_progression.season_merit = 350
	instance.call("_show_goals")
	await _wait_frames(3)
	var pass_cards: Array[Node] = []
	_collect_name_prefix(instance, "MetaPassLevel_", pass_cards)
	_ok(pass_cards.size() == 30, "pass tab renders all thirty reward levels")
	_ok(_tree_has_button(instance, "一键领取 3 项奖励"), "pass tab exposes batch claim for all reached levels")
	var goals_scroll := instance.find_child("GoalsContentScroll", true, false) as ScrollContainer
	if goals_scroll != null:
		goals_scroll.scroll_vertical = 160
		await _wait_frames(2)
		var goals_scroll_before := goals_scroll.scroll_vertical
		instance.call("_show_goals")
		await _wait_frames(4)
		var rebuilt_goals_scroll := instance.find_child("GoalsContentScroll", true, false) as ScrollContainer
		_ok(
			goals_scroll_before > 0
				and rebuilt_goals_scroll != null
				and rebuilt_goals_scroll.scroll_vertical == goals_scroll_before,
			"goals rebuild preserves the player's position in a long reward list"
		)
	var top_goal_nav := instance.find_child("TopNav行动Button", true, false) as Button
	var top_goal_badge := instance.find_child(
		"TopNav行动NotificationBadge", true, false
	) as Label
	var pass_badge := instance.find_child("PassNotificationBadge", true, false) as Label
	_ok(top_goal_nav != null and top_goal_nav.text == "行动", "top navigation keeps the destination label stable")
	_ok(
		top_goal_badge != null and top_goal_badge.visible and int(top_goal_badge.text) > 0,
		"top navigation renders pending rewards as a real notification badge"
	)
	_ok(
		pass_badge != null and pass_badge.visible and int(pass_badge.text) > 0,
		"goal tabs lead the player to the exact reward category"
	)
	var notification_now := int(Time.get_unix_time_from_system())
	game_autoload.current_state().factory.facility_work = {
		"work_type": "upgrade",
		"facility_id": "command_center",
		"started_at_unix": notification_now,
		"completes_at_unix": notification_now + 100,
		"target_level": 2,
	}
	instance.call("_show_map")
	await _wait_frames(3)
	var top_factory_badge := instance.find_child(
		"TopNav工厂NotificationBadge", true, false
	) as Label
	_ok(
		top_factory_badge != null and not top_factory_badge.visible,
		"unfinished factory work stays dark outside the factory"
	)
	game_autoload.current_state().factory.facility_work["completes_at_unix"] = notification_now - 1
	instance.call("_refresh_factory_work_ui")
	await _wait_frames(2)
	_ok(
		top_factory_badge != null and top_factory_badge.visible and top_factory_badge.text == "1",
		"completed factory work lights the destination without leaving the current screen"
	)
	var top_factory_nav := instance.find_child("TopNav工厂Button", true, false) as Button
	if top_factory_nav != null:
		top_factory_nav.pressed.emit()
		await _wait_frames(3)
	var ready_facility_tab := instance.find_child(
		"FactoryHudFacilityTab", true, false
	) as Button
	_ok(
		ready_facility_tab != null and ready_facility_tab.button_pressed,
		"clicking the lit factory destination opens the exact claim panel"
	)
	game_autoload.current_state().factory.facility_work = {}
	instance.call("_set_goals_tab", "action")
	instance.call("_show_map")
	await _wait_frames(3)
	_ok(
		_tree_has_button(instance, "立即出击") or _tree_has_button(instance, "仍要试探"),
		"war zone preserves a direct attack option at every risk level"
	)
	game_autoload.current_state().economy.recruit_tickets = 10
	instance.call("_show_legion")
	await _wait_frames(3)
	_ok(instance.find_child("LegionFormationTab", true, false) != null, "legion uses fixed task tabs above its detail region")
	instance.call("_set_legion_tab", "roster")
	await _wait_frames(3)
	_ok(instance.find_child("RosterResourceContext", true, false) == null, "roster no longer spends scroll space on the global resource balance")
	_ok(instance.find_child("GlobalCoreResourceHUD", true, false) != null, "roster retains the top-right core-resource bar")
	_ok(_tree_has_button(instance, "升星"), "legion screen exposes star progression")
	_ok(_tree_has_button(instance, "研究技能 Lv.2"), "legion screen exposes active-skill research")
	_ok(_tree_has_text(instance, "无损可出征"), "legion screen exposes lossless permanent heroes")
	instance.call("_set_legion_tab", "recruit")
	await _wait_frames(3)
	instance.call("_signal_recruit", 1)
	await _wait_frames(3)
	_ok(instance.find_child("SignalRecruitResultPanel", true, false) != null, "legion screen keeps the latest recruit result visible")
	instance.call("_set_legion_tab", "formation")
	await _wait_frames(3)
	instance.call("_select_formation_slot", "troop_5")
	await _wait_frames(3)
	_ok(instance.find_child("FormationSlotGrid", true, false) != null, "legion screen exposes six selectable formation slots")
	_ok(instance.find_child("FormationCandidatePanel", true, false) != null, "selected formation slot exposes immediate hero candidates without scrolling to long cards")
	var formation_candidates: Array[Node] = []
	_collect_name_prefix(instance, "FormationCandidate_", formation_candidates)
	_ok(not formation_candidates.is_empty(), "selecting a slot exposes direct deploy candidates in the formation tab")
	var result_hero_id := String(game_autoload.current_state().formation.hero_ids()[0])
	instance.set("last_battle_runtime_result", {
		"ticks": 125,
		"structures_destroyed": 4,
		"enemies_defeated": 8,
		"stage_reached": 2,
		"cannon_hit_count": 1,
		"cannon_suppressed_count": 0,
		"cannon_guarded_count": 2,
		"cannon_guard_counter_damage": 120,
		"ally_damage_dealt_by_unit": {result_hero_id: 1200},
	})
	instance.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_1_5",
			"reward": {"gold": 58, "porcelain": 27, "parts": 23, "sludge": 21},
			"industrial_tech": 4,
			"hero_shards": 8,
			"skill_chips": 2,
			"damage_manifest": {},
			"next_stage_id": "stage_2_1",
		},
	})
	instance.call("_show_result")
	await _wait_frames(3)
	_ok(_tree_has_text(instance, "首章胜利 · 你的成长选择通过实战验证"), "chapter result uses text and shape in addition to color for outcome")
	_ok(_tree_has_text(instance, "战斗复盘") and _tree_has_text(instance, "装甲护盾格挡巨炮 2 次并反震 120 伤害"), "result celebrates successful defensive timing instead of misreporting it as a cannon failure")
	_ok(
		String(instance.call("_battle_debrief_copy", {"cannon_hit_count": 1}, "defeat")).contains("下次切换手动技能"),
		"unguarded cannon hits still explain the recovery action"
	)
	_ok(_tree_has_text(instance, "核心贡献"), "result celebrates a contribution measured by the battle session")
	_ok(_tree_has_text(instance, "下一步成长"), "result maps rewards to the next growth action")
	_ok(_tree_has_text(instance, "军团数据 +"), "boss result exposes the unified legion-data reward")
	_ok(_tree_has_text(instance, "路线验证"), "boss result closes the chosen growth mastery loop")
	_ok(_tree_has_text(instance, "首章解锁 · 第2章战线"), "boss result exposes the actual next campaign unlock")
	_ok(_tree_has_button(instance, "领取阵营起手十连"), "boss result exposes the faction-starter CTA")
	instance.call("_show_settlement_error", "存储空间不足")
	await _wait_frames(2)
	_ok(instance.find_child("BattleSettlementErrorPanel", true, false) != null, "failed durable settlement opens a blocking recovery screen")
	_ok(instance.find_child("RetryBattleSettlementButton", true, false) != null, "failed durable settlement keeps an explicit idempotent retry action")
	game_autoload.current_state().stage_progress["highest_unlocked_stage"] = "endless_1"
	game_autoload.current_state().stage_progress["cleared_stages"] = StageCatalog.ACT1_STAGE_IDS.duplicate()
	instance.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_5_5",
			"ticks": 385,
			"campaign_completed": true,
			"first_campaign_completion": true,
		},
	})
	instance.call("_show_result")
	await _wait_frames(3)
	_ok(instance.find_child("CampaignEpilogueScreen", true, false) != null, "final victory opens the dedicated campaign epilogue")
	_ok(_tree_has_text(instance, "第一幕完成"), "campaign epilogue clearly states main-campaign completion")
	_ok(_tree_has_text(instance, "城镇占领  25/25"), "campaign epilogue summarizes all authored towns")
	var endless_button := instance.find_child("CampaignEnterEndlessButton", true, false) as Button
	_ok(endless_button != null and not endless_button.disabled, "campaign epilogue exposes endless continuation")
	if endless_button != null:
		endless_button.pressed.emit()
		await _wait_frames(3)
		_ok(_tree_has_text(instance, "无尽前线 1"), "epilogue continuation reaches the first endless stage")
	instance.call("_start_battle")
	await _wait_frames(6)
	_ok(music_director.current_state() == &"battle", "ordinary frontline route selects the battle music state")
	var pause_button := instance.find_child("BattlePauseButton", true, false) as Button
	var skill_mode_button := instance.find_child("BattleSkillModeButton", true, false) as Button
	var tactical_status := instance.find_child("BattleTacticalStatus", true, false) as Label
	_ok(pause_button != null and pause_button.custom_minimum_size.y >= 44.0, "battle exposes a touch-sized pause control")
	_ok(skill_mode_button != null and skill_mode_button.custom_minimum_size.y >= 44.0, "battle exposes an explicit automatic/manual skill decision")
	_ok(tactical_status != null and tactical_status.text.contains("阶段"), "battle HUD exposes stage and frontline context")
	_ok(instance.find_child("BattleHudTimer", true, false) == null, "battle HUD reuses deterministic snapshot events instead of polling duplicate snapshots")
	var battle_world: Node = instance.get("battle_world")
	_ok(battle_world != null, "SLG battle starts with presentation settings applied")
	_ok(
		battle_world != null and battle_world.get_parent() == instance.get_node_or_null("WorldHost"),
		"battle camera renders directly into the main viewport"
	)
	_ok(instance.find_child("BattleRenderViewport", true, false) == null, "battle avoids stretched SubViewport texture rendering")
	_ok(instance.find_child("BattleWorldViewportArea", true, false) != null, "battle HUD reserves a transparent view area over the direct camera")
	instance.call("_toggle_battle_skill_mode")
	await _wait_frames(2)
	var manual_skill_buttons: Array[Node] = []
	_collect_name_prefix(instance, "BattleSkillButton_", manual_skill_buttons)
	_ok(manual_skill_buttons.size() >= 1, "manual battle mode exposes one skill control per deployed permanent hero")
	var snapshots: Array = instance.call("_battle_snapshots")
	var all_auto := not snapshots.is_empty()
	for snapshot_value in snapshots:
		all_auto = all_auto and bool((snapshot_value as Dictionary).get("auto_skill", false))
	_ok(all_auto, "global auto skill is applied to every battle snapshot")
	var web_runtime: Node = instance.get("web_runtime")
	if web_runtime != null:
		web_runtime.set_focus_state(false)
		await _wait_frames(2)
		_ok(bool(instance.get("battle_is_paused")), "runtime focus loss pauses the SLG battle")
		var pause_overlay := instance.find_child("BattlePauseOverlay", true, false) as Control
		var pause_resume := instance.find_child("BattlePauseResumeButton", true, false) as Button
		var pause_retreat := instance.find_child("BattlePauseRetreatButton", true, false) as Button
		var pause_volume := instance.find_child("BattlePauseVolumeSlider", true, false) as HSlider
		var pause_reduced := instance.find_child("BattlePauseReducedMotionToggle", true, false) as CheckButton
		_ok(pause_overlay != null and pause_overlay.visible, "pausing opens a blocking full-screen battle menu")
		_ok(pause_overlay != null and pause_overlay.process_mode == Node.PROCESS_MODE_ALWAYS, "battle pause menu remains interactive while combat is frozen")
		_ok(pause_resume != null and pause_resume.custom_minimum_size.y >= 48.0, "pause menu exposes a touch-sized resume action")
		_ok(pause_retreat != null and pause_retreat.custom_minimum_size.y >= 48.0, "pause menu keeps the durable retreat path available")
		_ok(pause_volume != null and pause_reduced != null, "pause menu exposes safe audio and reduced-motion settings without destroying the battle")
		var cancel_event := InputEventAction.new()
		cancel_event.action = "ui_cancel"
		cancel_event.pressed = true
		_ok(bool(instance.call("_is_battle_pause_event", cancel_event)), "semantic pause input recognizes Escape and Android back")
		web_runtime.set_focus_state(true)
		await _wait_frames(2)
		_ok(bool(instance.get("battle_is_paused")), "runtime focus return does not resume without player intent")
		if pause_resume != null:
			pause_resume.pressed.emit()
			await _wait_frames(2)
			_ok(not bool(instance.get("battle_is_paused")), "pause overlay explicitly resumes the same battle")
	if pause_button != null and not bool(instance.get("battle_is_paused")):
		pause_button.pressed.emit()
		await _wait_frames(2)
		_ok(bool(instance.get("battle_is_paused")), "top battle pause control opens the full pause menu")
		instance.call("_set_battle_paused", false)


func _wait_frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _tree_has_text(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment):
		return true
	for child in node.get_children():
		if _tree_has_text(child, fragment):
			return true
	return false


func _tree_has_button(node: Node, fragment: String) -> bool:
	if node is Button and (node as Button).text.contains(fragment):
		return true
	for child in node.get_children():
		if _tree_has_button(child, fragment):
			return true
	return false


func _control_inside_viewport(control: Control, viewport: Viewport) -> bool:
	var bounds := Rect2(Vector2.ZERO, viewport.get_visible_rect().size)
	var rect := control.get_global_rect()
	return (
		rect.position.x >= bounds.position.x - 1.0
		and rect.position.y >= bounds.position.y - 1.0
		and rect.end.x <= bounds.end.x + 1.0
		and rect.end.y <= bounds.end.y + 1.0
	)


func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	call_deferred("_finish_after_cleanup")


func _finish_after_cleanup() -> void:
	for node in root.find_children("*", "AudioStreamPlayer", true, false):
		var player := node as AudioStreamPlayer
		if player != null:
			player.stop()
			player.stream = null
	if is_instance_valid(_test_instance):
		_test_instance.queue_free()
		for _frame in 6:
			await process_frame
	_test_instance = null
	_cleanup_settings(TEST_SAVE_PATH)
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
