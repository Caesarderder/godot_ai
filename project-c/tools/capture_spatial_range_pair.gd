extends SceneTree

const ArenaScript = preload("res://features/match/three_lane_match.gd")
const RulesScript = preload("res://features/match/match_rules.gd")
const OUTPUTS := {
	"vesper": "res://artifacts/range-pair-vesper-out-of-range.png",
	"sable": "res://artifacts/range-pair-sable-hit.png",
}
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
	var csv_path := ProjectSettings.globalize_path("res://artifacts/spatial-range-pair.csv")
	var csv := FileAccess.open(csv_path, FileAccess.WRITE)
	if csv == null:
		push_error("Cannot create spatial range manifest")
		quit(1)
		return
	var script_hash := FileAccess.get_sha256("res://tools/capture_spatial_range_pair.gd")
	csv.store_line("script_sha256,hero,result,target_slot,target_hp_before,target_hp_after,caster_before,caster_after,distance,cast_range,screenshot")
	await _capture_case(csv, script_hash, 1, "vesper")
	await _capture_case(csv, script_hash, 4, "sable")
	csv.close()
	print("SPATIAL_RANGE_PAIR_CAPTURE_OK")
	quit(0)

func _capture_case(csv: FileAccess, script_hash: String, slot: int, hero_id: String) -> void:
	game.arena.reset()
	game.controlled_slot = slot
	game.player_lane = RulesScript.Lane.MID
	var caster: Dictionary = game.arena.player_hero_by_slot(slot)
	caster.lane = RulesScript.Lane.MID
	caster.lane_position = 0.10
	var target := _find_target(1)
	target.lane_position = 0.65
	var target_hp_before := float(target.hp)
	var caster_before := float(caster.lane_position)
	var event := InputEventAction.new()
	event.action = &"arc_bolt"
	event.pressed = true
	game._unhandled_input(event)
	var result: Dictionary = game.arena.last_ability_result
	var expected_ok := hero_id == "sable"
	if bool(result.get("ok", false)) != expected_ok:
		push_error("%s result did not match range contract" % hero_id)
		quit(1)
		return
	if int(result.get("target_slot", -1)) != 1:
		push_error("%s did not resolve Dusk MID slot 1" % hero_id)
		quit(1)
		return
	if hero_id == "vesper" and (
		String(result.get("reason", "")) != "OUT_OF_RANGE"
		or not is_equal_approx(float(target.hp), 100.0)
		or not is_equal_approx(float(caster.lane_position), caster_before)
	):
		push_error("Vesper rejection mutated paired state")
		quit(1)
		return
	if hero_id == "sable" and not is_equal_approx(float(target.hp), 48.0):
		push_error("Sable did not apply paired long-range damage")
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
	var output: String = String(OUTPUTS[hero_id])
	var error := texture.get_image().save_png(ProjectSettings.globalize_path(output))
	if error != OK:
		push_error("Spatial range capture failed: %s" % error)
		quit(1)
		return
	csv.store_line(
		"%s,%s,%s,%d,%.1f,%.1f,%.2f,%.2f,%.2f,%.2f,%s"
		% [
			script_hash,
			hero_id,
			String(result.get("effect", result.get("reason", ""))),
			int(result.target_slot),
			target_hp_before,
			float(target.hp),
			caster_before,
			float(caster.lane_position),
			float(result.distance),
			float(result.cast_range),
			output.get_file(),
		]
	)

func _find_target(slot: int) -> Dictionary:
	for hero in game.arena.heroes:
		if (
			int(hero.team) == ArenaScript.Team.DUSK
			and int(hero.lane) == RulesScript.Lane.MID
			and int(hero.slot) == slot
		):
			return hero
	return {}
