class_name PlatformMetrics
extends RefCounted


static func safe_area_margins(viewport_size: Vector2i, safe_area: Rect2i) -> Vector4i:
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return Vector4i.ZERO

	var left := clampi(safe_area.position.x, 0, viewport_size.x)
	var top := clampi(safe_area.position.y, 0, viewport_size.y)
	var right_edge := clampi(safe_area.end.x, left, viewport_size.x)
	var bottom_edge := clampi(safe_area.end.y, top, viewport_size.y)
	return Vector4i(
		left,
		top,
		viewport_size.x - right_edge,
		viewport_size.y - bottom_edge
	)


static func display_safe_area_margins(
	viewport_size: Vector2i,
	display_size: Vector2i,
	safe_area: Rect2i
) -> Vector4i:
	if display_size.x <= 0 or display_size.y <= 0:
		return Vector4i.ZERO
	var scale := Vector2(viewport_size) / Vector2(display_size)
	var viewport_safe_area := Rect2i(
		Vector2i((Vector2(safe_area.position) * scale).round()),
		Vector2i((Vector2(safe_area.size) * scale).round())
	)
	return safe_area_margins(viewport_size, viewport_safe_area)
