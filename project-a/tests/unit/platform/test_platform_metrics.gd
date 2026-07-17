extends GutTest

const PlatformMetricsScript := preload("res://game/scripts/app/platform_metrics.gd")


func test_safe_area_margins_for_portrait_notch() -> void:
	var margins := PlatformMetricsScript.safe_area_margins(
		Vector2i(1080, 1920),
		Rect2i(0, 96, 1080, 1776)
	)
	assert_eq(margins, Vector4i(0, 96, 0, 48))


func test_safe_area_is_clamped_to_viewport() -> void:
	var margins := PlatformMetricsScript.safe_area_margins(
		Vector2i(1080, 1920),
		Rect2i(-20, -30, 1200, 2100)
	)
	assert_eq(margins, Vector4i.ZERO)


func test_invalid_viewport_has_no_margins() -> void:
	assert_eq(
		PlatformMetricsScript.safe_area_margins(Vector2i.ZERO, Rect2i()),
		Vector4i.ZERO
	)


func test_display_pixels_are_scaled_into_viewport_coordinates() -> void:
	var margins := PlatformMetricsScript.display_safe_area_margins(
		Vector2i(1080, 1920),
		Vector2i(1440, 2560),
		Rect2i(0, 128, 1440, 2368)
	)
	assert_eq(margins, Vector4i(0, 96, 0, 48))
