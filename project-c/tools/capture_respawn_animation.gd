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
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game._select_lane(1)
	var target: Dictionary = game.arena.heroes.filter(func(hero: Dictionary) -> bool: return int(hero.team) == 1 and int(hero.lane) == 1)[0]
	target.hp = 20.0
	game.arena.player_cast(1)
	var manifest_path := ProjectSettings.globalize_path("res://artifacts/respawn-continuity.csv")
	var manifest := FileAccess.open(manifest_path, FileAccess.WRITE)
	if manifest == null:
		push_error("Cannot create continuity manifest")
		quit(1)
		return
	manifest.store_line("# instance_id=%d" % game.get_instance_id())
	manifest.store_line("# script_sha256=%s" % FileAccess.get_sha256("res://tools/capture_respawn_animation.gd"))
	manifest.store_line("frame,elapsed,respawn_remaining,spawn_protection,hp,kills,gold")
	for frame_index in 91:
		var expected_elapsed := float(frame_index) * 0.1
		var expected_remaining := maxf(0.0, game.arena.HERO_RESPAWN_SECONDS - expected_elapsed)
		var expected_protection := 0.0
		if expected_elapsed >= game.arena.HERO_RESPAWN_SECONDS:
			expected_protection = maxf(
				0.0,
				game.arena.SPAWN_PROTECTION_SECONDS
					- (expected_elapsed - game.arena.HERO_RESPAWN_SECONDS)
			)
		if not is_equal_approx(float(game.arena.elapsed), expected_elapsed):
			push_error("Unexpected elapsed at frame %d: %.6f" % [frame_index, game.arena.elapsed])
			quit(1)
			return
		if expected_remaining > 0.0:
			if absf(float(target.respawn_remaining) - expected_remaining) > 0.0001 or float(target.hp) > 0.0:
				push_error("Unexpected dead state at frame %d" % frame_index)
				quit(1)
				return
		else:
			var invalid_respawn := float(target.respawn_remaining) != 0.0 or float(target.hp) <= 0.0
			if frame_index == 80: invalid_respawn = invalid_respawn or float(target.hp) != float(target.max_hp)
			if invalid_respawn:
				push_error("Unexpected respawn state at frame %d" % frame_index)
				quit(1)
				return
		if absf(float(target.spawn_protection) - expected_protection) > 0.0001:
			push_error("Unexpected spawn protection at frame %d: %.6f" % [frame_index, target.spawn_protection])
			quit(1)
			return
		manifest.store_line(
			"%d,%.1f,%.1f,%.2f,%.1f,%d,%d"
			% [
				frame_index,
				game.arena.elapsed,
				target.respawn_remaining,
				target.spawn_protection,
				target.hp,
				game.arena.team_kills[0],
				game.arena.gold[0],
			]
		)
		game.queue_redraw()
		await process_frame
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		var texture := root.get_texture()
		if texture == null:
			push_error("Capture requires a rendered session")
			quit(1)
			return
		var path := "res://artifacts/respawn_frames/frame-%03d.png" % frame_index
		var error := texture.get_image().save_png(ProjectSettings.globalize_path(path))
		if error != OK:
			push_error("Frame capture failed: %s" % error)
			quit(1)
			return
		if frame_index < 90: game.arena.tick(0.1)
	manifest.close()
	print("RESPAWN_ANIMATION_FRAMES_OK: 91")
	quit(0)
