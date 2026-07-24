extends Node

const FactoryCatalog := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const FactoryService := preload("res://game/scripts/domain/factory/factory_service.gd")
const HeroProgression := preload("res://game/scripts/domain/progression/hero_progression.gd")
const BattleWorldScript := preload("res://game/scripts/presentation_3d/battle_world.gd")
const CJKFont := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

enum AppState { BOOT, TITLE, CAMP, FACTORY, CULTIVATION, FORMATION, EXPEDITION, BATTLE, RESULT }

const COLOR_BG := Color("#0b1322")
const COLOR_PANEL := Color("#16243a")
const COLOR_PANEL_ALT := Color("#20334d")
const COLOR_PRIMARY := Color("#29b6a6")
const COLOR_ACCENT := Color("#ffb74d")
const COLOR_TEXT := Color("#f3f7ff")
const COLOR_MUTED := Color("#a9b8cc")
const COLOR_DANGER := Color("#ff7b72")
const UI_SCALE: float = 1.65
const SLOT_KEYS: Array[String] = ["front_left", "front_center", "front_right", "back_left", "back_center", "back_right"]
const SLOT_NAMES: Array[String] = ["前左", "前中", "前右", "后左", "后中", "后右"]
const MATERIAL_LABELS := {"porcelain": "瓷片", "parts": "零件", "sludge": "污泥"}

@onready var world_host: Node3D = $WorldHost
@onready var ui_root: Control = $Interface/UIRoot

var app_state: AppState = AppState.BOOT
var game: Node
var battle_world: Node3D
var battle_id: String = ""
var battle_elapsed: float = 0.0
var battle_snapshot_elapsed: float = 0.0
var factory_refresh_elapsed: float = 0.0
var factory_order_views: Array[Dictionary] = []
var battle_timer_label: Label
var battle_stage_label: Label
var battle_warning_label: Label
var battle_progress_label: Label
var battle_skill_rows: VBoxContainer
var battle_pause_button: Button
var status_label: Label
var command_serial: int = 0
var selected_formation_slot: int = 0
var selected_merge_ids: Array[String] = []
var selected_training_id: String = ""
var battle_is_paused: bool = false


func _ready() -> void:
	game = get_node_or_null("/root/Game")
	ui_root.theme = _build_theme()
	if game == null:
		_show_boot_error("Game 服务未加载，无法进入游戏。")
		return
	if not game.bootstrap_completed.is_connected(_on_bootstrap_completed):
		game.bootstrap_completed.connect(_on_bootstrap_completed)
	_show_boot()
	_on_bootstrap_completed(String(game.bootstrap_status))


func _process(delta: float) -> void:
	if app_state == AppState.FACTORY:
		factory_refresh_elapsed += delta
		if factory_refresh_elapsed >= 0.5:
			factory_refresh_elapsed = 0.0
			_update_factory_order_views()
		return
	if app_state != AppState.BATTLE or battle_world == null:
		return
	if not battle_is_paused:
		battle_elapsed += delta
	battle_snapshot_elapsed += delta
	if battle_snapshot_elapsed >= 0.2:
		battle_snapshot_elapsed = 0.0
		_update_battle_hud()


func _show_boot() -> void:
	app_state = AppState.BOOT
	_clear_ui()
	_clear_world()
	_add_background(COLOR_BG)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(center)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)
	var title := _label("马桶人工厂攻城", 32, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	status_label = _label("正在装配马桶军团...", 18, COLOR_MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status_label)


func _on_bootstrap_completed(status: String) -> void:
	if status in ["loaded", "created"]:
		_show_title()
	elif status != "not_started":
		_show_boot_error("存档初始化失败：%s" % status)


func _show_boot_error(message: String) -> void:
	if status_label == null:
		_show_boot()
	status_label.text = message
	status_label.add_theme_color_override("font_color", COLOR_DANGER)


func _show_title() -> void:
	app_state = AppState.TITLE
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_add_background(Color(0.02, 0.04, 0.08, 0.56))
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(center)
	var panel := _panel(COLOR_PANEL, 18)
	panel.custom_minimum_size = Vector2(420, 210)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := _label("马桶人工厂攻城", 34, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := _label("造兵、升星、六人编队，突破三阶段城市防线。", 16, COLOR_MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	var button := _button("进入营地", COLOR_PRIMARY, Vector2(210, 54), 19)
	button.pressed.connect(_show_camp)
	column.add_child(button)
	button.grab_focus()


func _show_camp() -> void:
	app_state = AppState.CAMP
	_clear_ui()
	_clear_world()
	_build_camp_world()
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(root)
	root.add_child(_build_top_bar())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var objective := _panel(Color(0.055, 0.09, 0.14, 0.92), 14)
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(objective)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 8)
	objective.add_child(copy)
	copy.add_child(_label("下一目标", 14, COLOR_PRIMARY))
	copy.add_child(_label("城市外围防线", 26, COLOR_TEXT))
	copy.add_child(_label("三阶段推进：外围路障 -> 火力封锁区 -> 基地广场。", 15, COLOR_MUTED))
	copy.add_child(_label("胜利奖励：金币、训练书、瓷片、零件、污泥。", 15, COLOR_ACCENT))
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	body.add_child(actions)
	var factory := _button("工厂", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	factory.pressed.connect(_show_factory)
	actions.add_child(factory)
	var cultivate := _button("培育", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	cultivate.pressed.connect(_show_cultivation)
	actions.add_child(cultivate)
	var formation := _button("编队", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	formation.pressed.connect(_show_formation)
	actions.add_child(formation)
	var expedition := _button("出征", COLOR_ACCENT, Vector2(138, 58), 19)
	expedition.pressed.connect(_show_expedition)
	actions.add_child(expedition)


func _build_top_bar() -> Control:
	var panel := _panel(Color(0.055, 0.09, 0.14, 0.94), 10)
	panel.custom_minimum_size.y = 54
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var brand := _label("马桶军团营地", 21, COLOR_TEXT)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(brand)
	var state: RefCounted = game.current_state()
	var materials: Dictionary = state.factory.materials
	var resources := _label(
		"金 %d · 书 %d · 瓷 %d · 零 %d · 泥 %d" % [
			state.economy.gold,
			state.economy.xp_books,
			int(materials.get("porcelain", 0)),
			int(materials.get("parts", 0)),
			int(materials.get("sludge", 0)),
		],
		13,
		COLOR_ACCENT
	)
	resources.autowrap_mode = TextServer.AUTOWRAP_OFF
	resources.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(resources)
	return panel


func _show_factory() -> void:
	app_state = AppState.FACTORY
	factory_refresh_elapsed = 0.0
	factory_order_views.clear()
	_clear_ui()
	_clear_world()
	_build_factory_world()
	_show_management_shell("工厂", _build_factory_body())


func _build_factory_body() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	var state: RefCounted = game.current_state()
	var now := int(Time.get_unix_time_from_system())
	var summary: Dictionary = FactoryService.offline_summary(state, now)
	if int(summary.get("ready_count", 0)) > 0:
		var ready_panel := _panel(Color(0.10, 0.16, 0.12, 0.96), 8)
		column.add_child(ready_panel)
		var ready_row := HBoxContainer.new()
		ready_row.add_theme_constant_override("separation", 8)
		ready_panel.add_child(ready_row)
		var ready_copy := _label("离线生产完成 %d 单，打开仓门即可领取。" % int(summary["ready_count"]), 15, COLOR_PRIMARY)
		ready_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ready_row.add_child(ready_copy)
		var claim_all := _button("领取完成", COLOR_PRIMARY, Vector2(120, 34), 13)
		claim_all.pressed.connect(_claim_ready_productions)
		ready_row.add_child(claim_all)
	var queue_title := _label("生产队列  %d/3" % state.factory.production_queue.size(), 17, COLOR_PRIMARY)
	column.add_child(queue_title)
	var queue_grid := GridContainer.new()
	queue_grid.columns = 3
	queue_grid.add_theme_constant_override("h_separation", 8)
	column.add_child(queue_grid)
	for index in 3:
		var order: Dictionary = state.factory.production_queue[index] if index < state.factory.production_queue.size() else {}
		queue_grid.add_child(_factory_order_card(order, now))
	column.add_child(_label("四类车间", 17, COLOR_PRIMARY))
	var workshop_labels := {
		"ordinary": "普通车间：低成本补员与前线压制",
		"flying": "飞行车间：远程轰炸与爆发突破",
		"heavy": "重装车间：抗线、破门、切精英",
		"special": "特殊车间：维修、寄生与战术反制",
	}
	for workshop_id in ["ordinary", "flying", "heavy", "special"]:
		var workshop := _panel(COLOR_PANEL, 8)
		column.add_child(workshop)
		var workshop_box := VBoxContainer.new()
		workshop_box.add_theme_constant_override("separation", 6)
		workshop.add_child(workshop_box)
		workshop_box.add_child(_label(String(workshop_labels[workshop_id]), 15, COLOR_ACCENT))
		var recipes := GridContainer.new()
		recipes.columns = 2
		recipes.add_theme_constant_override("h_separation", 8)
		recipes.add_theme_constant_override("v_separation", 8)
		workshop_box.add_child(recipes)
		for recipe in FactoryCatalog.recipes():
			if String(recipe["workshop"]) == workshop_id:
				recipes.add_child(_recipe_card(recipe, bool(state.factory.blueprints.get(String(recipe["recipe_id"]), false))))
	return scroll


func _factory_order_card(order: Dictionary, now: int) -> Control:
	var card := _panel(COLOR_PANEL, 8)
	card.custom_minimum_size = Vector2(180, 92)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	if order.is_empty():
		column.add_child(_label("空队列", 15, COLOR_MUTED))
		column.add_child(_label("选择下方配方开始生产", 13, COLOR_MUTED))
		return card
	var recipe := FactoryCatalog.recipe(String(order["recipe_id"]))
	column.add_child(_label(String(recipe.get("display_name", order["recipe_id"])), 15, COLOR_TEXT))
	var remain := maxi(0, int(order["completes_at_unix"]) - now)
	var timer_label := _label("剩余 %02d:%02d" % [remain / 60, remain % 60], 13, COLOR_ACCENT if remain > 0 else COLOR_PRIMARY)
	column.add_child(timer_label)
	var claim := _button("领取", COLOR_PRIMARY if remain == 0 else COLOR_PANEL_ALT, Vector2(120, 34), 14)
	claim.disabled = remain > 0
	var order_id := String(order["order_id"])
	claim.pressed.connect(func() -> void: _claim_production(order_id))
	column.add_child(claim)
	factory_order_views.append({
		"completes_at_unix": int(order["completes_at_unix"]),
		"timer_label": timer_label,
		"claim_button": claim,
	})
	return card


func _update_factory_order_views() -> void:
	var now := int(Time.get_unix_time_from_system())
	for view in factory_order_views:
		var timer_label := view.get("timer_label") as Label
		var claim_button := view.get("claim_button") as Button
		if not is_instance_valid(timer_label) or not is_instance_valid(claim_button):
			continue
		var remain := maxi(0, int(view["completes_at_unix"]) - now)
		timer_label.text = "剩余 %02d:%02d" % [remain / 60, remain % 60]
		timer_label.add_theme_color_override("font_color", COLOR_ACCENT if remain > 0 else COLOR_PRIMARY)
		claim_button.disabled = remain > 0


func _recipe_card(recipe: Dictionary, unlocked: bool = true) -> Control:
	var card := _panel(COLOR_PANEL, 8)
	card.custom_minimum_size = Vector2(270, 112)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label(String(recipe["display_name"]), 16, COLOR_TEXT))
	copy.add_child(_label("%s · %s · %ds" % [recipe["workshop"], recipe["rarity"], int(recipe["duration_seconds"])], 12, COLOR_MUTED))
	var cost: Dictionary = recipe["cost"]
	copy.add_child(_label("瓷%d 零%d 泥%d" % [int(cost["porcelain"]), int(cost["parts"]), int(cost["sludge"])], 13, COLOR_ACCENT))
	var archetype: Dictionary = FactoryCatalog.archetype(String(recipe["archetype_id"]))
	copy.add_child(_label("%s · %s" % [_role_name(String(archetype.get("role", ""))), String(archetype.get("description", ""))], 11, COLOR_MUTED))
	var start := _button("开始", COLOR_PRIMARY, Vector2(74, 74), 14)
	var recipe_id := String(recipe["recipe_id"])
	if not unlocked:
		start.text = "锁定"
		start.disabled = true
		copy.add_child(_label(_blueprint_hint(recipe_id), 11, COLOR_DANGER))
	start.pressed.connect(func() -> void: _start_production(recipe_id))
	row.add_child(start)
	return card


func _start_production(recipe_id: String) -> void:
	var now := int(Time.get_unix_time_from_system())
	var result := _execute_command("start_production", {"recipe_id": recipe_id, "now_unix": now}, "")
	if bool(result.get("ok", false)):
		_play_factory_start_feedback(recipe_id)
		await get_tree().create_timer(0.35).timeout
		if app_state == AppState.FACTORY:
			_show_factory()
	else:
		_show_notice("生产失败：%s" % result.get("error", "UNKNOWN"))


func _claim_production(order_id: String) -> void:
	var now := int(Time.get_unix_time_from_system())
	var result := _execute_command("claim_production", {"order_id": order_id, "now_unix": now}, "")
	if bool(result.get("ok", false)):
		var event: Dictionary = result.get("event", {}) as Dictionary
		_play_factory_claim_feedback(String(event.get("hero_id", "")), String(event.get("recipe_id", "")))
		await get_tree().create_timer(0.75).timeout
		if app_state == AppState.FACTORY:
			_show_factory()
	else:
		_show_notice("领取失败：%s" % result.get("error", "UNKNOWN"))


func _claim_ready_productions() -> void:
	var now := int(Time.get_unix_time_from_system())
	var result := _execute_command("claim_ready_productions", {"now_unix": now}, "")
	if bool(result.get("ok", false)):
		var event: Dictionary = result.get("event", {}) as Dictionary
		var claimed: Array = event.get("claimed", [])
		_show_notice("离线完成订单已领取：%d 名马桶人入列。" % claimed.size())
		if not claimed.is_empty():
			var first := claimed[0] as Dictionary
			_play_factory_claim_feedback(String(first.get("hero_id", "")), String(first.get("recipe_id", "")))
			await get_tree().create_timer(0.75).timeout
		if app_state == AppState.FACTORY:
			_show_factory()
	else:
		_show_notice("暂无可领取订单：%s" % result.get("error", "UNKNOWN"))


func _show_cultivation() -> void:
	app_state = AppState.CULTIVATION
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_show_management_shell("培育", _build_cultivation_body())


func _build_cultivation_body() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	column.add_child(_label("同 archetype + star 的 3 个英雄可三合一升星。", 15, COLOR_MUTED))
	column.add_child(_build_training_panel())
	var groups: Dictionary = {}
	for hero in game.current_state().roster:
		var key := "%s|%d" % [hero.archetype_id, hero.star]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(hero)
	for key in groups.keys():
		var heroes := groups[key] as Array
		if heroes.size() < 2:
			continue
		var card := _panel(COLOR_PANEL, 8)
		column.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)
		var exemplar: RefCounted = heroes[0]
		box.add_child(_label("%s  ★%d  (%d/3)" % [_archetype_name(exemplar.archetype_id), exemplar.star, heroes.size()], 17, COLOR_TEXT))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		box.add_child(row)
		for hero in heroes:
			var toggle := _button(("✓ " if selected_merge_ids.has(hero.hero_id) else "") + hero.display_name, COLOR_PANEL_ALT, Vector2(150, 42), 13)
			var hero_id := String(hero.hero_id)
			toggle.pressed.connect(func() -> void: _toggle_merge_selection(hero_id))
			row.add_child(toggle)
	var merge := _button("三合一升星", COLOR_PRIMARY, Vector2(180, 48), 16)
	merge.disabled = selected_merge_ids.size() != 3
	merge.pressed.connect(_merge_selected_heroes)
	column.add_child(merge)
	return scroll


func _build_training_panel() -> Control:
	var state: RefCounted = game.current_state()
	if selected_training_id.is_empty() and not state.roster.is_empty():
		selected_training_id = String(state.roster[0].hero_id)
	var panel := _panel(Color(0.07, 0.11, 0.17, 0.96), 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	row.add_child(list)
	list.add_child(_label("训练", 17, COLOR_PRIMARY))
	for index in state.roster.size():
		var hero: RefCounted = state.roster[index]
		var pick := _button(("✓ " if hero.hero_id == selected_training_id else "") + "%s L%d ★%d" % [hero.display_name, hero.level, hero.star], COLOR_PANEL_ALT, Vector2(190, 34), 11)
		var hero_id := String(hero.hero_id)
		pick.pressed.connect(func() -> void:
			selected_training_id = hero_id
			_show_cultivation()
		)
		list.add_child(pick)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 5)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail)
	var selected: RefCounted = state.hero_by_id(selected_training_id)
	if selected == null:
		detail.add_child(_label("没有可训练英雄。", 14, COLOR_MUTED))
		return panel
	var stats_before: Dictionary = HeroProgression.derived_battle_stats(selected)
	var preview: RefCounted = selected.deep_clone()
	HeroProgression.train_with_books(preview, 1)
	var stats_after: Dictionary = HeroProgression.derived_battle_stats(preview)
	var archetype: Dictionary = FactoryCatalog.archetype(String(selected.archetype_id))
	detail.add_child(_label("%s  L%d  XP %d/320  ★%d" % [selected.display_name, selected.level, selected.xp, selected.star], 15, COLOR_TEXT))
	detail.add_child(_label("%s · %s · 技能层级 T%d" % [
		_role_name(String(archetype.get("role", ""))),
		String(archetype.get("active_skill", "")),
		HeroProgression.skill_tier(selected),
	], 12, COLOR_PRIMARY))
	detail.add_child(_label("消耗：金币%d + 训练书1；当前 金%d/书%d" % [HeroProgression.GOLD_PER_BOOK, state.economy.gold, state.economy.xp_books], 13, COLOR_ACCENT))
	detail.add_child(_label("预览：HP %d→%d  攻击 %d→%d  防御 %d→%d" % [
		int(stats_before["max_hp"]),
		int(stats_after["max_hp"]),
		maxi(int(stats_before["physical_atk"]), int(stats_before["magic_atk"])),
		maxi(int(stats_after["physical_atk"]), int(stats_after["magic_atk"])),
		int(stats_before["defense"]),
		int(stats_after["defense"]),
	], 13, COLOR_MUTED))
	var train := _button("训练1本", COLOR_PRIMARY, Vector2(140, 40), 13)
	train.disabled = state.economy.xp_books < 1 or state.economy.gold < HeroProgression.GOLD_PER_BOOK or selected.level >= 5
	train.pressed.connect(func() -> void: _train_selected_hero(1))
	detail.add_child(train)
	return panel


func _train_selected_hero(book_count: int) -> void:
	if selected_training_id.is_empty():
		return
	var result := _execute_command("train_hero", {"hero_id": selected_training_id, "book_count": book_count}, "")
	if bool(result.get("ok", false)):
		_show_cultivation()
	else:
		_show_notice("训练失败：%s" % result.get("error", "UNKNOWN"))


func _toggle_merge_selection(hero_id: String) -> void:
	if selected_merge_ids.has(hero_id):
		selected_merge_ids.erase(hero_id)
	elif selected_merge_ids.size() < 3:
		if selected_merge_ids.is_empty():
			selected_merge_ids.append(hero_id)
		elif _merge_group_key(hero_id) == _merge_group_key(selected_merge_ids[0]):
			selected_merge_ids.append(hero_id)
		else:
			selected_merge_ids.clear()
			selected_merge_ids.append(hero_id)
	_show_cultivation()


func _merge_selected_heroes() -> void:
	var result := _execute_command("merge_heroes", {"hero_ids": selected_merge_ids.duplicate()}, "")
	if bool(result.get("ok", false)):
		selected_merge_ids.clear()
		_show_cultivation()
	else:
		_show_notice("培育失败：%s" % result.get("error", "UNKNOWN"))


func _show_formation() -> void:
	app_state = AppState.FORMATION
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_show_management_shell("六人编队", _build_formation_body())


func _build_formation_body() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	row.add_child(grid)
	var state: RefCounted = game.current_state()
	var ids: Array[String] = state.formation.hero_ids()
	for index in 6:
		var hero: RefCounted = state.hero_by_id(ids[index])
		var slot := _button(_formation_slot_text(index, hero), COLOR_PRIMARY if index == selected_formation_slot else COLOR_PANEL, Vector2(150, 82), 13)
		var slot_index := index
		slot.pressed.connect(func() -> void:
			selected_formation_slot = slot_index
			_show_formation()
		)
		grid.add_child(slot)
	var reserve_panel := _panel(COLOR_PANEL, 10)
	reserve_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(reserve_panel)
	var reserve_column := VBoxContainer.new()
	reserve_column.add_theme_constant_override("separation", 6)
	reserve_panel.add_child(reserve_column)
	reserve_column.add_child(_label("替换 %s" % SLOT_NAMES[selected_formation_slot], 17, COLOR_PRIMARY))
	var reserves := _reserve_heroes()
	if reserves.is_empty():
		reserve_column.add_child(_label("当前没有未上阵英雄。", 15, COLOR_MUTED))
	for hero in reserves:
		var pick := _button("%s ★%d %s" % [hero.display_name, hero.star, _class_name(hero.class_id)], COLOR_PANEL_ALT, Vector2(220, 40), 13)
		var hero_id := String(hero.hero_id)
		pick.pressed.connect(func() -> void: _replace_formation_slot(hero_id))
		reserve_column.add_child(pick)
	return row


func _formation_slot_text(index: int, hero: RefCounted) -> String:
	if hero == null:
		return "%s\n空" % SLOT_NAMES[index]
	return "%s\n%s ★%d\n%s" % [SLOT_NAMES[index], hero.display_name, hero.star, _class_name(hero.class_id)]


func _replace_formation_slot(hero_id: String) -> void:
	var state: RefCounted = game.current_state()
	var payload: Dictionary = state.formation.to_dict()
	payload[SLOT_KEYS[selected_formation_slot]] = hero_id
	var result := _execute_command("set_formation", payload, "")
	if bool(result.get("ok", false)):
		_show_formation()
	else:
		_show_notice("编队保存失败：%s" % result.get("error", "UNKNOWN"))


func _reserve_heroes() -> Array[RefCounted]:
	var state: RefCounted = game.current_state()
	var deployed: Array[String] = state.formation.hero_ids()
	var reserves: Array[RefCounted] = []
	for hero in state.roster:
		if not deployed.has(String(hero.hero_id)):
			reserves.append(hero)
	return reserves


func _show_expedition() -> void:
	app_state = AppState.EXPEDITION
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_add_background(Color(0.02, 0.04, 0.08, 0.62))
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := _label("出征确认", 26, COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := _button("返回营地", COLOR_PANEL_ALT, Vector2(110, 40), 14)
	back.pressed.connect(_show_camp)
	header.add_child(back)
	var start := _button("开始攻城", COLOR_PRIMARY, Vector2(140, 40), 15)
	start.pressed.connect(_start_battle)
	header.add_child(start)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var stages := _panel(COLOR_PANEL, 10)
	stages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stages.custom_minimum_size.x = 900
	body.add_child(stages)
	var stage_column := VBoxContainer.new()
	stage_column.add_theme_constant_override("separation", 8)
	stages.add_child(stage_column)
	stage_column.add_child(_label("三阶段路线", 17, COLOR_PRIMARY))
	stage_column.add_child(_label("1. 城市外围：拆除外围路障", 15, COLOR_TEXT))
	stage_column.add_child(_label("2. 火力封锁区：拔掉火力塔与装甲门", 15, COLOR_TEXT))
	stage_column.add_child(_label("3. 基地广场：击毁电池、核心装甲、联盟核心", 15, COLOR_TEXT))
	stage_column.add_child(_label("六人自动推进，可手动释放技能。", 15, COLOR_ACCENT))
	var squad := _panel(COLOR_PANEL, 10)
	squad.custom_minimum_size.x = 650
	body.add_child(squad)
	var squad_column := VBoxContainer.new()
	squad_column.add_theme_constant_override("separation", 4)
	squad.add_child(squad_column)
	squad_column.add_child(_label("出征六人", 17, COLOR_PRIMARY))
	var squad_grid := GridContainer.new()
	squad_grid.columns = 2
	squad_grid.add_theme_constant_override("h_separation", 8)
	squad_grid.add_theme_constant_override("v_separation", 4)
	squad_column.add_child(squad_grid)
	var ids: Array[String] = game.current_state().formation.hero_ids()
	for index in 6:
		var hero: RefCounted = game.current_state().hero_by_id(ids[index])
		var hero_label := _label("%s  %s ★%d" % [SLOT_NAMES[index], _archetype_name(hero.archetype_id), hero.star], 13, COLOR_TEXT)
		hero_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		squad_grid.add_child(hero_label)
	start.grab_focus()


func _start_battle() -> void:
	app_state = AppState.BATTLE
	_clear_ui()
	_clear_world()
	battle_id = "stage_1_1-%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
	battle_elapsed = 0.0
	battle_snapshot_elapsed = 0.0
	battle_is_paused = false
	battle_world = BattleWorldScript.new()
	world_host.add_child(battle_world)
	battle_world.battle_finished.connect(_on_battle_finished)
	var snapshots: Array[Dictionary] = _build_battle_snapshots()
	battle_world.start_battle(snapshots)
	_build_battle_hud()
	_update_battle_hud()


func _build_battle_hud() -> void:
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(root)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)
	battle_pause_button = _button("暂停", COLOR_PANEL_ALT, Vector2(72, 40), 14)
	battle_pause_button.pressed.connect(_toggle_battle_pause)
	top.add_child(battle_pause_button)
	var stage := _panel(Color(0.055, 0.09, 0.14, 0.88), 8)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stage)
	var stage_row := HBoxContainer.new()
	stage_row.add_theme_constant_override("separation", 8)
	stage.add_child(stage_row)
	battle_stage_label = _label("阶段", 16, COLOR_TEXT)
	battle_stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_stage_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	battle_stage_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stage_row.add_child(battle_stage_label)
	battle_progress_label = _label("进度 0/1000", 14, COLOR_PRIMARY)
	battle_progress_label.custom_minimum_size.x = 130
	battle_progress_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stage_row.add_child(battle_progress_label)
	battle_timer_label = _label("00:00", 14, COLOR_ACCENT)
	battle_timer_label.custom_minimum_size.x = 70
	battle_timer_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stage_row.add_child(battle_timer_label)
	battle_warning_label = _label("无预警", 14, COLOR_MUTED)
	battle_warning_label.custom_minimum_size.x = 95
	battle_warning_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(battle_warning_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var bottom := _panel(Color(0.055, 0.09, 0.14, 0.84), 8)
	root.add_child(bottom)
	battle_skill_rows = VBoxContainer.new()
	battle_skill_rows.add_theme_constant_override("separation", 4)
	bottom.add_child(battle_skill_rows)


func _update_battle_hud() -> void:
	if battle_world == null or not battle_world.has_method("get_battle_snapshot"):
		return
	var snapshot: Dictionary = battle_world.get_battle_snapshot()
	if snapshot.is_empty():
		return
	battle_timer_label.text = "%02d:%02d" % [int(battle_elapsed) / 60, int(battle_elapsed) % 60]
	battle_stage_label.text = "阶段 %d/3  %s" % [int(snapshot.get("stage_index", 0)) + 1, snapshot.get("stage_name", "")]
	battle_progress_label.text = "推进 %d/1000" % int(snapshot.get("road_progress", 0))
	var warnings: Array = snapshot.get("warnings", [])
	battle_warning_label.text = "预警 %d" % warnings.size() if not warnings.is_empty() else "无预警"
	if battle_pause_button != null:
		battle_pause_button.text = "继续" if battle_is_paused else "暂停"
	_rebuild_skill_hud(snapshot)


func _toggle_battle_pause() -> void:
	if battle_world == null:
		return
	battle_is_paused = not battle_is_paused
	if battle_world.has_method("set_paused"):
		battle_world.set_paused(battle_is_paused)
	_update_battle_hud()


func _rebuild_skill_hud(snapshot: Dictionary) -> void:
	for child in battle_skill_rows.get_children():
		child.queue_free()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	battle_skill_rows.add_child(grid)
	var units: Array[Dictionary] = []
	for unit_value in snapshot.get("units", []):
		var unit := unit_value as Dictionary
		if int(unit.get("team", 0)) == 0 and not bool(unit.get("temporary", false)) and int(unit.get("slot", 99)) < 6:
			units.append(unit)
	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["slot"]) < int(b["slot"]))
	for unit in units:
		grid.add_child(_battle_unit_control(unit))


func _battle_unit_control(unit: Dictionary) -> Control:
	var card := _panel(COLOR_PANEL, 5)
	card.custom_minimum_size = Vector2(180, 72)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	card.add_child(column)
	var hp := _label("%s %d/%d E%d" % [
		SLOT_NAMES[int(unit["slot"])],
		int(unit["hp"]),
		int(unit["max_hp"]),
		int(unit["energy"]),
	], 11, COLOR_TEXT if bool(unit["alive"]) else COLOR_DANGER)
	hp.autowrap_mode = TextServer.AUTOWRAP_OFF
	hp.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(hp)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	column.add_child(row)
	var skill_name := _label(_skill_short(String(unit["skill_id"])), 11, COLOR_MUTED)
	skill_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(skill_name)
	var unit_id := StringName(unit["unit_id"])
	var skill := _button("技", COLOR_PRIMARY, Vector2(44, 24), 10)
	skill.disabled = int(unit["energy"]) < 100 or not bool(unit["alive"])
	skill.pressed.connect(func() -> void:
		if battle_world != null:
			battle_world.request_skill(unit_id)
			_update_battle_hud()
	)
	row.add_child(skill)
	var auto := CheckButton.new()
	auto.text = ""
	auto.button_pressed = bool(unit.get("auto_skill", false))
	auto.custom_minimum_size = Vector2(36, 24) * UI_SCALE
	auto.add_theme_font_size_override("font_size", int(10 * UI_SCALE))
	auto.toggled.connect(func(enabled: bool) -> void:
		var result := _execute_command("set_auto_skill_preference", {"hero_id": String(unit_id), "enabled": enabled}, "")
		if bool(result.get("ok", false)):
			if battle_world != null:
				battle_world.set_auto_skill(unit_id, enabled)
			_update_battle_hud()
		else:
			auto.set_pressed_no_signal(not enabled)
			_show_notice("自动技能偏好保存失败：%s" % result.get("error", "UNKNOWN"))
	)
	row.add_child(auto)
	return card


func _on_battle_finished(result: Dictionary) -> void:
	var outcome := String(result.get("outcome", "defeat"))
	var ticks := clampi(int(result.get("ticks", 1)), 1, 300)
	var settlement := _execute_command(
		"settle_battle",
		{"battle_id": battle_id, "outcome": outcome, "ticks": ticks},
		"battle:%s" % battle_id
	)
	if not bool(settlement.get("ok", false)):
		_show_result(result, {}, "结算保存失败：%s" % settlement.get("error", "UNKNOWN"))
		return
	_show_result(result, settlement.get("event", {}) as Dictionary)


func _show_result(result: Dictionary, settlement: Dictionary, error_message: String = "") -> void:
	app_state = AppState.RESULT
	_clear_ui()
	_add_background(Color(0.02, 0.04, 0.08, 0.72))
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(center)
	var panel := _panel(COLOR_PANEL, 14)
	panel.custom_minimum_size = Vector2(520, 250)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var victory := String(result.get("outcome", "defeat")) == "victory"
	column.add_child(_label("核心已摧毁" if victory else "攻城失败", 28, COLOR_ACCENT if victory else COLOR_DANGER))
	var reason := String(result.get("reason", ""))
	var reason_text: String = String({
		"core_destroyed": "联盟核心已经坍塌",
		"main_squad_defeated": "六名主力全部阵亡",
		"timeout": "60 秒内攻城输出不足",
		"invalid_formation": "出征编队不足六人",
	}.get(reason, reason))
	column.add_child(_label(
		"到达阶段 %d/3 · 摧毁结构 %d/7 · %s" % [
			clampi(int(result.get("stage_reached", 0)) + 1, 1, 3),
			int(result.get("structures_destroyed", 0)),
			reason_text,
		],
		14,
		COLOR_TEXT
	))
	var reward: Dictionary = settlement.get("reward", {}) as Dictionary
	column.add_child(_label(
		"奖励：金币%d 书%d 瓷%d 零%d 泥%d" % [
			int(reward.get("gold", 0)),
			int(reward.get("xp_books", 0)),
			int(reward.get("porcelain", 0)),
			int(reward.get("parts", 0)),
			int(reward.get("sludge", 0)),
		],
		17,
		COLOR_PRIMARY if victory else COLOR_MUTED
	))
	if not victory:
		column.add_child(_label("失败也会带回少量残骸；去工厂补同型单位、培育升星或开启自动技能。", 13, COLOR_ACCENT))
	if not error_message.is_empty():
		column.add_child(_label(error_message, 14, COLOR_DANGER))
	var actions := GridContainer.new()
	actions.columns = 5
	actions.add_theme_constant_override("h_separation", 6)
	column.add_child(actions)
	var factory := _button("工厂", COLOR_PANEL_ALT, Vector2(90, 42), 14)
	factory.pressed.connect(_show_factory)
	actions.add_child(factory)
	var cultivate := _button("培育", COLOR_PANEL_ALT, Vector2(90, 42), 14)
	cultivate.pressed.connect(_show_cultivation)
	actions.add_child(cultivate)
	var formation := _button("编队", COLOR_PANEL_ALT, Vector2(90, 42), 14)
	formation.pressed.connect(_show_formation)
	actions.add_child(formation)
	var retry := _button("重试", COLOR_PRIMARY, Vector2(90, 42), 14)
	retry.pressed.connect(_show_expedition)
	actions.add_child(retry)
	var camp := _button("营地", COLOR_PANEL_ALT, Vector2(90, 42), 14)
	camp.pressed.connect(_show_camp)
	actions.add_child(camp)


func _build_battle_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	var state: RefCounted = game.current_state()
	var hero_ids: Array[String] = state.formation.hero_ids()
	for slot_index in 6:
		var hero_id: String = hero_ids[slot_index]
		var hero: RefCounted = state.hero_by_id(hero_id)
		var stats: Dictionary = HeroProgression.derived_battle_stats(hero)
		var skill_id := FactoryCatalog.active_skill_for_archetype(hero.archetype_id)
		snapshots.append({
			"hero_id": hero.hero_id,
			"display_name": hero.display_name,
			"archetype_id": hero.archetype_id,
			"class_id": hero.class_id,
			"star": hero.star,
			"max_hp": int(stats["max_hp"]),
			"attack": maxi(int(stats["physical_atk"]), int(stats["magic_atk"])),
			"defense": int(stats["defense"]),
			"slot": slot_index,
			"skill_id": skill_id,
			"auto_skill": hero.auto_skill_enabled,
		})
	return snapshots


func _execute_command(command_type: String, payload: Dictionary, business_key: String) -> Dictionary:
	command_serial += 1
	var now := Time.get_ticks_msec()
	var command_id := "%s-%d-%d" % [command_type, now, command_serial]
	var key := business_key if not business_key.is_empty() else command_id
	return game.execute_command({
		"command_id": command_id,
		"type": command_type,
		"payload": payload,
		"business_key": key,
		"expected_revision": game.current_state().revision,
		"requested_at": int(Time.get_unix_time_from_system()),
	})


func _show_management_shell(title_text: String, body: Control) -> void:
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(root)
	root.add_child(_build_top_bar())
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)
	var title := _label(title_text, 24, COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := _button("返回营地", COLOR_PANEL_ALT, Vector2(110, 38), 14)
	back.pressed.connect(_show_camp)
	header.add_child(back)
	root.add_child(body)


func _show_notice(message: String) -> void:
	var notice := Label.new()
	notice.text = message
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_size_override("font_size", 15)
	notice.add_theme_color_override("font_color", Color("#ffcf70"))
	notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notice.position = Vector2(-240, 56)
	notice.custom_minimum_size = Vector2(480, 32)
	ui_root.add_child(notice)
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(notice, "modulate:a", 0.0, 0.4)
	tween.tween_callback(notice.queue_free)


func _build_camp_world() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#101e31")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#91a8bf")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	world_host.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = false
	world_host.add_child(sun)
	var camera := Camera3D.new()
	camera.position = Vector3(8, 6.5, 10)
	camera.look_at_from_position(camera.position, Vector3(0, 1.2, 0))
	camera.fov = 42
	camera.current = true
	world_host.add_child(camera)
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(22, 16)
	floor.mesh = floor_mesh
	floor.material_override = _material(Color("#24364b"), 0.9)
	world_host.add_child(floor)
	for index in 7:
		var block := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.6 + index * 0.25, 1.5 + index * 0.5, 1.8)
		block.mesh = mesh
		block.position = Vector3(-7.5 + index * 2.5, mesh.size.y * 0.5, -3.5)
		block.material_override = _material(Color("#30475e").lightened(index * 0.025), 0.85)
		world_host.add_child(block)
	for lane in [-1, 1]:
		var strip := MeshInstance3D.new()
		var strip_mesh := BoxMesh.new()
		strip_mesh.size = Vector3(0.12, 0.02, 12)
		strip.mesh = strip_mesh
		strip.position = Vector3(lane * 2.4, 0.02, 0)
		strip.material_override = _material(Color("#dfc16e"), 0.8)
		world_host.add_child(strip)


func _build_factory_world() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#101825")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#91a8bf")
	environment.ambient_light_energy = 0.78
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	world_host.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -28, 0)
	sun.light_energy = 1.05
	world_host.add_child(sun)
	var camera := Camera3D.new()
	camera.position = Vector3(8.5, 5.8, 9.5)
	camera.look_at_from_position(camera.position, Vector3(0, 1.0, -0.6))
	camera.fov = 43
	camera.current = true
	world_host.add_child(camera)
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(24, 14)
	floor.mesh = floor_mesh
	floor.material_override = _material(Color("#1f2c3a"), 0.88)
	world_host.add_child(floor)
	var workshop_colors := [Color("#2f6f7b"), Color("#594a7a"), Color("#6a5840"), Color("#4d704c")]
	for index in 4:
		var line := MeshInstance3D.new()
		line.name = "FactoryLine_%d" % index
		var line_mesh := BoxMesh.new()
		line_mesh.size = Vector3(4.4, 0.35, 1.1)
		line.mesh = line_mesh
		line.position = Vector3(-5.7 + float(index) * 3.8, 0.18, -1.2)
		line.material_override = _material(workshop_colors[index], 0.62)
		world_host.add_child(line)
		var machine := MeshInstance3D.new()
		machine.name = "FactoryMachine_%d" % index
		var machine_mesh := CylinderMesh.new()
		machine_mesh.top_radius = 0.55
		machine_mesh.bottom_radius = 0.75
		machine_mesh.height = 1.8
		machine_mesh.radial_segments = 10
		machine.mesh = machine_mesh
		machine.position = line.position + Vector3(0.0, 1.08, -0.1)
		machine.material_override = _material(workshop_colors[index].lightened(0.2), 0.5)
		world_host.add_child(machine)
		var door := MeshInstance3D.new()
		door.name = "FactoryDoor_%d" % index
		var door_mesh := BoxMesh.new()
		door_mesh.size = Vector3(0.9, 1.0, 0.14)
		door.mesh = door_mesh
		door.position = line.position + Vector3(0.0, 0.78, 0.74)
		door.material_override = _material(Color("#d9e8ed"), 0.54)
		world_host.add_child(door)


func _play_factory_start_feedback(recipe_id: String) -> void:
	_show_notice("设备启动：%s 正在生产。" % String(FactoryCatalog.recipe(recipe_id).get("display_name", recipe_id)))
	var machine := world_host.get_node_or_null("FactoryMachine_%d" % _workshop_index(String(FactoryCatalog.recipe(recipe_id).get("workshop", "ordinary")))) as Node3D
	if machine == null:
		return
	var tween := machine.create_tween()
	tween.tween_property(machine, "scale", Vector3(1.18, 0.86, 1.18), 0.12)
	tween.tween_property(machine, "scale", Vector3.ONE, 0.18)


func _play_factory_claim_feedback(hero_id: String, recipe_id: String) -> void:
	var recipe := FactoryCatalog.recipe(recipe_id)
	_show_notice("仓门开启：%s 入列，%s ★1。" % [String(recipe.get("display_name", hero_id)), String(recipe.get("rarity", ""))])
	var workshop := String(recipe.get("workshop", "ordinary"))
	var door := world_host.get_node_or_null("FactoryDoor_%d" % _workshop_index(workshop)) as Node3D
	if door != null:
		var tween := door.create_tween()
		tween.tween_property(door, "position:y", door.position.y + 0.75, 0.18)
		tween.tween_property(door, "position:y", door.position.y, 0.26)
	var reveal := MeshInstance3D.new()
	reveal.name = "FactoryReveal"
	var mesh := SphereMesh.new()
	mesh.radius = 0.32
	mesh.height = 0.64
	mesh.radial_segments = 10
	mesh.rings = 5
	reveal.mesh = mesh
	reveal.position = Vector3(-5.7 + float(_workshop_index(workshop)) * 3.8, 1.15, 0.15)
	reveal.material_override = _material(Color("#ffe082"), 0.5)
	world_host.add_child(reveal)
	var appear := reveal.create_tween()
	reveal.scale = Vector3(0.2, 0.2, 0.2)
	appear.tween_property(reveal, "scale", Vector3(1.35, 1.35, 1.35), 0.22)
	appear.tween_property(reveal, "transparency", 1.0, 0.5)
	appear.tween_callback(reveal.queue_free)


func _clear_ui() -> void:
	battle_timer_label = null
	battle_stage_label = null
	battle_warning_label = null
	battle_progress_label = null
	battle_skill_rows = null
	status_label = null
	for child in ui_root.get_children():
		child.queue_free()


func _clear_world() -> void:
	battle_world = null
	for child in world_host.get_children():
		child.queue_free()


func _add_background(color: Color) -> void:
	var background := ColorRect.new()
	background.color = color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(background)


func _safe_margin() -> MarginContainer:
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", int(14 * UI_SCALE))
	safe.add_theme_constant_override("margin_right", int(14 * UI_SCALE))
	safe.add_theme_constant_override("margin_top", int(10 * UI_SCALE))
	safe.add_theme_constant_override("margin_bottom", int(10 * UI_SCALE))
	return safe


func _panel(color: Color, padding: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	var scaled_padding := int(padding * UI_SCALE)
	style.content_margin_left = scaled_padding
	style.content_margin_right = scaled_padding
	style.content_margin_top = scaled_padding
	style.content_margin_bottom = scaled_padding
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(color, 1.0).lightened(0.15)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _button(text: String, color: Color, min_size: Vector2 = Vector2(120, 48), font_size: int = 16) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size * UI_SCALE
	button.focus_mode = Control.FOCUS_ALL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color.darkened(0.35) if state_name == "disabled" else color.lightened(0.10 if state_name == "hover" else (-0.08 if state_name == "pressed" else 0.0))
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.content_margin_left = int(8 * UI_SCALE)
		style.content_margin_right = int(8 * UI_SCALE)
		style.content_margin_top = int(6 * UI_SCALE)
		style.content_margin_bottom = int(6 * UI_SCALE)
		if state_name == "focus":
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_color = COLOR_TEXT
		button.add_theme_stylebox_override(state_name, style)
	button.add_theme_font_size_override("font_size", int(font_size * UI_SCALE))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", int(size * UI_SCALE))
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _resource_chip(name_text: String, value: String, color: Color) -> Control:
	var chip := _panel(COLOR_PANEL_ALT, 5)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	chip.add_child(row)
	row.add_child(_label(name_text, 12, COLOR_MUTED))
	row.add_child(_label(value, 14, color))
	return chip


func _build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = CJKFont
	theme.default_font_size = int(14 * UI_SCALE)
	return theme


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _class_name(class_id: String) -> String:
	return {
		"guardian": "重装",
		"fighter": "突击",
		"ranger": "远程",
		"arcanist": "能量",
	}.get(class_id, class_id)


func _merge_group_key(hero_id: String) -> String:
	var hero: RefCounted = game.current_state().hero_by_id(hero_id)
	if hero == null:
		return ""
	return "%s|%d" % [hero.archetype_id, hero.star]


func _archetype_name(archetype_id: String) -> String:
	return {
		"assault": "冲锋马桶人",
		"sonic": "音波马桶人",
		"rocket": "火箭飞行马桶人",
		"bomber": "自爆飞行马桶人",
		"armored": "装甲冲城马桶人",
		"saw": "双锯重装马桶人",
		"repair": "维修马桶人",
		"parasite": "寄生母体马桶人",
	}.get(archetype_id, archetype_id)


func _blueprint_hint(recipe_id: String) -> String:
	var rows: Array = FactoryService.blueprint_status(game.current_state()).filter(func(row: Dictionary) -> bool: return String(row["recipe_id"]) == recipe_id)
	if rows.is_empty():
		return "等待蓝图解锁"
	return String((rows[0] as Dictionary).get("unlock_hint", "等待蓝图解锁"))


func _workshop_index(workshop_id: String) -> int:
	return {
		"ordinary": 0,
		"flying": 1,
		"heavy": 2,
		"special": 3,
	}.get(workshop_id, 0)


func _skill_short(skill_id: String) -> String:
	return {
		"plunger_charge": "冲",
		"sonic_disruptor": "音",
		"rocket_salvo": "箭",
		"suicide_dive": "爆",
		"siege_shield": "盾",
		"saw_rush": "锯",
		"field_repair": "修",
		"parasite_swarm": "寄",
	}.get(skill_id, "技")


func _role_name(role_id: String) -> String:
	return {
		"frontline_breaker": "前线突破",
		"crowd_control": "群体控制",
		"siege_artillery": "远程攻城",
		"burst_sacrifice": "爆发突击",
		"siege_tank": "攻城承伤",
		"elite_duelist": "精英斩杀",
		"sustain_support": "持续修复",
		"summoner_debuffer": "召唤干扰",
	}.get(role_id, role_id)
