class_name SettingsScreen
extends VBoxContainer

signal setting_changed(setting_id: String, value: Variant)
signal action_requested(action_id: String)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const UiArtDirectionScript := preload("res://game/scripts/ui/ui_art_direction.gd")
const ICON_CHECK := preload("res://assets/ui/icons/kenney_game_icons/checkmark.png")
const ICON_EXIT := preload("res://assets/ui/icons/kenney_game_icons/exit_right.png")
const ICON_GEAR := preload("res://assets/ui/icons/kenney_game_icons/gear.png")
const ICON_HOME := preload("res://assets/ui/icons/kenney_game_icons/home.png")
const ICON_LOCK := preload("res://assets/ui/icons/kenney_game_icons/locked.png")
const ICON_SIGNAL := preload("res://assets/ui/icons/kenney_game_icons/signal_3.png")
const ICON_STAR := preload("res://assets/ui/icons/kenney_game_icons/star.png")
const ICON_WARNING := preload("res://assets/ui/icons/kenney_game_icons/warning.png")
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
@onready var experience_scroll: ScrollContainer = $SettingsLandscapeColumns/SettingsScroll
@onready var data_scroll: ScrollContainer = $SettingsLandscapeColumns/SettingsDataScroll
@onready var experience_tab: Button = %SettingsExperienceTab
@onready var data_tab: Button = %SettingsDataTab
@onready var volume: HSlider = %SettingsMasterVolumeSlider
@onready var volume_value: Label = %SettingsMasterVolumeValue
@onready var music_volume: HSlider = %SettingsMusicVolumeSlider
@onready var music_volume_value: Label = %SettingsMusicVolumeValue
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
@onready var back_button: Button = %SettingsBackButton

var _view: Dictionary = {}
var _projecting := false
var _active_section := "experience"


func _ready() -> void:
	_assign_icon_contract()
	_apply_theme()
	volume.value_changed.connect(_on_volume_changed)
	music_volume.value_changed.connect(_on_music_volume_changed)
	quality.item_selected.connect(_on_quality_selected)
	reduced_motion.toggled.connect(_emit_setting.bind("reduced_motion"))
	global_auto_skill.toggled.connect(_emit_setting.bind("global_auto_skill"))
	local_playtest.toggled.connect(_emit_setting.bind("local_playtest_logging"))
	experience_tab.pressed.connect(_select_section.bind("experience"))
	data_tab.pressed.connect(_select_section.bind("data"))
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
	else:
		_select_section(_active_section)
	_focus_primary_after_layout()


func _assign_icon_contract() -> void:
	quality.set_item_text(0, "低")
	quality.set_item_text(1, "中")
	quality.set_item_text(2, "高")
	_set_button_icon(experience_tab, ICON_GEAR, "音频、画面辅助与战斗偏好")
	_set_button_icon(data_tab, ICON_LOCK, "备份、导入、本地试玩记录与删除")
	_set_button_icon(%SettingsHelpButton, ICON_STAR, "打开图标化战术手册")
	_set_button_icon(%SettingsExportPlaytestButton, ICON_SIGNAL, "下载不含账号标识的本地试玩报告")
	_set_button_icon(%SettingsClearPlaytestButton, ICON_WARNING, "清空本机试玩记录")
	_set_button_icon(%SettingsExportSaveButton, ICON_EXIT, "下载当前进度备份")
	_set_button_icon(import_button, ICON_HOME, "选择备份，校验后再覆盖")
	_set_button_icon(delete_button, ICON_WARNING, "删除本机进度，需要再次确认")
	_set_button_icon(save_button, ICON_CHECK, "应用当前体验设置")
	_set_button_icon(back_button, ICON_EXIT, "返回上一界面")


func _set_button_icon(button: Button, icon: Texture2D, tooltip: String) -> void:
	button.icon = icon
	button.add_theme_constant_override("icon_max_width", 22)
	button.expand_icon = true
	button.tooltip_text = tooltip


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_apply_view()


func _apply_view() -> void:
	_projecting = true
	_apply_responsive_contract(bool(_view.get("compact", false)))
	volume.value = clampf(float(_view.get("master_volume", 80)), 0.0, 100.0)
	volume_value.text = "%d" % roundi(volume.value)
	music_volume.value = clampf(float(_view.get("music_volume", 55)), 0.0, 100.0)
	music_volume_value.text = "%d" % roundi(music_volume.value)
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
	import_button.text = "确认覆盖当前进度" if has_import else "导入并校验"
	import_preview.visible = has_import
	import_preview.text = String(_view.get("import_preview", ""))
	delete_button.text = (
		"再次点击确认删除"
		if bool(_view.get("delete_armed", false))
		else "删除本地存档"
	)
	if (
		bool(_view.get("local_playtest_logging", false))
		or has_import
		or bool(_view.get("delete_armed", false))
	):
		_active_section = "data"
	_select_section(_active_section)
	_projecting = false


func _apply_responsive_contract(compact: bool) -> void:
	$SettingsLandscapeColumns.custom_minimum_size.y = 126.0 if compact else 150.0
	var audio_label_width := 60.0 if compact else 82.0
	var gameplay_label_width := 96.0 if compact else 104.0
	var audio_control_width := 82.0 if compact else 150.0
	var gameplay_control_width := 104.0 if compact else 150.0
	for row_path in [
		"SettingsLandscapeColumns/SettingsScroll/SettingsExperiencePanel/Margin/Content/ExperienceColumns/AudioColumn/VolumeRow",
		"SettingsLandscapeColumns/SettingsScroll/SettingsExperiencePanel/Margin/Content/ExperienceColumns/AudioColumn/MusicVolumeRow",
	]:
		var row := get_node(row_path) as HBoxContainer
		(row.get_child(0) as Label).custom_minimum_size.x = audio_label_width
		(row.get_child(1) as Control).custom_minimum_size.x = audio_control_width
		(row.get_child(2) as Label).custom_minimum_size.x = 24.0 if compact else 28.0
	for row_path in [
		"SettingsLandscapeColumns/SettingsScroll/SettingsExperiencePanel/Margin/Content/ExperienceColumns/GameplayColumn/QualityRow",
		"SettingsLandscapeColumns/SettingsScroll/SettingsExperiencePanel/Margin/Content/ExperienceColumns/GameplayColumn/ReducedRow",
		"SettingsLandscapeColumns/SettingsScroll/SettingsExperiencePanel/Margin/Content/ExperienceColumns/GameplayColumn/AutoRow",
	]:
		var row := get_node(row_path) as HBoxContainer
		(row.get_child(0) as Label).custom_minimum_size.x = gameplay_label_width
		(row.get_child(1) as Control).custom_minimum_size.x = gameplay_control_width
	var playtest_row := get_node(
		"SettingsLandscapeColumns/SettingsDataScroll/SettingsDataPanel/Margin/Content/DataColumns/PlaytestColumn/PlaytestRow"
	) as HBoxContainer
	(playtest_row.get_child(0) as Label).custom_minimum_size.x = 136.0 if compact else 180.0
	(playtest_row.get_child(1) as Control).custom_minimum_size.x = 76.0 if compact else 90.0


func _select_section(section_id: String) -> void:
	_active_section = section_id if section_id == "data" else "experience"
	var show_experience := _active_section == "experience"
	experience_scroll.visible = show_experience
	data_scroll.visible = not show_experience
	save_button.visible = show_experience
	_style_section_tab(experience_tab, show_experience)
	_style_section_tab(data_tab, not show_experience)


func _on_volume_changed(value: float) -> void:
	volume_value.text = "%d" % roundi(value)
	if not _projecting:
		setting_changed.emit("master_volume", value)


func _on_music_volume_changed(value: float) -> void:
	music_volume_value.text = "%d" % roundi(value)
	if not _projecting:
		setting_changed.emit("music_volume", value)


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
		panel.add_theme_stylebox_override("panel", UiArtDirectionScript.panel_style())
	for label in find_children("*", "Label", true, false):
		(label as Label).add_theme_font_override("font", CJK_FONT)
		(label as Label).add_theme_color_override("font_color", TEXT)
	for control in find_children("*", "Control", true, false):
		(control as Control).add_theme_font_override("font", CJK_FONT)
	for button in find_children("*", "Button", true, false):
		if button != experience_tab and button != data_tab:
			_style_button(button as Button, button == save_button)
	for slider in [volume, music_volume]:
		_style_slider(slider)
	import_preview.add_theme_color_override("font_color", GOLD)
	playtest_status.add_theme_color_override("font_color", GREEN)
	playtest_status.add_theme_font_size_override("font_size", 11)
	persistence_status.add_theme_font_size_override("font_size", 11)
	volume_value.add_theme_color_override("font_color", CYAN)
	music_volume_value.add_theme_color_override("font_color", CYAN)
	delete_button.add_theme_color_override("font_color", Color("#f18a7f"))
	_select_section(_active_section)


func _style_section_tab(button: Button, active: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 14)
	var normal: StyleBox = _button_style(Color("#132326"), CYAN) if active else UiArtDirectionScript.button_style(false)
	var hover: StyleBox = _button_style(Color("#193337"), Color.WHITE) if active else UiArtDirectionScript.button_style(false, "hover")
	var pressed: StyleBox = _button_style(Color("#1d4447"), Color.WHITE) if active else UiArtDirectionScript.button_style(false, "pressed")
	var focus: StyleBox = _button_style(Color("#132326"), Color.WHITE) if active else UiArtDirectionScript.button_style(false, "focus")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", CYAN if active else TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)


func _style_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", UiArtDirectionScript.button_style(primary))
	button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(primary, "hover"))
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(primary, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(primary, "focus"))
	button.add_theme_color_override("font_color", BG if primary else TEXT)
	button.add_theme_color_override("font_hover_color", BG if primary else TEXT)


func _style_slider(slider: HSlider) -> void:
	slider.focus_mode = Control.FOCUS_ALL
	slider.add_theme_stylebox_override(
		"slider",
		_slider_style(Color("#0b1115"), Color(LINE, 0.9), 1)
	)
	slider.add_theme_stylebox_override(
		"grabber_area",
		_slider_style(Color(CYAN, 0.72), Color(CYAN, 0.9), 1)
	)
	# Godot 4.6 renders this state for both hover and keyboard/gamepad focus.
	slider.add_theme_stylebox_override(
		"grabber_area_highlight",
		_slider_style(Color(GOLD, 0.9), Color.WHITE, 2)
	)


func _slider_style(color: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(4)
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


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
