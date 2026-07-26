extends SceneTree

const RUNTIME_FONT: FontFile = preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const RUNTIME_ROOTS: Array[String] = [
	"res://game",
	"res://scenes",
]
const RUNTIME_FILES: Array[String] = [
	"res://project.godot",
	"res://scripts/slg_main.gd",
]
const TEXT_EXTENSIONS: Array[String] = [
	"gd",
	"godot",
	"json",
	"cfg",
	"tscn",
	"tres",
]
const MIN_EXPECTED_NON_ASCII_CODEPOINTS := 500
const MAX_EXPECTED_NON_ASCII_CODEPOINTS := 2000

var failures: Array[String] = []


func _init() -> void:
	var required: Dictionary = {}
	for codepoint in range(32, 127):
		required[codepoint] = true
	for path in RUNTIME_FILES:
		_collect_file(path, required)
	for root in RUNTIME_ROOTS:
		_collect_directory(root, required)

	var non_ascii_count := 0
	var missing: Array[String] = []
	var codepoints: Array = required.keys()
	codepoints.sort()
	for value in codepoints:
		var codepoint := int(value)
		if codepoint > 127:
			non_ascii_count += 1
		if not RUNTIME_FONT.has_char(codepoint):
			missing.append("U+%04X %s" % [codepoint, String.chr(codepoint)])

	_check(
		non_ascii_count >= MIN_EXPECTED_NON_ASCII_CODEPOINTS,
		"runtime text scan unexpectedly found only %d non-ASCII codepoints" % non_ascii_count
	)
	_check(
		non_ascii_count <= MAX_EXPECTED_NON_ASCII_CODEPOINTS,
		"runtime text scan expanded to %d non-ASCII codepoints; review player-visible scope" % non_ascii_count
	)
	_check(
		missing.is_empty(),
		"runtime font misses %d required glyphs: %s" % [missing.size(), ", ".join(missing)]
	)

	if failures.is_empty():
		print(
			"FONT_COVERAGE_TESTS_OK: %d required codepoints (%d non-ASCII)" % [
				required.size(),
				non_ascii_count,
			]
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _collect_directory(path: String, required: Dictionary) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		failures.append("could not open runtime text directory: %s" % path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var child := path.path_join(entry)
			if directory.current_is_dir():
				_collect_directory(child, required)
			elif TEXT_EXTENSIONS.has(entry.get_extension().to_lower()):
				_collect_file(child, required)
		entry = directory.get_next()
	directory.list_dir_end()


func _collect_file(path: String, required: Dictionary) -> void:
	if not FileAccess.file_exists(path):
		failures.append("runtime text source missing: %s" % path)
		return
	var text := FileAccess.get_file_as_string(path)
	for index in text.length():
		var codepoint := text.unicode_at(index)
		if codepoint >= 32:
			required[codepoint] = true


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
