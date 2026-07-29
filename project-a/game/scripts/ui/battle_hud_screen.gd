class_name BattleHudScreen
extends Control

signal pause_requested
signal skill_mode_requested
signal burst_requested
signal retreat_requested
signal skill_requested(unit_id: String)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const UiArtDirectionScript := preload("res://game/scripts/ui/ui_art_direction.gd")
const ICON_PAUSE := preload("res://assets/ui/icons/kenney_game_icons/pause.png")
const ICON_TARGET := preload("res://assets/ui/icons/kenney_game_icons/target.png")
const ICON_RETREAT := preload("res://assets/ui/icons/kenney_game_icons/exit_right.png")
const PANEL := Color("#0b1117e8")
const PANEL_2 := Color("#111a21")
const LINE := Color("#42525d")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const RED := Color("#d95c4f")
const GREEN := Color("#78b982")

@onready var status_label: Label = %BattleTacticalStatus
@onready var pause_button: Button = %BattlePauseButton
@onready var skill_mode_button: Button = %BattleSkillModeButton
@onready var burst_button: Button = %BattleBurstButton
@onready var retreat_button: Button = %BattleRetreatButton
@onready var skill_grid: GridContainer = %BattleSkillGrid

var _manual_skills := false
var _warning_tactic := "点亮技能集中爆发"
var _first_skill_tutorial := false
var _first_skill_confirmed := false
var _skill_confirmation_updates := 0
var _skill_feedback_updates := 0
var _skill_feedback_copy := ""
var _skill_feedback_queue: Array[String] = []
var _skill_unavailable_updates := 0
var _reinforcement_rally_updates := 0
var _chapter_feedback_updates := 0
var _chapter_feedback_copy := ""
var _chapter_feedback_danger := false
var _unit_hud: Dictionary = {}
var _skill_buttons: Dictionary = {}


func _ready() -> void:
	_apply_theme()
	pause_button.pressed.connect(pause_requested.emit)
	skill_mode_button.pressed.connect(skill_mode_requested.emit)
	burst_button.pressed.connect(burst_requested.emit)
	retreat_button.pressed.connect(retreat_requested.emit)


func configure(
	snapshots: Array[Dictionary],
	manual_skills: bool,
	first_skill_tutorial: bool = false,
	reinforcement_rally: bool = false,
	compact: bool = false
) -> void:
	status_label.add_theme_font_size_override("font_size", 18 if compact else 16)
	for action in [pause_button, skill_mode_button, burst_button, retreat_button]:
		action.add_theme_font_size_override("font_size", 16 if compact else 14)
	_manual_skills = manual_skills
	_first_skill_tutorial = first_skill_tutorial
	_first_skill_confirmed = false
	_skill_confirmation_updates = 0
	_skill_feedback_updates = 0
	_skill_feedback_copy = ""
	_skill_feedback_queue.clear()
	_skill_unavailable_updates = 0
	_reinforcement_rally_updates = 10 if reinforcement_rally else 0
	_chapter_feedback_updates = 0
	_chapter_feedback_copy = ""
	_chapter_feedback_danger = false
	_warning_tactic = _warning_tactic_for(snapshots)
	skill_mode_button.text = "手动技能" if _manual_skills else "自动技能"
	burst_button.visible = _manual_skills
	burst_button.disabled = not _manual_skills
	burst_button.tooltip_text = "下达全队爆发指令；接下来 2 秒内就绪的技能会立即释放"
	skill_grid.columns = maxi(1, snapshots.size())
	_clear_units()
	for snapshot in snapshots:
		var card := _build_unit_card(snapshot)
		var unit_id := String(snapshot.get("hero_id", ""))
		_skill_buttons[unit_id] = card["button"]
		_unit_hud[unit_id] = card
		skill_grid.add_child(card["root"])


func set_manual_skills(enabled: bool) -> void:
	_manual_skills = enabled
	skill_mode_button.text = "手动技能" if enabled else "自动技能"
	burst_button.visible = enabled
	burst_button.disabled = not enabled


func confirm_skill_requested() -> void:
	if not _first_skill_tutorial or _first_skill_confirmed:
		return
	_first_skill_confirmed = true
	_skill_confirmation_updates = 5


func show_skill_unavailable() -> void:
	_skill_unavailable_updates = 3


func apply_battle_events(events: Array[Dictionary]) -> void:
	for event in events:
		var event_type := StringName(event.get("type", &""))
		if event_type == &"skill_used":
			var copy := _skill_result_copy(String(event.get("unit_id", "")), events)
			if not copy.is_empty():
				_skill_feedback_queue.append(copy)
		elif event_type == &"faction_protocol":
			var effect_id := String(event.get("effect_id", ""))
			var tier := int(event.get("tier", 1))
			var detail := ""
			match effect_id:
				"opening_energy":
					detail = "%d名主力获得开局能量，核心成员最高+%d" % [
						int(event.get("affected", 0)),
						int(event.get("value", 0)),
					]
				"opening_shield":
					detail = "%d名主力获得开局护盾，核心成员护盾更厚" % int(event.get("affected", 0))
				"opening_armor_break":
					detail = "%d座结构已标定，覆盖%d个战区，承伤+%d%%" % [
						int(event.get("affected", 0)),
						int(event.get("zone_count", 1)),
						int(event.get("armor_break_bp", 2500)) / 100,
					]
				"opening_weakness":
					detail = "%d名守军虚弱%d秒，覆盖%d个战区" % [
						int(event.get("affected", 0)),
						int(event.get("duration_ticks", 50)) / 5,
						int(event.get("zone_count", 1)),
					]
				_:
					detail = "阵营效果已生效"
			_chapter_feedback_copy = "%s · %d阶「%s」：%s" % [
				String(event.get("faction", "阵营")),
				tier,
				String(event.get("title", "阵营科技")),
				detail,
			]
			_chapter_feedback_updates = 12
			_chapter_feedback_danger = false
		elif event_type == &"resonance_warning":
			_chapter_feedback_copy = (
				"共振蓄能 · 2秒后削减全队能量 · 立即释放已就绪技能"
				if _manual_skills
				else "共振蓄能 · 2秒后削减全队能量 · 可切手动抢先释放"
			)
			_chapter_feedback_updates = 10
			_chapter_feedback_danger = false
		elif event_type == &"resonance_pulse":
			_chapter_feedback_copy = "共振冲击 · 全队损失 %d 能量 · 技能节奏被拖慢" % int(
				event.get("energy_drained", 0)
			)
			_chapter_feedback_updates = 6
			_chapter_feedback_danger = true
		elif event_type == &"speaker_reinforcement":
			_chapter_feedback_copy = "广播车增援 · 第%d/%d波进入战场 · 立即集火新增目标" % [
				int(event.get("wave", 1)),
				int(event.get("wave_limit", 1)),
			]
			_chapter_feedback_updates = 8
			_chapter_feedback_danger = false
		elif event_type == &"speaker_echo_warning":
			_chapter_feedback_copy = "双塔回响蓄能 · 2秒后冲击%s · 检查护盾与治疗" % (
				"前排" if String(event.get("rank", "front")) == "front" else "后排"
			)
			_chapter_feedback_updates = 10
			_chapter_feedback_danger = false
		elif event_type == &"speaker_echo_impact":
			_chapter_feedback_copy = "双塔回响 · %s承受 %d 伤害 · 下一次将切换排位" % [
				"前排" if String(event.get("rank", "front")) == "front" else "后排",
				int(event.get("damage", 0)),
			]
			_chapter_feedback_updates = 6
			_chapter_feedback_danger = true
		elif event_type == &"tv_signal_vanish":
			_chapter_feedback_copy = "目标信号消失 · %0.1f秒后复现 · 先转火场上目标" % (
				float(int(event.get("duration_ticks", 10))) / 5.0
			)
			_chapter_feedback_updates = 10
			_chapter_feedback_danger = false
		elif event_type == &"tv_signal_return":
			_chapter_feedback_copy = "目标信号复现 · 已重新进入战场 · 评估距离后再决定是否切回"
			_chapter_feedback_updates = 8
			_chapter_feedback_danger = false
		elif event_type == &"tv_teleport":
			_chapter_feedback_copy = "电视人精英换位 · 已切换战斗带与路线 · 重新确认集火目标"
			_chapter_feedback_updates = 8
			_chapter_feedback_danger = false
		elif event_type == &"screen_control":
			_chapter_feedback_copy = "屏幕控制 · %s停火 %0.1f秒 · 其余成员继续推进" % [
				_unit_display_name(String(event.get("unit_id", ""))),
				float(int(event.get("duration_ticks", 8))) / 5.0,
			]
			_chapter_feedback_updates = 8
			_chapter_feedback_danger = true
		elif event_type == &"tv_overseer_shield":
			_chapter_feedback_copy = "监军护盾 · %d名精英获得 %d 护盾 · 集中爆发击穿" % [
				int(event.get("shielded", 0)),
				int(event.get("amount", 0)),
			]
			_chapter_feedback_updates = 8
			_chapter_feedback_danger = false
		elif event_type == &"alliance_mark":
			_chapter_feedback_copy = "联合标记 · %s被锁定 %0.1f秒 · 开盾或治疗分担集火" % [
				_unit_display_name(String(event.get("unit_id", ""))),
				float(int(event.get("duration_ticks", 15))) / 5.0,
			]
			_chapter_feedback_updates = 10
			_chapter_feedback_danger = true
		elif event_type == &"alliance_anti_air":
			if bool(event.get("locked", false)):
				_chapter_feedback_copy = "防空锁定 · %s停火 %0.1f秒 · 地面成员继续拆塔" % [
					_unit_display_name(String(event.get("unit_id", ""))),
					float(int(event.get("duration_ticks", 5))) / 5.0,
				]
				_chapter_feedback_danger = true
			else:
				_chapter_feedback_copy = "防空扫描 · 当前无飞行单位 · 地面编队成功规避"
				_chapter_feedback_danger = false
			_chapter_feedback_updates = 8
		elif event_type == &"alliance_purge":
			var purged := int(event.get("purged", 0))
			if purged > 0:
				_chapter_feedback_copy = "净化脉冲 · %d个临时单位承受 %d 伤害 · 保护永久主队" % [
					purged,
					int(event.get("damage", 0)),
				]
				_chapter_feedback_danger = true
			else:
				_chapter_feedback_copy = "净化脉冲 · 当前无召唤物 · 主队不受影响"
				_chapter_feedback_danger = false
			_chapter_feedback_updates = 8
		elif event_type == &"alliance_coordination":
			_chapter_feedback_copy = "联合护盾 · %d名精英获得 %d 护盾 · 集中火力逐个击穿" % [
				int(event.get("shielded", 0)),
				int(event.get("amount", 28)),
			]
			_chapter_feedback_updates = 8
			_chapter_feedback_danger = false
		elif event_type == &"finale_warning":
			var is_titan := String(event.get("kind", "")) == "titan"
			_chapter_feedback_copy = (
				"泰坦足迹余波 · 2秒后冲击%d号战线 · 这是环境威胁，不可锁定"
				if is_titan
				else "空城诱敌炮击 · 2秒后覆盖%d号战线 · 保留护盾与治疗"
			) % (int(event.get("lane", 0)) + 1)
			_chapter_feedback_updates = 10
			_chapter_feedback_danger = false
		elif event_type == &"finale_impact":
			_chapter_feedback_copy = "%s · 命中%d名成员，造成%d伤害" % [
				"泰坦余波" if String(event.get("kind", "")) == "titan" else "诱敌炮击",
				int(event.get("affected", 0)),
				int(event.get("damage", 0)),
			]
			_chapter_feedback_updates = 7
			_chapter_feedback_danger = true
		elif event_type == &"finale_armor":
			_chapter_feedback_copy = "仓库诱饵装甲 · %d名精英获得%d护盾 · 集中破甲，不追逐战利品信号" % [
				int(event.get("shielded", 0)),
				int(event.get("amount", 0)),
			]
			_chapter_feedback_updates = 8
			_chapter_feedback_danger = false
		elif event_type == &"finale_support":
			_chapter_feedback_copy = "剧情支援 · Gman命中当前目标，造成%d伤害 · 抓住窗口推进" % int(
				event.get("damage", 0)
			)
			_chapter_feedback_updates = 10
			_chapter_feedback_danger = false
	if not _skill_feedback_queue.is_empty():
		_skill_confirmation_updates = 0
	_start_next_skill_feedback()


func skill_buttons() -> Dictionary:
	return _skill_buttons.duplicate()


func apply_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	var objective_copy := _objective_copy(snapshot)
	var warnings := snapshot.get("warnings", []) as Array
	var warning_copy := ""
	var warning_suppressed := false
	if not warnings.is_empty():
		var warning := warnings[0] as Dictionary
		warning_suppressed = bool(warning.get("suppressed", false))
		if warning_suppressed:
			warning_copy = " · 巨炮已压制 · 安全窗口"
		else:
			warning_copy = " · 炮击 %0.1f秒 · %s" % [
				float(warning.get("remaining_ticks", 0)) / 5.0,
				_warning_tactic,
			]
	var battle_status := "阶段 %d/%d · %s · 战线 %d%%%s" % [
		int(snapshot.get("stage_index", 0)) + 1,
		int(snapshot.get("stage_count", 3)),
		objective_copy if not objective_copy.is_empty() else String(snapshot.get("stage_name", "推进中")),
		clampi(int(snapshot.get("road_progress", 0)) / 10, 0, 100),
		warning_copy,
	]
	var ready_unit_name := ""
	var ready_count := 0
	for unit_value in snapshot.get("units", []):
		var unit := unit_value as Dictionary
		if bool(unit.get("temporary", false)):
			continue
		_apply_unit_snapshot(unit)
		if (
			_manual_skills
			and bool(unit.get("alive", false))
			and int(unit.get("energy", 0)) >= 100
		):
			ready_count += 1
			if ready_unit_name.is_empty():
				ready_unit_name = _unit_display_name(String(unit.get("unit_id", "")))
	var burst_remaining := int(snapshot.get("burst_window_remaining_ticks", 0))
	burst_button.visible = _manual_skills
	burst_button.disabled = not _manual_skills or burst_remaining > 0
	if burst_remaining > 0:
		burst_button.text = "爆发 %0.1f秒" % (float(burst_remaining) / 5.0)
	elif ready_count > 0:
		burst_button.text = "全队爆发 ×%d" % ready_count
	else:
		burst_button.text = "全队蓄势"
	_apply_burst_emphasis(
		_manual_skills
			and not warnings.is_empty()
			and not warning_suppressed
			and burst_remaining <= 0
	)
	status_label.text = battle_status
	status_label.add_theme_color_override(
		"font_color",
		GREEN if warning_suppressed else (RED if not warnings.is_empty() else GOLD)
	)
	if not warnings.is_empty():
		return
	if _chapter_feedback_updates > 0:
		status_label.text = _chapter_feedback_copy
		status_label.add_theme_color_override(
			"font_color",
			RED if _chapter_feedback_danger else GOLD
		)
		_chapter_feedback_updates -= 1
		if _chapter_feedback_updates == 0:
			_chapter_feedback_copy = ""
			_chapter_feedback_danger = false
	elif _skill_unavailable_updates > 0:
		status_label.text = "技能尚未就绪 · 等待能量充满"
		status_label.add_theme_color_override("font_color", MUTED)
		_skill_unavailable_updates -= 1
	elif _skill_feedback_updates > 0:
		status_label.text = _skill_feedback_copy
		status_label.add_theme_color_override("font_color", GREEN)
		_skill_feedback_updates -= 1
		if _skill_feedback_updates == 0:
			_skill_feedback_copy = ""
			_start_next_skill_feedback()
	elif _skill_confirmation_updates > 0:
		status_label.text = "指令生效 · %s 正在释放主动技能" % ready_unit_name if not ready_unit_name.is_empty() else "指令生效 · 主动技能正在释放"
		status_label.add_theme_color_override("font_color", GREEN)
		_skill_confirmation_updates -= 1
	elif _reinforcement_rally_updates > 0:
		status_label.text = "援军已就位 · 装甲前排承伤，冲锋快速压制"
		status_label.add_theme_color_override("font_color", CYAN)
		_reinforcement_rally_updates -= 1
	elif (
		_first_skill_tutorial
		and not _first_skill_confirmed
		and _manual_skills
		and not ready_unit_name.is_empty()
	):
		status_label.text = "%s · 首次反攻强化 · 点击发光的 %s 卡释放" % [
			objective_copy if not objective_copy.is_empty() else "继续推进",
			ready_unit_name,
		]
		status_label.add_theme_color_override("font_color", GOLD)


func _skill_result_copy(unit_id: String, events: Array[Dictionary]) -> String:
	var hud := _unit_hud.get(unit_id, {}) as Dictionary
	var hero_name := String(hud.get("display_name", "主力"))
	var skill_name := String(hud.get("skill_display_name", "主动技能"))
	var damage := 0
	var healed := 0
	var shielded := 0
	var shielded_units := 0
	var revived := 0
	var weakened := 0
	var stunned := 0
	var summoned := 0
	var converted := 0
	var armor_broken := 0
	for event in events:
		var event_type := StringName(event.get("type", &""))
		var source_id := String(event.get("source_id", ""))
		if (
			event_type in [&"enemy_damaged", &"structure_damaged"]
			and bool(event.get("is_skill", false))
			and source_id == unit_id
		):
			damage += maxi(0, int(event.get("effective_damage", event.get("damage", 0))))
		elif event_type == &"unit_healed" and source_id == unit_id:
			healed += maxi(0, int(event.get("heal", 0)))
		elif event_type == &"unit_shielded" and source_id == unit_id:
			shielded += maxi(0, int(event.get("shield", 0)))
			shielded_units += 1
		elif event_type == &"unit_revived" and source_id == unit_id:
			revived += 1
		elif event_type == &"enemy_weakened" and source_id == unit_id:
			weakened += 1
		elif event_type == &"enemy_stunned" and source_id == unit_id:
			stunned += 1
		elif event_type == &"structure_armor_broken" and source_id == unit_id:
			armor_broken += 1
		elif event_type == &"unit_summoned" and String(event.get("owner_id", "")) == unit_id:
			summoned += 1
		elif event_type == &"unit_converted" and String(event.get("owner_id", "")) == unit_id:
			converted += 1
	var results: Array[String] = []
	if damage > 0:
		results.append("造成 %d 伤害" % damage)
	if shielded > 0:
		results.append("为 %d 人提供 %d 护盾" % [shielded_units, shielded])
	if healed > 0:
		results.append("修复 %d 生命" % healed)
	if revived > 0:
		results.append("救回 %d 名主力" % revived)
	if weakened > 0:
		results.append("削弱 %d 名守军" % weakened)
	if stunned > 0:
		results.append("压制 %d 名守军" % stunned)
	if armor_broken > 0:
		results.append("击破结构护甲")
	if summoned > 0:
		results.append("召唤 %d 名幼体" % summoned)
	if converted > 0:
		results.append("策反 %d 名守军" % converted)
	if results.is_empty():
		results.append("技能生效")
	return "%s · %s：%s" % [hero_name, skill_name, " · ".join(results)]


func _start_next_skill_feedback() -> void:
	if _skill_feedback_updates > 0 or _skill_feedback_queue.is_empty():
		return
	_skill_feedback_copy = _skill_feedback_queue.pop_front()
	_skill_feedback_updates = 5


func _objective_copy(snapshot: Dictionary) -> String:
	var stage_index := int(snapshot.get("stage_index", 0))
	for structure_value in snapshot.get("structures", []):
		var structure := structure_value as Dictionary
		if int(structure.get("stage", -1)) != stage_index or not bool(structure.get("alive", false)):
			continue
		var max_hp := maxi(1, int(structure.get("max_hp", 1)))
		var durability := clampi(
			ceili(float(maxi(0, int(structure.get("hp", 0)))) * 100.0 / float(max_hp)),
			0,
			100
		)
		var verb := "摧毁" if String(structure.get("kind", "")) in ["city", "core"] else "突破"
		return "%s%s · 耐久 %d%%" % [
			verb,
			String(structure.get("display_name", "防御结构")),
			durability,
		]
	return ""


func _warning_tactic_for(snapshots: Array[Dictionary]) -> String:
	for snapshot in snapshots:
		if String(snapshot.get("skill_id", "")) == "siege_shield" and int(snapshot.get("star", 1)) >= 2:
			return "点装甲护盾扛炮"
	for snapshot in snapshots:
		if String(snapshot.get("skill_id", "")) == "assault_rush":
			return "点冲锋技能打断"
	return "点亮技能集中爆发"


func _apply_unit_snapshot(unit: Dictionary) -> void:
	var unit_id := String(unit.get("unit_id", ""))
	var button := _skill_buttons.get(unit_id) as Button
	if button == null:
		return
	var hud := _unit_hud.get(unit_id, {}) as Dictionary
	var energy := clampi(int(unit.get("energy", 0)), 0, 100)
	var hp := maxi(0, int(unit.get("hp", 0)))
	var max_hp := maxi(1, int(unit.get("max_hp", 1)))
	var alive := bool(unit.get("alive", false))
	button.disabled = not _manual_skills or not alive or energy < 100
	var hp_bar := hud.get("hp_bar") as ProgressBar
	var energy_bar := hud.get("energy_bar") as ProgressBar
	var hp_label := hud.get("hp_label") as Label
	var energy_label := hud.get("energy_label") as Label
	var state_label := hud.get("state_label") as Label
	var root := hud.get("root") as PanelContainer
	root.add_theme_stylebox_override("panel", _unit_card_style(false))
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	_set_progress_fill(hp_bar, GREEN if hp * 3 > max_hp else RED)
	energy_bar.value = energy
	_set_progress_fill(energy_bar, GOLD if energy >= 100 else CYAN)
	hp_label.text = "%d/%d" % [hp, max_hp]
	energy_label.text = "%d%%" % energy
	if not alive:
		state_label.text = "阵亡"
		state_label.add_theme_color_override("font_color", RED)
	elif energy >= 100:
		var tutorial_ready := _first_skill_tutorial and not _first_skill_confirmed and _manual_skills
		state_label.text = "点击整张卡" if tutorial_ready else ("技能就绪" if _manual_skills else "自动释放")
		state_label.add_theme_color_override("font_color", GOLD)
		if tutorial_ready:
			root.add_theme_stylebox_override("panel", _unit_card_style(true))
	else:
		state_label.text = "充能中"
		state_label.add_theme_color_override("font_color", MUTED)


func _build_unit_card(snapshot: Dictionary) -> Dictionary:
	var unit_id := String(snapshot.get("hero_id", ""))
	var root := PanelContainer.new()
	root.name = "BattleUnitCard_%s" % unit_id
	root.custom_minimum_size = Vector2(108, 68)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_stylebox_override("panel", _unit_card_style(false))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	root.add_child(stack)
	var header := HBoxContainer.new()
	var name_label := _label("%s · %s" % [
		String(snapshot.get("display_name", unit_id)),
		String(snapshot.get("skill_display_name", "主动技能")),
	], 12, TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(name_label)
	var state_label := _label("充能中", 10, MUTED)
	state_label.name = "BattleUnitStateLabel"
	state_label.custom_minimum_size.x = 52
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(state_label)
	stack.add_child(header)
	var hp := _meter_row("HP", GREEN, int(snapshot.get("max_hp", 1)), int(snapshot.get("max_hp", 1)))
	stack.add_child(hp["root"])
	var energy := _meter_row("EN", CYAN, 0, 100)
	stack.add_child(energy["root"])
	var skill := Button.new()
	skill.name = "BattleSkillButton_%s" % unit_id
	skill.flat = true
	skill.focus_mode = Control.FOCUS_ALL
	skill.custom_minimum_size.y = 64
	skill.tooltip_text = "%s\n%s" % [
		String(snapshot.get("skill_display_name", "主动技能")),
		String(snapshot.get("skill_timing", "能量达到 100% 后释放")),
	]
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled"]:
		skill.add_theme_stylebox_override(state, empty_style)
	skill.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), 6, Color.WHITE))
	skill.pressed.connect(skill_requested.emit.bind(unit_id))
	root.add_child(skill)
	skill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return {
		"root": root,
		"button": skill,
		"display_name": String(snapshot.get("display_name", unit_id)),
		"skill_display_name": String(snapshot.get("skill_display_name", "主动技能")),
		"hp_bar": hp["bar"],
		"energy_bar": energy["bar"],
		"hp_label": hp["value"],
		"energy_label": energy["value"],
		"state_label": state_label,
	}


func _unit_display_name(unit_id: String) -> String:
	var hud := _unit_hud.get(unit_id, {}) as Dictionary
	return String(hud.get("display_name", unit_id))


func _unit_card_style(highlighted: bool) -> StyleBoxFlat:
	var style := _box(
		Color(PANEL_2, 0.9),
		5,
		GOLD if highlighted else Color(0, 0, 0, 0)
	)
	if highlighted:
		style.set_border_width_all(2)
	else:
		style.set_border_width_all(0)
	return style


func _meter_row(tag_text: String, color: Color, value: int, maximum: int) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var tag := _label(tag_text, 9, color)
	tag.custom_minimum_size.x = 18
	row.add_child(tag)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = maxi(1, maximum)
	bar.value = value
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_progress_fill(bar, color)
	row.add_child(bar)
	var value_label := _label("%d%s" % [value, "%" if tag_text == "EN" else "/%d" % maximum], 9, color)
	value_label.custom_minimum_size.x = 42
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	return {"root": row, "bar": bar, "value": value_label}


func _apply_theme() -> void:
	var bottom_style := _box(Color(PANEL, 0.82), 10, Color(CYAN, 0.24))
	bottom_style.set_border_width_all(1)
	%BattleBottomHud.add_theme_stylebox_override("panel", bottom_style)
	var tactical_style := _box(Color(PANEL, 0.76), 10, Color(CYAN, 0.22))
	tactical_style.set_border_width_all(1)
	$TacticalBar.add_theme_stylebox_override("panel", tactical_style)
	var status_style := _box(Color("#071018e6"), 7, Color(0, 0, 0, 0))
	status_style.set_border_width_all(0)
	status_label.add_theme_stylebox_override("normal", status_style)
	pause_button.icon = ICON_PAUSE
	skill_mode_button.icon = ICON_TARGET
	retreat_button.icon = ICON_RETREAT
	for label: Label in [status_label]:
		label.add_theme_font_override("font", CJK_FONT)
	for button: Button in [pause_button, skill_mode_button, burst_button, retreat_button]:
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_constant_override("icon_max_width", 18)
		button.add_theme_font_override("font", CJK_FONT)
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_stylebox_override("normal", UiArtDirectionScript.button_style(false))
		button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(false, "hover"))
		button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(false, "pressed"))
		button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(false, "focus"))
	_apply_burst_emphasis(false)


func _apply_burst_emphasis(emphasized: bool) -> void:
	var normal_color := Color("#3b2a16") if emphasized else Color("#1a2228")
	var hover_color := Color("#51391a") if emphasized else Color("#24333a")
	var border_color := GOLD if emphasized else LINE
	burst_button.add_theme_color_override("font_color", GOLD if emphasized else TEXT)
	burst_button.add_theme_stylebox_override("normal", _box(normal_color, 7, border_color))
	burst_button.add_theme_stylebox_override("hover", _box(hover_color, 7, GOLD if emphasized else CYAN))
	burst_button.add_theme_stylebox_override("pressed", _box(Color("#55401f"), 7, GOLD))


func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", CJK_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _set_progress_fill(bar: ProgressBar, color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#252f36")
	background.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", background)


func _box(color: Color, radius: int, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _clear_units() -> void:
	_skill_buttons.clear()
	_unit_hud.clear()
	for child in skill_grid.get_children():
		child.queue_free()
