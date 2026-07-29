extends SceneTree

const OUTPUT_DIR := "res://artifacts"

var game: FpsGame
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var scene := load("res://game/fps_game.tscn") as PackedScene
	if scene == null:
		push_error("FPS capture cannot load the real main scene")
		quit(1)
		return
	game = scene.instantiate() as FpsGame
	root.add_child(game)
	await _wait_frames(12)

	await _capture("quiet_entry.png")

	game.debug_combat_peak()
	await _wait_frames(4)
	await _capture("combat_peak.png")

	game.restart_run()
	game.debug_set_low_health_reload()
	await _wait_frames(5)
	await _capture("low_health_reload.png")

	game.restart_run()
	game.run_state.elapsed_seconds = 34.7
	game.run_state.shots_fired = 19
	game.run_state.hits = 12
	game.debug_eliminate_all()
	await _wait_frames(8)
	await _capture("victory.png")

	game.restart_run()
	game.run_state.elapsed_seconds = 18.4
	game.run_state.shots_fired = 11
	game.run_state.hits = 4
	game.debug_defeat_player()
	await _wait_frames(8)
	await _capture("failure.png")

	if failures.is_empty():
		print("FPS_REVIEW_CAPTURES_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("FPS_REVIEW_CAPTURES_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _capture(filename: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("%s produced no viewport image" % filename)
		return
	var path := "%s/%s" % [OUTPUT_DIR, filename]
	var error := image.save_png(path)
	if error != OK:
		failures.append("%s save failed: %s" % [filename, error_string(error)])


func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame
