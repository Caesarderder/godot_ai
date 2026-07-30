extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://game/moba_game.tscn") as PackedScene
	if packed == null:
		push_error("Cannot load MOBA scene"); quit(1); return
	var game := packed.instantiate() as MobaGame
	root.add_child(game)
	for _i in 4: await process_frame
	game.debug_action_peak()
	for _i in 8: await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var texture := root.get_texture()
	if texture == null:
		push_error("Capture requires a rendered (non-headless) Godot session")
		quit(1)
		return
	var image := texture.get_image()
	var output := ProjectSettings.globalize_path("res://artifacts/lane-action-review.png")
	var error := image.save_png(output)
	if error != OK:
		push_error("Capture failed: %s" % error); quit(1); return
	print("MOBA_CAPTURE_OK: %s" % output)
	quit(0)
