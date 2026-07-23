extends Control

const CanonicalRunner := preload("res://game/scripts/domain/battle/canonical_battle_runner.gd")
const M4Runner := preload("res://game/scripts/domain/battle/m4_canonical_battle_runner.gd")
const SessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const UnitScript := preload("res://game/scripts/domain/battle/battle_unit.gd")
const FormationReducerScript := preload("res://game/scripts/domain/formation/formation_reducer.gd")
const StageCatalog := preload("res://game/scripts/presentation/m3_stage_catalog.gd")
const HeroGenerator := preload("res://game/scripts/domain/heroes/hero_generator.gd")
const LootGenerator := preload("res://game/scripts/domain/loot/loot_generator.gd")

const DEMO_RUN_SEED := 1
const STAGE_ORDER: Array[String] = ["stage-1-1", "stage-1-2", "stage-1-3", "stage-1-4", "stage-1-5"]
const STAGE_TITLES := {
	"stage-1-1": "关卡 1-1 · 边境遭遇",
	"stage-1-2": "关卡 1-2 · 林间伏击",
	"stage-1-3": "关卡 1-3 · 岩甲魔像",
	"stage-1-4": "关卡 1-4 · 双线夹击",
	"stage-1-5": "关卡 1-5 · 首领试炼",
}
const CLASS_NAMES := {
	"guardian": "守护者",
	"fighter": "战士",
	"ranger": "游侠",
	"arcanist": "秘法师",
}
const TRAIT_NAMES := {
	"steadfast": "稳健",
	"bold": "勇猛",
	"watchful": "警觉",
	"quick": "迅捷",
	"patient": "沉着",
	"fierce": "烈性",
	"clever": "机敏",
	"kind": "亲和",
}
const FACILITY_NAMES := {
	"tavern": "酒馆",
	"blacksmith": "铁匠铺",
	"training_ground": "训练场",
}
const SLOT_NAMES := {
	"front_1": "前排一",
	"front_2": "前排二",
	"back_1": "后排一",
	"back_2": "后排二",
}

@onready var _safe_area: MarginContainer = $SafeArea
@onready var _battle_screen: VBoxContainer = $SafeArea/BattleScreen
@onready var _arena: BattleArena = $SafeArea/BattleScreen/Arena
@onready var _stage_name: Label = $SafeArea/BattleScreen/BattleInfo/InfoRows/StageName
@onready var _battle_status: Label = $SafeArea/BattleScreen/BattleInfo/InfoRows/Status
@onready var _start_button: Button = $SafeArea/BattleScreen/ActionButtons/StartButton
@onready var _formation_button: Button = $SafeArea/BattleScreen/ActionButtons/FormationButton
@onready var _formation_hint: Label = $SafeArea/BattleScreen/FormationHint
@onready var _battle_log: RichTextLabel = $SafeArea/BattleScreen/LogPanel/LogRows/BattleLog
@onready var _stage_buttons: Array[Button] = [
	$SafeArea/BattleScreen/StageSelector/Stage11,
	$SafeArea/BattleScreen/StageSelector/Stage12,
	$SafeArea/BattleScreen/StageSelector/Stage13,
	$SafeArea/BattleScreen/StageSelector/Stage14,
	$SafeArea/BattleScreen/StageSelector/Stage15,
]

# Hidden compatibility dashboard for the M1 bootstrap contract.
@onready var _status: Label = $SafeArea/Content/Status
@onready var _persistence: Label = $SafeArea/Content/StateCard/StateContent/Persistence
@onready var _save_id: Label = $SafeArea/Content/StateCard/StateContent/SaveId
@onready var _revision: Label = $SafeArea/Content/StateCard/StateContent/Revision
@onready var _offline_credit: Label = $SafeArea/Content/StateCard/StateContent/OfflineCredit
@onready var _refresh_button: Button = $SafeArea/Content/RefreshButton

var _game: Object
var _manifest: Dictionary = {}
var _selected_stage := "stage-1-1"
var _pending_stage := ""
var _formation_adjusted := false
var _equipment_adjusted := false
var _session: BattleSession
var _snapshot: Dictionary = {}
var _previous_hp: Dictionary = {}
var _unit_names: Dictionary = {}
var _logged_result := false
var _current_page := "expedition"
var _selected_hero_id := ""
var _selected_item_id := ""
var _command_serial := 0
var _settled_results: Dictionary = {}

var _shell: VBoxContainer
var _resource_bar: HBoxContainer
var _page_stack: Control
var _hero_page: ScrollContainer
var _forge_page: ScrollContainer
var _camp_page: ScrollContainer
var _quest_page: ScrollContainer
var _bottom_nav: HBoxContainer
var _toast: Label
var _hero_rows: VBoxContainer
var _formation_slots: GridContainer
var _forge_items: VBoxContainer
var _camp_rows: VBoxContainer
var _quest_rows: VBoxContainer


func _ready() -> void:
	_build_operation_board()
	_refresh_button.pressed.connect(_refresh_state)
	_start_button.pressed.connect(_on_start_pressed)
	_formation_button.pressed.connect(_on_formation_pressed)
	for index: int in _stage_buttons.size():
		_stage_buttons[index].pressed.connect(_select_stage.bind(STAGE_ORDER[index]))
	_load_manifest()
	_select_stage(_selected_stage)
	configure_game(get_tree().root.get_node_or_null("Game"))
	_start_button.grab_focus()


func _process(delta: float) -> void:
	if _session == null or _session.result != null:
		return
	var processed := _session.advance_frame(delta)
	if processed <= 0:
		return
	_capture_damage_feedback()
	_arena.queue_redraw()
	_battle_status.text = "自动战斗中 · 第 %d 回合" % _session.tick_index
	if _session.result != null:
		_finish_battle()


func has_active_battle() -> bool:
	return _session != null and _session.result == null


func get_battle_result() -> BattleResult:
	return null if _session == null else _session.result


func configure_game(game_port: Object) -> void:
	var ready_callable := Callable(self, "_refresh_state")
	if _game != null and _game.has_signal("game_ready") and _game.is_connected(
		"game_ready", ready_callable
	):
		_game.disconnect("game_ready", ready_callable)
	_game = game_port
	if _game != null and _game.has_signal("game_ready") and not _game.is_connected(
		"game_ready", ready_callable
	):
		_game.connect("game_ready", ready_callable)
	_refresh_state()


func _build_operation_board() -> void:
	_battle_screen.name = "BattleScreen"
	_battle_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_battle_screen.custom_minimum_size = Vector2(0, 0)
	_arena.custom_minimum_size = Vector2(0, 600)
	_start_button.custom_minimum_size.y = 88
	_formation_button.custom_minimum_size.y = 88

	_shell = VBoxContainer.new()
	_shell.name = "OperationBoard"
	_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shell.add_theme_constant_override("separation", 14)
	_safe_area.add_child(_shell)
	_safe_area.move_child(_shell, 0)

	_resource_bar = HBoxContainer.new()
	_resource_bar.name = "ResourceBar"
	_resource_bar.custom_minimum_size = Vector2(0, 98)
	_resource_bar.add_theme_constant_override("separation", 8)
	_shell.add_child(_resource_bar)

	_page_stack = Control.new()
	_page_stack.name = "Pages"
	_page_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shell.add_child(_page_stack)

	_battle_screen.reparent(_page_stack)
	_battle_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_hero_page = _make_page("HeroesPage")
	_forge_page = _make_page("ForgePage")
	_camp_page = _make_page("CampPage")
	_quest_page = _make_page("QuestPage")
	_page_stack.add_child(_hero_page)
	_page_stack.add_child(_forge_page)
	_page_stack.add_child(_camp_page)
	_page_stack.add_child(_quest_page)

	_bottom_nav = HBoxContainer.new()
	_bottom_nav.name = "BottomNav"
	_bottom_nav.custom_minimum_size = Vector2(0, 96)
	_bottom_nav.add_theme_constant_override("separation", 8)
	_shell.add_child(_bottom_nav)
	for spec: Dictionary in [
		{"id": "expedition", "text": "远征"},
		{"id": "heroes", "text": "英雄"},
		{"id": "forge", "text": "锻造"},
		{"id": "camp", "text": "营地"},
		{"id": "quests", "text": "任务"},
	]:
		var nav := _make_button(str(spec.text), 88)
		nav.name = "Nav%s" % str(spec.id).capitalize()
		nav.pressed.connect(_show_page.bind(str(spec.id)))
		_bottom_nav.add_child(nav)

	_toast = Label.new()
	_toast.name = "CommandStatus"
	_toast.add_theme_font_size_override("font_size", 20)
	_toast.add_theme_color_override("font_color", Color(0.78, 0.86, 0.95))
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shell.add_child(_toast)

	_build_hero_page()
	_build_forge_page()
	_build_camp_page()
	_build_quest_page()
	_show_page("expedition")


func _make_page(page_name: String) -> ScrollContainer:
	var page := ScrollContainer.new()
	page.name = page_name
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return page


func _build_hero_page() -> void:
	var root := VBoxContainer.new()
	root.name = "HeroContent"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	_hero_page.add_child(root)
	root.add_child(_make_section_label("英雄与编队"))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var recruit := _make_button("招募英雄", 88)
	recruit.name = "RecruitButton"
	recruit.pressed.connect(_on_recruit_pressed)
	actions.add_child(recruit)
	var train := _make_button("训练选中", 88)
	train.name = "TrainButton"
	train.pressed.connect(_on_train_pressed)
	actions.add_child(train)
	var swap := _make_button("四槽换位", 88)
	swap.name = "SwapFormationButton"
	swap.pressed.connect(_on_swap_formation_pressed)
	actions.add_child(swap)
	_formation_slots = GridContainer.new()
	_formation_slots.name = "FormationSlots"
	_formation_slots.columns = 2
	_formation_slots.add_theme_constant_override("h_separation", 8)
	_formation_slots.add_theme_constant_override("v_separation", 8)
	root.add_child(_formation_slots)
	_hero_rows = VBoxContainer.new()
	_hero_rows.name = "HeroRows"
	_hero_rows.add_theme_constant_override("separation", 8)
	root.add_child(_hero_rows)


func _build_forge_page() -> void:
	var root := VBoxContainer.new()
	root.name = "ForgeContent"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	_forge_page.add_child(root)
	root.add_child(_make_section_label("锻造与掉落"))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var equip := _make_button("装备选中", 88)
	equip.name = "EquipButton"
	equip.pressed.connect(_on_equip_pressed)
	actions.add_child(equip)
	var enhance := _make_button("强化选中", 88)
	enhance.name = "EnhanceButton"
	enhance.pressed.connect(_on_enhance_pressed)
	actions.add_child(enhance)
	_forge_items = VBoxContainer.new()
	_forge_items.name = "ForgeItems"
	_forge_items.add_theme_constant_override("separation", 8)
	root.add_child(_forge_items)


func _build_camp_page() -> void:
	var root := VBoxContainer.new()
	root.name = "CampContent"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	_camp_page.add_child(root)
	root.add_child(_make_section_label("营地设施"))
	_camp_rows = VBoxContainer.new()
	_camp_rows.name = "CampRows"
	_camp_rows.add_theme_constant_override("separation", 8)
	root.add_child(_camp_rows)


func _build_quest_page() -> void:
	var root := VBoxContainer.new()
	root.name = "QuestContent"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	_quest_page.add_child(root)
	root.add_child(_make_section_label("任务奖励"))
	var note := Label.new()
	note.name = "SoftGuidanceNote"
	note.text = "任务只给奖励与方向，不锁定关卡推进。"
	note.add_theme_font_size_override("font_size", 22)
	note.add_theme_color_override("font_color", Color(0.96, 0.78, 0.42))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(note)
	_quest_rows = VBoxContainer.new()
	_quest_rows.name = "QuestRows"
	_quest_rows.add_theme_constant_override("separation", 8)
	root.add_child(_quest_rows)


func _show_page(page_id: String) -> void:
	_current_page = page_id
	_battle_screen.visible = page_id == "expedition"
	_hero_page.visible = page_id == "heroes"
	_forge_page.visible = page_id == "forge"
	_camp_page.visible = page_id == "camp"
	_quest_page.visible = page_id == "quests"
	for button: Button in _bottom_nav.get_children():
		button.disabled = button.name.to_lower().contains(page_id)


func _load_manifest() -> void:
	_manifest = {"scenarios": StageCatalog.scenarios()}


func _select_stage(stage_id: String) -> void:
	if _session != null and _session.result == null:
		return
	_selected_stage = stage_id
	_pending_stage = ""
	_formation_adjusted = false
	_equipment_adjusted = false
	_session = null
	_snapshot.clear()
	_previous_hp.clear()
	_arena.clear_battle()
	_stage_name.text = str(STAGE_TITLES.get(stage_id, stage_id))
	_battle_status.text = "四人小队已就绪 · 点击开始自动战斗"
	_start_button.text = "开始战斗"
	_formation_button.text = "调整编队再战"
	_start_button.disabled = _manifest.is_empty()
	_formation_button.visible = false
	_formation_hint.visible = false
	_battle_log.text = "[color=#8ba7cc]%s[/color]\n等待远征指令……" % _stage_name.text
	_set_stage_buttons_enabled(true)


func _on_start_pressed() -> void:
	if not _pending_stage.is_empty():
		_select_stage(_pending_stage)
	var apply_intervention := _formation_adjusted or _equipment_adjusted
	_start_battle(apply_intervention)


func _on_formation_pressed() -> void:
	_formation_adjusted = true
	_formation_button.visible = false
	_formation_hint.visible = true
	_append_log("[color=#f2c76e]编队指令：守护者与主力交换前排站位。[/color]")
	_execute_predeclared_intervention()
	_start_battle(true)


func _start_battle(apply_intervention: bool) -> void:
	if _manifest.is_empty():
		return
	var scenarios: Dictionary = _manifest.get("scenarios", {})
	if not scenarios.has(_selected_stage):
		return
	var reserve := _execute_game_command(
		"reserve_battle_attempt",
		{"stage_id": _selected_stage},
		"battle:%s:attempt" % _selected_stage
	)
	if _game != null and _game.has_method("execute_command") and not reserve.get("ok", false):
		_toast.text = "无法开始：%s" % str(reserve.get("code", "UNKNOWN"))
		return
	var scenario: Dictionary = scenarios[_selected_stage]
	var runner: Variant = M4Runner if _selected_stage in ["stage-1-4", "stage-1-5"] else CanonicalRunner
	_snapshot = runner.materialize(scenario, DEMO_RUN_SEED, apply_intervention)
	var units := _make_units(_snapshot)
	_session = SessionScript.new(int(_snapshot["battle_seed"]), units)
	_previous_hp.clear()
	for unit: BattleUnit in _session.units:
		_previous_hp[unit.unit_id] = unit.hp
	_logged_result = false
	_arena.present_units(_session.units, _unit_names)
	_start_button.disabled = true
	_formation_button.visible = false
	_formation_hint.visible = apply_intervention
	_set_stage_buttons_enabled(false)
	_battle_log.text = "[color=#f2c76e]战斗开始！[/color] 四名英雄进入战场。"
	if apply_intervention:
		_append_log("成长干预已通过真实命令入口尝试提交。")


func _make_units(snapshot: Dictionary) -> Array[BattleUnit]:
	var units: Array[BattleUnit] = []
	var slot_names: Array[String] = FormationReducerScript.SLOT_ORDER
	var roster_by_id: Dictionary = {}
	for hero: Dictionary in snapshot["roster"]:
		roster_by_id[hero["id"]] = hero
	_unit_names.clear()
	for slot_index: int in slot_names.size():
		var hero_id: String = snapshot["formation"][slot_names[slot_index]]
		var stats: Dictionary = snapshot["combat_stats"][hero_id]
		var hero: Dictionary = roster_by_id[hero_id]
		var hero_name := str(CLASS_NAMES.get(hero["class_id"], "英雄"))
		_unit_names[hero_id] = hero_name
		units.append(UnitScript.new(
			hero_id, 0, slot_index, int(stats["speed"]), int(stats["hp"]), int(stats["attack"])
		))
	var enemy: Dictionary = snapshot["enemy"]
	_unit_names["zz-enemy"] = "岩甲魔像"
	units.append(UnitScript.new(
		"zz-enemy", 1, 0, int(enemy["speed"]), int(enemy["hp"]), int(enemy["attack"])
	))
	return units


func _capture_damage_feedback() -> void:
	for unit: BattleUnit in _session.units:
		var previous := int(_previous_hp.get(unit.unit_id, unit.hp))
		if unit.hp < previous:
			var damage := previous - unit.hp
			_arena.show_damage(unit.unit_id, damage)
			_append_log("%s受到 [color=#ffbd59]%d[/color] 点伤害，剩余 HP %d。" % [
				str(_unit_names.get(unit.unit_id, unit.unit_id)), damage, unit.hp
			])
		_previous_hp[unit.unit_id] = unit.hp


func _finish_battle() -> void:
	if _logged_result:
		return
	_logged_result = true
	_capture_damage_feedback()
	var won := _session.result.winner == 0
	var result_text := "胜利" if won else "失败"
	_battle_status.text = "%s · %d 回合 · 结果 #%s" % [
		result_text, _session.result.ticks, _session.result.digest.left(8)
	]
	_append_log("[color=%s][font_size=26]%s[/font_size][/color] · 共 %d 次攻击。" % [
		"#58d68d" if won else "#ff667a", result_text, _session.result.events.size()
	])
	_settle_battle_result(won)
	_start_button.disabled = false
	_set_stage_buttons_enabled(true)
	if won:
		var current_index := STAGE_ORDER.find(_selected_stage)
		if current_index >= 0 and current_index < STAGE_ORDER.size() - 1:
			_pending_stage = STAGE_ORDER[current_index + 1]
			_start_button.text = "进入下一关"
		else:
			_start_button.text = "再次挑战"
	else:
		_pending_stage = ""
		_start_button.text = "重新战斗"
		if _selected_stage in ["stage-1-3", "stage-1-4"] and not _formation_adjusted:
			_formation_button.visible = true
			_formation_hint.visible = true
			_start_button.text = "原编队重战"
		elif _selected_stage == "stage-1-5" and not _equipment_adjusted:
			_formation_button.visible = true
			_formation_hint.visible = true
			_formation_button.text = "装备强化再战"


func _settle_battle_result(won: bool) -> void:
	var outcome := "win" if won else "defeat"
	var key := "%s:%s" % [_selected_stage, outcome]
	if _settled_results.has(key):
		return
	_settled_results[key] = true
	var progress: Dictionary = _state().get("stage_progress", {})
	var stage: Dictionary = progress.get(_selected_stage, {})
	var result := _execute_game_command(
		"settle_battle_result",
		{
			"stage_id": _selected_stage,
			"outcome": outcome,
			"first_clear": won and not bool(stage.get("cleared", false)),
		},
		"stage:%s:%s" % [_selected_stage, outcome]
	)
	if result.get("ok", false):
		_refresh_state()


func _append_log(message: String) -> void:
	_battle_log.append_text("\n" + message)


func _set_stage_buttons_enabled(enabled: bool) -> void:
	for index: int in _stage_buttons.size():
		_stage_buttons[index].disabled = not enabled or STAGE_ORDER[index] == _selected_stage


func _refresh_state() -> void:
	var state := _state()
	if state.is_empty():
		_show_waiting_state()
		_render_board({})
		return
	_status.text = "M1 状态已加载"
	_persistence.text = "持久化：已安装快照"
	var identifier := str(state.get("save_id", ""))
	_save_id.text = "存档：%s" % (
		identifier.left(8) + "…" if identifier.length() > 8 else identifier
	)
	_revision.text = "状态版本：r%d" % int(state.get("revision", 0))
	var economy: Dictionary = state.get("economy", { })
	_offline_credit.text = "累计离线收益：%s" % _format_duration(
		int(economy.get("offline_seconds", 0))
	)
	_render_board(state)


func _show_waiting_state() -> void:
	_status.text = "M1 正在初始化"
	_persistence.text = "持久化：等待 Game 就绪"
	_save_id.text = "存档：—"
	_revision.text = "状态版本：—"
	_offline_credit.text = "累计离线收益：—"


func _render_board(state: Dictionary) -> void:
	_render_resources(state)
	_render_heroes(state)
	_render_forge(state)
	_render_camp(state)
	_render_quests(state)


func _render_resources(state: Dictionary) -> void:
	_clear_children(_resource_bar)
	var economy: Dictionary = state.get("economy", {})
	for spec: Dictionary in [
		{"label": "金币", "value": int(economy.get("gold", 0))},
		{"label": "招募券", "value": int(economy.get("recruit_ticket", economy.get("recruit_tickets", 0)))},
		{"label": "经验书", "value": int(economy.get("xp_book", economy.get("experience_books", 0)))},
		{"label": "锻造石", "value": int(economy.get("forge_stone", economy.get("forge_stones", 0)))},
	]:
		var label := Label.new()
		label.custom_minimum_size = Vector2(0, 74)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 21)
		label.add_theme_color_override("font_color", Color(0.91, 0.94, 0.98))
		label.text = "%s\n%s" % [str(spec.label), str(spec.value)]
		_resource_bar.add_child(label)


func _render_heroes(state: Dictionary) -> void:
	_clear_children(_formation_slots)
	_clear_children(_hero_rows)
	var heroes := _hero_list(state)
	var slots := _formation_slots_from_state(state, heroes)
	for slot: String in FormationReducerScript.SLOT_ORDER:
		var button := _make_button("%s\n%s" % [SLOT_NAMES[slot], _hero_short_name(slots.get(slot, ""))], 96)
		button.name = "Slot%s" % slot.capitalize()
		button.pressed.connect(_select_hero.bind(str(slots.get(slot, ""))))
		_formation_slots.add_child(button)
	for hero: Dictionary in heroes:
		var id := str(hero.get("id", ""))
		var row := _make_button(_hero_summary(hero), 104)
		row.name = "HeroRow%s" % id.right(2)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.disabled = id == _selected_hero_id
		row.pressed.connect(_select_hero.bind(id))
		_hero_rows.add_child(row)
	if _selected_hero_id.is_empty() and not heroes.is_empty():
		_selected_hero_id = str(heroes[0].get("id", ""))


func _render_forge(state: Dictionary) -> void:
	_clear_children(_forge_items)
	var drops := _preview_drops(state)
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.75, 0.84, 0.95))
	title.text = "掉落候选：%s" % ", ".join(drops)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_forge_items.add_child(title)
	var items: Dictionary = state.get("inventory", {}).get("items", {})
	if items.is_empty():
		_forge_items.add_child(_make_muted_label("背包暂无装备；通关结算接口当前只记录关卡结果，掉落入包尚未接通。"))
		return
	for item_id: String in items:
		var item: Dictionary = items[item_id]
		var row := _make_button(_item_summary(item), 96)
		row.name = "ItemRow%s" % item_id.right(4)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.disabled = item_id == _selected_item_id
		row.pressed.connect(_select_item.bind(item_id))
		_forge_items.add_child(row)
	if _selected_item_id.is_empty() and not items.is_empty():
		_selected_item_id = str(items.keys()[0])


func _render_camp(state: Dictionary) -> void:
	_clear_children(_camp_rows)
	var facilities: Dictionary = state.get("camp", {}).get("facilities", {})
	for facility_id: String in ["tavern", "blacksmith", "training_ground"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_camp_rows.add_child(row)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 23)
		var level := int(facilities.get(facility_id, {}).get("level", 1))
		label.text = "%s Lv.%d / 3" % [FACILITY_NAMES[facility_id], level]
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
		var upgrade := _make_button("升级", 88)
		upgrade.name = "Upgrade%sButton" % facility_id.capitalize()
		upgrade.pressed.connect(_on_upgrade_facility_pressed.bind(facility_id))
		row.add_child(upgrade)


func _render_quests(state: Dictionary) -> void:
	_clear_children(_quest_rows)
	var quests: Dictionary = state.get("quest", {}).get("quests", {})
	var shown := 0
	for quest_id: String in quests:
		if shown >= 10:
			break
		var quest: Dictionary = quests[quest_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_quest_rows.add_child(row)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 20)
		label.text = "%s · %s %d/%d%s" % [
			quest_id,
			str(quest.get("event_type", "")),
			int(quest.get("progress", 0)),
			int(quest.get("target", 1)),
			" · 已领取" if bool(quest.get("claimed", false)) else "",
		]
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
		var claim := _make_button("领取", 88)
		claim.name = "Claim%sButton" % quest_id.replace("-", "")
		claim.disabled = not bool(quest.get("terminal", false)) or bool(quest.get("claimed", false))
		claim.pressed.connect(_on_claim_pressed.bind(quest_id))
		row.add_child(claim)
		shown += 1


func _on_recruit_pressed() -> void:
	var state := _state()
	var roster: Dictionary = state.get("roster", {})
	var result := _execute_game_command(
		"recruit_hero",
		{
			"seed": int(state.get("run_seed", DEMO_RUN_SEED)),
			"index": roster.size(),
		},
		"recruit:%d" % (roster.size() + 1)
	)
	_report_command("招募", result)


func _on_train_pressed() -> void:
	if _selected_hero_id.is_empty():
		return
	var result := _execute_game_command(
		"train_hero",
		{"hero_id": _selected_hero_id, "xp_books": 1, "xp_amount": 40},
		"train:%s:%d" % [_selected_hero_id, _command_serial + 1]
	)
	_report_command("训练", result)


func _on_swap_formation_pressed() -> void:
	_execute_predeclared_intervention()


func _execute_predeclared_intervention() -> void:
	var state := _state()
	var heroes := _hero_list(state)
	if heroes.size() < 4:
		_toast.text = "需要至少 4 名已招募英雄才能提交编队。"
		return
	var slots := _formation_slots_from_state(state, heroes)
	var swapped := {
		"front_1": str(slots.get("front_2", "")),
		"front_2": str(slots.get("front_1", "")),
		"back_1": str(slots.get("back_1", "")),
		"back_2": str(slots.get("back_2", "")),
	}
	var result := _execute_game_command(
		"set_formation",
		{"slots": swapped},
		"formation:%s:%s" % [swapped.front_1, swapped.front_2]
	)
	if result.get("ok", false):
		_formation_adjusted = true
	_report_command("编队", result)


func _on_equip_pressed() -> void:
	if _selected_item_id.is_empty() or _selected_hero_id.is_empty():
		_toast.text = "需要选中英雄和装备。"
		return
	var result := _execute_game_command(
		"equip_item",
		{"hero_id": _selected_hero_id, "item_id": _selected_item_id},
		"equip:%s:%s" % [_selected_hero_id, _selected_item_id]
	)
	if result.get("ok", false):
		_equipment_adjusted = true
	_report_command("装备", result)


func _on_enhance_pressed() -> void:
	if _selected_item_id.is_empty():
		_toast.text = "需要先选中装备。"
		return
	var result := _execute_game_command(
		"enhance_item",
		{"item_id": _selected_item_id},
		"enhance:%s:%d" % [_selected_item_id, _command_serial + 1]
	)
	if result.get("ok", false):
		_equipment_adjusted = true
	_report_command("强化", result)


func _on_upgrade_facility_pressed(facility_id: String) -> void:
	var result := _execute_game_command(
		"upgrade_facility",
		{"facility_id": facility_id},
		"facility:%s:%d" % [facility_id, _command_serial + 1]
	)
	_report_command("设施升级", result)


func _on_claim_pressed(quest_id: String) -> void:
	var result := _execute_game_command(
		"claim_reward",
		{"quest_id": quest_id},
		"quest:%s:claim" % quest_id
	)
	_report_command("领奖", result)


func _select_hero(hero_id: String) -> void:
	_selected_hero_id = hero_id
	_render_heroes(_state())


func _select_item(item_id: String) -> void:
	_selected_item_id = item_id
	_render_forge(_state())


func _execute_game_command(command_type: String, payload: Dictionary, business_key: String) -> Dictionary:
	if _game == null or not _game.has_method("execute_command"):
		return {"ok": false, "code": "GAME_NOT_READY"}
	var state := _state()
	_command_serial += 1
	return _game.execute_command({
		"command_id": "%s:%d:%d" % [command_type, int(state.get("revision", 0)) + 1, _command_serial],
		"type": command_type,
		"payload": payload.duplicate(true),
		"business_key": business_key,
		"expected_revision": int(state.get("revision", 0)),
		"requested_at": int(Time.get_unix_time_from_system()),
	})


func _report_command(label: String, result: Dictionary) -> void:
	_toast.text = "%s成功" % label if result.get("ok", false) else "%s失败：%s" % [
		label, str(result.get("code", "UNKNOWN"))
	]
	_refresh_state()


func _state() -> Dictionary:
	if _game == null or not _game.has_method("get_state"):
		return {}
	var state: Dictionary = _game.get_state()
	return state if not state.is_empty() else {}


func _hero_list(state: Dictionary) -> Array[Dictionary]:
	var roster: Dictionary = state.get("roster", {})
	var heroes: Array[Dictionary] = []
	for hero_id: String in roster:
		heroes.append(roster[hero_id])
	if heroes.size() >= 8:
		return heroes
	var seed := int(state.get("run_seed", DEMO_RUN_SEED))
	var preview := HeroGenerator.generate_roster(seed, 8)
	var existing: Dictionary = {}
	for hero: Dictionary in heroes:
		existing[str(hero.get("id", ""))] = true
	for hero: Dictionary in preview:
		if heroes.size() >= 8:
			break
		if not existing.has(str(hero.get("id", ""))):
			heroes.append(hero)
	return heroes


func _formation_slots_from_state(state: Dictionary, heroes: Array[Dictionary]) -> Dictionary:
	var formation: Dictionary = state.get("formation", {})
	var slots: Dictionary = formation.get("slots", {})
	if slots.size() == FormationReducerScript.SLOT_ORDER.size():
		return slots
	var fallback := {}
	for index: int in FormationReducerScript.SLOT_ORDER.size():
		fallback[FormationReducerScript.SLOT_ORDER[index]] = (
			str(heroes[index].get("id", "")) if index < heroes.size() else ""
		)
	return fallback


func _hero_short_name(hero_id: String) -> String:
	for hero: Dictionary in _hero_list(_state()):
		if str(hero.get("id", "")) == hero_id:
			return "%s %s" % [
				str(CLASS_NAMES.get(hero.get("class_id", ""), "英雄")),
				str(hero.get("aptitude", ""))
			]
	return "空"


func _hero_summary(hero: Dictionary) -> String:
	var stats: Dictionary = hero.get("stats", {})
	return "%s · %s · Lv.%d · %s · V%d S%d A%d I%d" % [
		str(hero.get("name", "")),
		str(CLASS_NAMES.get(hero.get("class_id", ""), "英雄")),
		int(hero.get("level", 1)),
		"%s/%s" % [str(hero.get("aptitude", "")), str(TRAIT_NAMES.get(hero.get("trait", ""), hero.get("trait", "")))],
		int(stats.get("vig", 0)),
		int(stats.get("str", 0)),
		int(stats.get("agi", 0)),
		int(stats.get("int", 0)),
	]


func _preview_drops(state: Dictionary) -> Array[String]:
	var seed := int(state.get("run_seed", DEMO_RUN_SEED))
	var item_a := LootGenerator.create_item(seed, 1, "guardian_blade", "blue", ["vitality"])
	var item_b := LootGenerator.create_item(seed, 2, "ranger_bow", "green", ["haste"])
	var item_c := LootGenerator.create_item(seed, 3, "arcanist_staff", "purple", ["focus"])
	return [_item_summary(item_a), _item_summary(item_b), _item_summary(item_c)]


func _item_summary(item: Dictionary) -> String:
	return "%s · %s · +%d · %s" % [
		str(item.get("quality", "")),
		str(item.get("template_id", "")),
		int(item.get("enhancement", 0)),
		",".join(item.get("affix_ids", [])),
	]


func _make_button(text: String, height: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 22)
	return button


func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.94, 0.82, 0.48))
	return label


func _make_muted_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.7, 0.78, 0.88))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child: Node in node.get_children():
		node.remove_child(child)
		child.free()


func _format_duration(total_seconds: int) -> String:
	var clamped := maxi(total_seconds, 0)
	var hours := floori(float(clamped) / 3600.0)
	var minutes := floori(float(clamped % 3600) / 60.0)
	var seconds := clamped % 60
	return "%d小时 %d分 %d秒" % [hours, minutes, seconds]
