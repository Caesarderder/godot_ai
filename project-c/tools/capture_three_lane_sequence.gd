extends SceneTree

var game: Variant

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://game/three_lane_arena.tscn") as PackedScene
	if packed == null:
		push_error("Cannot load three-lane arena")
		quit(1)
		return
	game = packed.instantiate()
	root.add_child(game)
	for _frame in 4: await process_frame
	game._select_lane(0)
	if not await _save("res://artifacts/sequence-01-top-selected.png"):
		quit(1)
		return
	game._select_lane(1)
	var target: Dictionary = game.arena.heroes.filter(func(hero: Dictionary) -> bool: return int(hero.team) == 1 and int(hero.lane) == 1)[0]
	target.hp = 20.0
	game.arena.player_cast(1)
	if not await _save("res://artifacts/sequence-02-mid-death.png"):
		quit(1)
		return
	game.arena.tick(4.0)
	if not await _save("res://artifacts/sequence-03-mid-countdown.png"):
		quit(1)
		return
	game.arena.tick(4.1)
	if not await _save("res://artifacts/sequence-04-mid-respawn.png"):
		quit(1)
		return
	print("THREE_LANE_SEQUENCE_CAPTURE_OK")
	quit(0)

func _save(path: String) -> bool:
	for _frame in 3: await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var texture := root.get_texture()
	if texture == null:
		push_error("Capture requires a rendered session")
		return false
	var output := ProjectSettings.globalize_path(path)
	var error := texture.get_image().save_png(output)
	if error != OK:
		push_error("Capture failed: %s" % error)
		return false
	return true
