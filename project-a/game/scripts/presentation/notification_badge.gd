class_name NotificationBadge
extends Label

const BADGE_COLOR := Color("#f04444")
const BADGE_TEXT := Color("#ffffff")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -22.0
	offset_top = -6.0
	offset_right = 6.0
	offset_bottom = 22.0
	custom_minimum_size = Vector2(28, 28)
	add_theme_font_size_override("font_size", 13)
	add_theme_color_override("font_color", BADGE_TEXT)
	add_theme_constant_override("outline_size", 3)
	add_theme_color_override("font_outline_color", Color(0.12, 0.02, 0.02, 0.9))
	var style := StyleBoxFlat.new()
	style.bg_color = BADGE_COLOR
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#ff8a80")
	add_theme_stylebox_override("normal", style)


func set_count(value: int) -> void:
	var count := maxi(0, value)
	visible = count > 0
	text = "99+" if count > 99 else str(count)
	tooltip_text = "%d 项待处理" % count if count > 0 else ""
