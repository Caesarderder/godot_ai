class_name HelpScreen
extends VBoxContainer

signal back_requested

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const UiArtDirectionScript := preload("res://game/scripts/ui/ui_art_direction.gd")
const PANEL := Color("#12171c")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const GREEN := Color("#78b982")

const TOPICS := {
	"now": {
		"eyebrow": "行动导航",
		"heading": "先看行动页，不用猜下一步",
		"summary": "行动页把大目标、中目标、小目标、当前卡点和唯一推荐行动放在同一屏。",
		"steps": "① 看青色中目标\n② 找金色主按钮\n③ 完成后回到世界继续推进",
		"tip": "提示 · 它只给方向，不会替你自动推图。",
	},
	"recovery": {
		"eyebrow": "无损恢复",
		"heading": "卡关不是惩罚，先查缺口",
		"summary": "失败后角色完全恢复，不会阵亡或等待维修。首次攻克 1-2、1-3 可获得冲锋与装甲图纸。",
		"steps": "① 回工厂收取后勤\n② 在研究所逐张研发图纸；信号招募后续开放\n③ 前排承伤、后排保护输出，再次攻城",
		"tip": "路线 · 冲锋二星偏突破，装甲二星偏稳定承伤。",
	},
	"controls": {
		"eyebrow": "操作速查",
		"heading": "战斗自动推进，关键时机由你决定",
		"summary": "军团自动移动和普攻；能量达到 100% 后可手动释放技能，也可开启自动技能。",
		"steps": "战斗 · 点亮的角色技能可释放\n建造 · 选择建筑 → 选择亮起地格 → 确认\n资源 · 只有确认建造后才会扣除",
		"tip": "提示 · 暂停菜单可切换自动技能和退出战斗。",
	},
	"data": {
		"eyebrow": "本地数据",
		"heading": "存档只留在当前浏览器",
		"summary": "不使用分析 SDK、遥测接口或 Cookie；试玩报告默认关闭且不会联网。",
		"steps": "备份 · 在设置中下载 JSON\n恢复 · 选择备份并先校验\n清理 · 删除前会要求再次确认",
		"tip": "version",
	},
}

@onready var back_button: Button = %HelpBackButton
@onready var detail_eyebrow: Label = %HelpDetailEyebrow
@onready var detail_heading: Label = %HelpDetailHeading
@onready var detail_summary: Label = %HelpDetailSummary
@onready var detail_steps: Label = %HelpDetailSteps
@onready var detail_tip: Label = %HelpDetailTip
@onready var topic_buttons := {
	"now": %HelpNowTab,
	"recovery": %HelpRecoveryTab,
	"controls": %HelpControlsTab,
	"data": %HelpDataTab,
}

var _view: Dictionary = {}
var _active_topic := "now"


func _ready() -> void:
	for topic_id in topic_buttons:
		(topic_buttons[topic_id] as Button).pressed.connect(_select_topic.bind(topic_id))
	back_button.pressed.connect(back_requested.emit)
	_apply_theme()
	_select_topic(_active_topic)
	_focus_primary_after_layout()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_select_topic(_active_topic)


func _select_topic(topic_id: String) -> void:
	_active_topic = topic_id if TOPICS.has(topic_id) else "now"
	var topic := TOPICS[_active_topic] as Dictionary
	detail_eyebrow.text = String(topic["eyebrow"])
	detail_heading.text = String(topic["heading"])
	detail_summary.text = String(topic["summary"])
	detail_steps.text = String(topic["steps"])
	detail_tip.text = (
		"版本 %s · Godot 4.6.3 Compatibility / WebGL2 · 非官方学习项目"
		% String(_view.get("version", "dev"))
		if String(topic["tip"]) == "version"
		else String(topic["tip"])
	)
	for id in topic_buttons:
		_style_topic_button(topic_buttons[id] as Button, id == _active_topic)


func _focus_primary_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree():
		(topic_buttons[_active_topic] as Button).grab_focus()


func _apply_theme() -> void:
	for panel_node in find_children("*", "PanelContainer", true, false):
		(panel_node as PanelContainer).add_theme_stylebox_override(
			"panel",
			UiArtDirectionScript.panel_style()
		)
	for label_node in find_children("*", "Label", true, false):
		var label := label_node as Label
		label.add_theme_font_override("font", CJK_FONT)
		label.add_theme_color_override("font_color", TEXT)
	%HelpDetailEyebrow.add_theme_font_size_override("font_size", 12)
	%HelpDetailEyebrow.add_theme_color_override("font_color", CYAN)
	%HelpDetailHeading.add_theme_font_size_override("font_size", 21)
	%HelpDetailHeading.add_theme_color_override("font_color", GOLD)
	%HelpDetailSummary.add_theme_font_size_override("font_size", 14)
	%HelpDetailSteps.add_theme_font_size_override("font_size", 14)
	%HelpDetailSteps.add_theme_color_override("font_color", GREEN)
	%HelpDetailTip.add_theme_font_size_override("font_size", 12)
	%HelpDetailTip.add_theme_color_override("font_color", MUTED)
	_style_action_button(back_button)


func _style_topic_button(button: Button, active: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", UiArtDirectionScript.button_style(active))
	button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(active, "hover"))
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(active, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(active, "focus"))
	button.add_theme_color_override("font_color", PANEL if active else TEXT)
	button.add_theme_color_override("font_hover_color", PANEL if active else TEXT)
	button.add_theme_color_override("font_pressed_color", PANEL if active else TEXT)


func _style_action_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", UiArtDirectionScript.button_style(false))
	button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(false, "hover"))
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(false, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(false, "focus"))
	button.add_theme_color_override("font_color", TEXT)
