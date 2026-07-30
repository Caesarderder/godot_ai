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
	root.add_child(game)
	for _frame in 4: await process_frame
	game.arena.player_buy("pulse_lens", game.player_lane)
	var target: Dictionary = game.arena.heroes.filter(func(hero: Dictionary) -> bool: return int(hero.team) == 1 and int(hero.lane) == game.player_lane)[0]
	target.hp = 30.0
	game.arena.player_cast(game.player_lane)
	for _frame in 4: await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var texture := root.get_texture()
	if texture == null:
		push_error("Capture requires a rendered session")
		quit(1)
		return
	var output := ProjectSettings.globalize_path("res://artifacts/three-lane-inventory-review.png")
	var error := texture.get_image().save_png(output)
	if error != OK:
		push_error("Capture failed: %s" % error)
		quit(1)
		return
	print("THREE_LANE_CAPTURE_OK: %s" % output)
	quit(0)
