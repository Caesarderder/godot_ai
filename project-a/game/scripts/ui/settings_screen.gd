class_name SettingsScreen
extends VBoxContainer

signal setting_changed(setting_id: String, value: Variant)
signal action_requested(action_id: String)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const BG := Color("#090d10")
const PANEL := Color("#12171c")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const GREEN := Color("#78b982")

@onready var experience_panel: PanelContainer = %SettingsExperiencePanel
@onready var data_panel: PanelContainer = %SettingsDataPanel
@onready var volume: HSlider = %SettingsMasterVolumeSlider
@onready var volume_value: Label = %SettingsMasterVolumeValue
@onready var quality: OptionButton = %SettingsEffectsQualityOption
@onready var reduced_motion: CheckButton = %SettingsReducedMotionToggle
@onready var global_auto_skill: CheckButton = %SettingsGlobalAutoSkillToggle
@onready var local_playtest: CheckButton = %SettingsLocalPlaytestToggle
@onready var playtest_status: Label = %SettingsPlaytestStatus
@onready var playtest_actions: HBoxContainer = %SettingsPlaytestActions
@onready var persistence_status: Label = %SettingsPersistenceStatus
@onready var import_button: Button = %SettingsImportSaveButton
@onready var import_preview: Label = %SettingsImportPreview
@onready var delete_button: Button = %SettingsDeleteLocalSaveButton
@onready var save_button: Button = %SettingsSaveButton

var _view: Dictionary = {}
var _projecting := false


func _ready() -> void:
	_apply_theme()
	volume.value_changed.connect(_on_volume_changed)
	quality.item_selected.connect(_on_quality_selected)
	reduced_motion.toggled.connect(_emit_setting.bind("reduced_motion"))
	global_auto_skill.toggled.connect(_emit_setting.bind("global_auto_skill"))
	local_playtest.toggled.connect(_emit_setting.bind("local_playtest_logging"))
	_bind_action(%SettingsHelpButton, "help")
	_bind_action(%SettingsExportPlaytestButton, "export_playtest")
	_bind_action(%SettingsClearPlaytestButton, "clear_playtest")
	_bind_action(%SettingsExportSaveButton, "export_save")
	_bind_action(import_button, "import_save")
	_bind_action(delete_button, "delete_save")
	_bind_action(save_button, "save")
	_bind_action(%SettingsBackButton, "back")
	if not _view.is_empty():
		_apply_view()
	_focus_primary_after_layout()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_apply_view()


func _apply_view() -> void:
	_projecting = true
	volume.value = clampf(float(_view.get("master_volume", 80)), 0.0, 100.0)
	volume_value.text = "%d" % roundi(volume.value)
	var quality_id := String(_view.get("effects_quality", "medium"))
	quality.select(maxi(0, ["low", "medium", "high"].find(quality_id)))
	reduced_motion.button_pressed = bool(_view.get("reduced_motion", false))
	global_auto_skill.button_pressed = bool(_view.get("global_auto_skill", false))
	local_playtest.button_pressed = bool(_view.get("local_playtest_logging", false))
	var journal_visible := local_playtest.button_pressed
	playtest_status.visible = journal_visible
	playtest_actions.visible = journal_visible
	playtest_status.text = String(_view.get("playtest_status", ""))
	var persistent := bool(_view.get("storage_persistent", false))
	persistence_status.text = String(_view.get("persistence_copy", ""))
	persistence_status.add_theme_color_override("font_color", GREEN if persistent else GOLD)
	var has_import := bool(_view.get("has_import_preview", false))
	import_button.text = "确认覆盖当前进度" if has_import else "选择备份并校验"
	import_preview.visible = has_import
	import_preview.text = String(_view.get("import_preview", ""))
	delete_button.text = (
		"再次点击确认删除"
		if bool(_view.get("delete_armed", false))
		else "删除本地存档"
	)
	_projecting = false


func _on_volume_changed(value: float) -> void:
	volume_value.text = "%d" % roundi(value)
	if not _projecting:
		setting_changed.emit("master_volume", value)


func _on_quality_selected(index: int) -> void:
	if not _projecting and index >= 0 and index < 3:
		setting_changed.emit("effects_quality", ["low", "medium", "high"][index])


func _emit_setting(value: bool, setting_id: String) -> void:
	if not _projecting:
		setting_changed.emit(setting_id, value)


func _bind_action(button: Button, action_id: String) -> void:
	button.pressed.connect(action_requested.emit.bind(action_id))


func _focus_primary_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree() and save_button.is_inside_tree():
		save_button.grab_focus()


func _apply_theme() -> void:
	for panel in [experience_panel, data_panel]:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(PANEL, 0.94)
		panel_style.border_color = Color(LINE, 0.8)
		panel_style.set_border_width_all(1)
		panel_style.set_corner_radius_all(3)
		panel.add_theme_stylebox_override("panel", panel_style)
	for label in find_children("*", "Label", true, false):
		(label as Label).add_theme_font_override("font", CJK_FONT)
		(label as Label).add_theme_color_override("font_color", TEXT)
	for heading in [%SettingsExperienceHeading, %SettingsDataHeading]:
		heading.add_theme_font_size_override("font_size", 16)
		heading.add_theme_color_override("font_color", CYAN)
	for control in find_children("*", "Control", true, false):
		(control as Control).add_theme_font_override("font", CJK_FONT)
	for button in find_children("*", "Button", true, false):
		_style_button(button as Button, button == save_button)
	import_preview.add_theme_color_override("font_color", GOLD)
	playtest_status.add_theme_color_override("font_color", GREEN)
	volume_value.add_theme_color_override("font_color", CYAN)


func _style_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 14)
	var normal := _button_style(GOLD if primary else PANEL_2, GOLD if primary else LINE)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _button_style(normal.bg_color.lightened(0.1), GOLD))
	button.add_theme_stylebox_override("pressed", _button_style(PANEL, GOLD))
	button.add_theme_stylebox_override("focus", _button_style(Color(GOLD, 0.22), Color.WHITE))
	button.add_theme_color_override("font_color", BG if primary else TEXT)
	button.add_theme_color_override("font_hover_color", BG if primary else TEXT)


func _button_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
