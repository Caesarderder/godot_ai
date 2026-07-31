extends SceneTree

const SOURCE := "../tmp/imagegen/achievement-medals-key.png"
const OUTPUT_DIR := "res://assets/ui/achievements"
const ICON_SIZE := Vector2i(64, 64)
const ICONS := [
	{"name": "captured_fortress.webp", "rect": Rect2i(34, 28, 444, 446)},
	{"name": "campaign_network.webp", "rect": Rect2i(546, 28, 424, 446)},
	{"name": "battle_mastery.webp", "rect": Rect2i(1050, 28, 440, 446)},
	{"name": "factory_mastery.webp", "rect": Rect2i(34, 526, 444, 454)},
	{"name": "commander_rank.webp", "rect": Rect2i(550, 526, 420, 454)},
	{"name": "classified_lock.webp", "rect": Rect2i(1050, 526, 440, 454)},
]


func _init() -> void:
	var source_path := ProjectSettings.globalize_path(SOURCE)
	var source := Image.load_from_file(source_path)
	if source.is_empty():
		push_error("Could not load generated achievement medal sheet: %s" % source_path)
		quit(1)
		return
	for y in source.get_height():
		for x in source.get_width():
			var pixel := source.get_pixel(x, y)
			var magenta_strength := minf(pixel.r, pixel.b) - pixel.g
			if magenta_strength > 0.025:
				var key_weight := smoothstep(0.025, 0.34, magenta_strength)
				pixel = pixel.lerp(Color("#071014"), key_weight)
				pixel.a = 1.0
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
	print("ACHIEVEMENT_MEDAL_WORKFLOW_OK")
	quit(0)
