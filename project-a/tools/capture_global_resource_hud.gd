extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	change_scene_to_file("res://scenes/screens/main.tscn")
	for _frame in 8:
		await process_frame
	var main := current_scene
	var game: Node = root.get_node_or_null("Game")
	if main == null or game == null:
		_fail("app shell unavailable")
		return
	var audio_director: Node = main.get("audio_director")
	if audio_director != null:
		audio_director.call("set_playback_enabled", false)
	game.reset_game(20260727, 1000)
	var state: RefCounted = game.current_state()
	state.economy.toilet_coins = 519
	state.economy.hero_shards = 8
	state.economy.recruit_tickets = 0
	state.factory.materials = {"porcelain": 56, "parts": 0, "sludge": 0}
	main.set("legion_tab", "roster")
	main.call("_show_legion")
	for _frame in 10:
		await process_frame
	var global_hud := main.find_child("GlobalCoreResourceHUD", true, false) as Control
	var local_summary := main.find_child("RosterResourceContext", true, false)
	if global_hud == null or not global_hud.is_visible_in_tree():
		_fail("global resource HUD is not visible")
		return
	if global_hud.get_global_rect().get_center().x <= root.size.x * 0.5:
		_fail("global resource HUD is not in the right half")
		return
	if local_summary != null:
		_fail("roster still contains the retired local resource summary")
		return
	var output := "res://artifacts/ui-global-resource-hud-844x390.png"
	var error := root.get_texture().get_image().save_png(output)
	if error != OK:
		_fail(error_string(error))
		return
	main.queue_free()
	await process_frame
	print("GLOBAL RESOURCE HUD CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
	quit(0)


func _fail(reason: String) -> void:
	push_error("GLOBAL RESOURCE HUD CAPTURE FAIL: %s" % reason)
	quit(1)
