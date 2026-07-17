class_name SafeAreaContainer
extends MarginContainer

const CONTENT_PADDING := 48


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


func _apply_safe_area() -> void:
	var viewport_size := Vector2i(get_viewport_rect().size)
	if OS.get_name() not in [&"Android", &"iOS"]:
		_set_margins(Vector4i.ZERO)
		return

	var safe_area := DisplayServer.get_display_safe_area()
	var display_size := DisplayServer.window_get_size()
	var margins := PlatformMetrics.display_safe_area_margins(
		viewport_size,
		display_size,
		safe_area
	)
	_set_margins(margins)


func _set_margins(margins: Vector4i) -> void:
	add_theme_constant_override("margin_left", margins.x + CONTENT_PADDING)
	add_theme_constant_override("margin_top", margins.y + CONTENT_PADDING)
	add_theme_constant_override("margin_right", margins.z + CONTENT_PADDING)
	add_theme_constant_override("margin_bottom", margins.w + CONTENT_PADDING)
