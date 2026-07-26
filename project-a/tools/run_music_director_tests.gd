extends SceneTree

const MUSIC_SCENE := preload("res://game/scenes/presentation/music_director.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var music := MUSIC_SCENE.instantiate()
	root.add_child(music)
	await process_frame
	_check(music.current_state() == &"silent", "music starts silent before the first player gesture")
	_check(music.active_track_count() == 0, "silent state owns no active music voice")

	music.request_state(&"base", true)
	_check(music.current_state() == &"base", "base route selects factory ambience")
	_check(music.active_track_count() == 1, "base route owns exactly one streaming voice")

	music.request_state(&"battle", true)
	_check(music.current_state() == &"battle", "ordinary siege selects battle music")
	_check(music.active_track_count() == 1, "immediate music switch stops the previous voice")

	music.set_runtime_active(false)
	_check(music.active_track_count() == 0, "hidden or inactive runtime pauses music")
	music.set_runtime_active(true)
	_check(music.active_track_count() == 1, "interactive runtime resumes the desired track")

	music.request_state(&"base")
	music.request_state(&"battle")
	music.request_state(&"boss")
	await create_timer(1.0).timeout
	_check(music.current_state() == &"boss", "latest interrupted crossfade wins")
	_check(music.active_track_count() == 1, "completed crossfade leaves one music voice")

	music.request_state(&"silent", true)
	_check(music.active_track_count() == 0, "immediate silence releases the active stream")
	music.shutdown()
	root.remove_child(music)
	music.free()
	await process_frame

	if failures.is_empty():
		print("MUSIC_DIRECTOR_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("MUSIC_DIRECTOR_TESTS_FAIL: %d" % failures.size())
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
