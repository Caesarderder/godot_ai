extends SceneTree

const SOURCE := "../tmp/imagegen/blueprint-icons-key.png"
const OUTPUT_DIR := "res://assets/ui/blueprints"
const ICON_SIZE := Vector2i(64, 64)
const ICONS := [
	{"name": "branch_assault.webp", "rect": Rect2i(62, 54, 438, 434)},
	{"name": "branch_heavy.webp", "rect": Rect2i(546, 54, 438, 434)},
	{"name": "branch_flying.webp", "rect": Rect2i(1032, 54, 438, 434)},
	{"name": "branch_support.webp", "rect": Rect2i(62, 532, 438, 434)},
	{"name": "ability_charge.webp", "rect": Rect2i(546, 532, 438, 434)},
	{"name": "ability_sonic.webp", "rect": Rect2i(1032, 532, 438, 434)},
]


func _init() -> void:
	var source_path := ProjectSettings.globalize_path(SOURCE)
	var source := Image.load_from_file(source_path)
	if source.is_empty():
		push_error("Could not load generated blueprint icon sheet: %s" % source_path)
		quit(1)
		return
	for y in source.get_height():
		for x in source.get_width():
			var pixel := source.get_pixel(x, y)
			var key_distance := Vector3(
				1.0 - pixel.r,
				pixel.g,
				1.0 - pixel.b
			).length()
			if key_distance < 0.55:
				pixel.a = smoothstep(0.025, 0.55, key_distance)
				pixel.r = minf(pixel.r, pixel.b * 0.9)
			if pixel.r > pixel.g * 1.25 and pixel.b > pixel.g * 1.25:
				var luminance := maxf(0.35, pixel.get_luminance())
				pixel.r = 0.35 * luminance
				pixel.g = 0.79 * luminance
				pixel.b = 0.76 * luminance
			source.set_pixel(x, y, pixel)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for definition in ICONS:
		var icon := source.get_region(definition["rect"])
		icon.resize(ICON_SIZE.x, ICON_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var output_path := "%s/%s" % [OUTPUT_DIR, definition["name"]]
		var error := icon.save_webp(output_path, true, 0.82)
		if error != OK:
			push_error("Could not save %s: %s" % [output_path, error_string(error)])
			quit(1)
			return
	print("BLUEPRINT_ICON_WORKFLOW_OK")
	quit(0)
