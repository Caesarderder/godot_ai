extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://game/three_lane_arena.tscn") as PackedScene
	if packed == null:
		push_error("Cannot load three-lane arena")
		quit(1)
		return
	var game: Variant = packed.instantiate()
	game.show_hero_labels = false
	root.add_child(game)
	for _frame in 8: await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var texture := root.get_texture()
	if texture == null:
		push_error("Capture requires a rendered session")
		quit(1)
		return
	var output := ProjectSettings.globalize_path("res://artifacts/three-lane-silhouette-review.png")
	var error := texture.get_image().save_png(output)
	if error != OK:
		push_error("Capture failed: %s" % error)
		quit(1)
		return
	print("HERO_SILHOUETTE_CAPTURE_OK: %s" % output)
	quit(0)
