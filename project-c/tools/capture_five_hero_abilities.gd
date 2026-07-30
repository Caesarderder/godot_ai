extends SceneTree

const HERO_LABELS := ["aerion-guard", "vesper-step", "mira-array", "orun-field", "sable-shot"]
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
	var manifest_path := ProjectSettings.globalize_path("res://artifacts/ability-spatial-state.csv")
	var manifest := FileAccess.open(manifest_path, FileAccess.WRITE)
	if manifest == null:
		push_error("Cannot create ability spatial manifest")
		quit(1)
		return
	manifest.store_line("# script_sha256=%s" % FileAccess.get_sha256("res://tools/capture_five_hero_abilities.gd"))
	manifest.store_line("hero,effect,caster_before,caster_after,target_position,distance,cast_range,target_hp,cooldown,screenshot")
	for slot in HERO_LABELS.size():
		game.arena.reset()
		game.controlled_slot = slot
		var controlled: Dictionary = game.arena.player_hero_by_slot(slot)
		game.player_lane = int(controlled.lane)
		var caster_before := float(controlled.lane_position)
		if String(controlled.hero_id) == "orun":
			for ally in game.arena.heroes:
				if int(ally.team) == 0 and int(ally.lane) == int(controlled.lane):
					ally.hp = 50.0
		var event := InputEventAction.new()
		event.action = &"arc_bolt"
		event.pressed = true
		game._unhandled_input(event)
		var result: Dictionary = game.arena.last_ability_result
		if not bool(result.get("ok", false)):
			push_error("Ability capture failed for slot %d" % slot)
			quit(1)
			return
		var target_position := -1.0
		var target_hp := -1.0
		if result.has("target_slot"):
			for hero in game.arena.heroes:
				if int(hero.team) == 1 and int(hero.lane) == int(controlled.lane) and int(hero.slot) == int(result.target_slot):
					target_position = float(hero.lane_position)
					target_hp = float(hero.hp)
					break
		if String(controlled.hero_id) == "vesper" and float(result.get("travel", 0.0)) <= 0.0:
			push_error("Vesper capture did not move")
			quit(1)
			return
		if String(controlled.hero_id) == "sable" and float(result.get("distance", 0.0)) <= game.arena.VESPER_CAST_RANGE:
			push_error("Sable capture is not beyond Vesper range")
			quit(1)
			return
		game.queue_redraw()
		await process_frame
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		var texture := root.get_texture()
		if texture == null:
			push_error("Capture requires a rendered session")
			quit(1)
			return
		var output := "res://artifacts/ability-%s.png" % HERO_LABELS[slot]
		var error := texture.get_image().save_png(ProjectSettings.globalize_path(output))
		if error != OK:
			push_error("Ability capture failed: %s" % error)
			quit(1)
			return
		manifest.store_line(
			"%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f,%.1f,%s"
			% [
				String(controlled.hero_id),
				String(result.effect),
				caster_before,
				float(controlled.lane_position),
				target_position,
				float(result.get("distance", -1.0)),
				float(result.get("cast_range", -1.0)),
				target_hp,
				float(controlled.ability_cooldown_remaining),
				output.get_file(),
			]
		)
	manifest.close()
	print("FIVE_HERO_ABILITY_CAPTURES_OK")
	quit(0)
