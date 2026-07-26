class_name MobileViewportAdapter
extends Node

signal layout_changed(snapshot: Dictionary)

const DESIGN_SIZE := Vector2(844.0, 390.0)
const LANDSCAPE_MIN_ASPECT := 1.15
const MIN_TOUCH_CSS_PX := 48.0
const POLL_INTERVAL_SECONDS := 0.25

var snapshot: Dictionary = {}
var _poll_elapsed := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	refresh(true)


func _process(delta: float) -> void:
	_poll_elapsed += delta
	if _poll_elapsed < POLL_INTERVAL_SECONDS:
		return
	_poll_elapsed = 0.0
	refresh()


func refresh(force: bool = false) -> Dictionary:
	var next := build_snapshot(_read_surface(), get_viewport().get_visible_rect().size)
	if force or not _same_layout(snapshot, next):
		snapshot = next
		layout_changed.emit(snapshot.duplicate(true))
	else:
		snapshot = next
	return snapshot


func surface_size() -> Vector2:
	return snapshot.get("surface_size", get_viewport().get_visible_rect().size) as Vector2


func safe_margins() -> Vector4:
	return snapshot.get("safe_margins", Vector4(12.0, 8.0, 12.0, 8.0)) as Vector4


func touch_target_height() -> float:
	return float(snapshot.get("touch_target_height", MIN_TOUCH_CSS_PX))


func requires_landscape_gate() -> bool:
	return bool(snapshot.get("portrait_blocked", false))


static func classify(surface: Vector2) -> String:
	var width := maxf(1.0, surface.x)
	var height := maxf(1.0, surface.y)
	var aspect := width / height
	if aspect < LANDSCAPE_MIN_ASPECT:
		return "portrait_blocked"
	if height <= 340.0:
		return "compact_landscape"
	if aspect >= 2.25:
		return "ultrawide_landscape"
	if aspect <= 1.55:
		return "tablet_landscape"
	return "standard_landscape"


static func build_snapshot(surface_data: Dictionary, canvas_size: Vector2) -> Dictionary:
	var surface := Vector2(
		maxf(1.0, float(surface_data.get("width", canvas_size.x))),
		maxf(1.0, float(surface_data.get("height", canvas_size.y)))
	)
	var safe_css := Vector4(
		maxf(0.0, float(surface_data.get("safe_left", 0.0))),
		maxf(0.0, float(surface_data.get("safe_top", 0.0))),
		maxf(0.0, float(surface_data.get("safe_right", 0.0))),
		maxf(0.0, float(surface_data.get("safe_bottom", 0.0)))
	)
	var scale_x := surface.x / maxf(1.0, canvas_size.x)
	var scale_y := surface.y / maxf(1.0, canvas_size.y)
	var safe_ui := Vector4(
		safe_css.x / maxf(0.01, scale_x),
		safe_css.y / maxf(0.01, scale_y),
		safe_css.z / maxf(0.01, scale_x),
		safe_css.w / maxf(0.01, scale_y)
	)
	var minimum_gutter := Vector4(12.0, 8.0, 12.0, 8.0)
	var margins := Vector4(
		maxf(minimum_gutter.x, safe_ui.x + 6.0),
		maxf(minimum_gutter.y, safe_ui.y + 6.0),
		maxf(minimum_gutter.z, safe_ui.z + 6.0),
		maxf(minimum_gutter.w, safe_ui.w + 6.0)
	)
	var rendered_scale := minf(scale_x, scale_y)
	return {
		"surface_size": surface,
		"canvas_size": canvas_size,
		"profile": classify(surface),
		"portrait_blocked": classify(surface) == "portrait_blocked",
		"safe_css": safe_css,
		"safe_margins": margins,
		"touch_target_height": ceilf(MIN_TOUCH_CSS_PX / maxf(0.01, rendered_scale)),
		"visual_offset": Vector2(
			float(surface_data.get("offset_left", 0.0)),
			float(surface_data.get("offset_top", 0.0))
		),
	}


func _read_surface() -> Dictionary:
	if OS.has_feature("web"):
		var json := String(JavaScriptBridge.eval("""
			(() => {
				const root = document.documentElement;
				let probe = document.getElementById("godot-safe-area-probe");
				if (!probe) {
					probe = document.createElement("div");
					probe.id = "godot-safe-area-probe";
					Object.assign(probe.style, {
						position: "fixed", visibility: "hidden", pointerEvents: "none",
						paddingTop: "env(safe-area-inset-top)",
						paddingRight: "env(safe-area-inset-right)",
						paddingBottom: "env(safe-area-inset-bottom)",
						paddingLeft: "env(safe-area-inset-left)"
					});
					root.appendChild(probe);
				}
				const style = getComputedStyle(probe);
				const viewport = window.visualViewport;
				return JSON.stringify({
					width: viewport ? viewport.width : window.innerWidth,
					height: viewport ? viewport.height : window.innerHeight,
					offset_left: viewport ? viewport.offsetLeft : 0,
					offset_top: viewport ? viewport.offsetTop : 0,
					safe_left: parseFloat(style.paddingLeft) || 0,
					safe_top: parseFloat(style.paddingTop) || 0,
					safe_right: parseFloat(style.paddingRight) || 0,
					safe_bottom: parseFloat(style.paddingBottom) || 0
				});
			})()
		""", true))
		var parsed: Variant = JSON.parse_string(json)
		if parsed is Dictionary:
			return parsed as Dictionary
	var viewport_size := get_viewport().get_visible_rect().size
	var result := {"width": viewport_size.x, "height": viewport_size.y}
	var screen_size := Vector2(DisplayServer.screen_get_size())
	var safe_area := DisplayServer.get_display_safe_area()
	if screen_size.x > 0.0 and screen_size.y > 0.0 and safe_area.size.x > 0:
		result["safe_left"] = float(safe_area.position.x) * viewport_size.x / screen_size.x
		result["safe_top"] = float(safe_area.position.y) * viewport_size.y / screen_size.y
		result["safe_right"] = float(screen_size.x - safe_area.end.x) * viewport_size.x / screen_size.x
		result["safe_bottom"] = float(screen_size.y - safe_area.end.y) * viewport_size.y / screen_size.y
	return result


func _same_layout(previous: Dictionary, next: Dictionary) -> bool:
	if previous.is_empty():
		return false
	if String(previous.get("profile", "")) != String(next.get("profile", "")):
		return false
	var previous_margins := previous.get("safe_margins", Vector4.ZERO) as Vector4
	var next_margins := next.get("safe_margins", Vector4.ZERO) as Vector4
	if not previous_margins.is_equal_approx(next_margins):
		return false
	return is_equal_approx(
		float(previous.get("touch_target_height", 0.0)),
		float(next.get("touch_target_height", 0.0))
	)
