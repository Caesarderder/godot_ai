extends SceneTree

const OnboardingCatalogScript := preload(
	"res://game/scripts/domain/onboarding/onboarding_catalog.gd"
)


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	change_scene_to_file("res://scenes/screens/main.tscn")
	for _frame in 20:
		await process_frame
	var main := current_scene
	if main == null:
		push_error("FACTION JOURNEY CAPTURE FAIL: main scene unavailable")
		quit(1)
		return
	var game: Node = main.get("game")
	game.call("reset_game", 20260728, 1000)
	var state: RefCounted = game.call("current_state")
	state.meta_progression.commander_xp = 450
	state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
	]
	state.stage_progress["highest_unlocked_stage"] = "stage_2_1"
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	state.onboarding["active_index"] = OnboardingCatalogScript.count()
	state.onboarding["progress"] = {}
	state.onboarding["completed"] = {}
	state.onboarding["claimed"] = {}
	main.call("_claim_faction_signal")
	for _frame in 8:
		await process_frame
	main.call("_show_goals")
	for _frame in 8:
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png("res://artifacts/ui-faction-journey-research-844x390.png")
	if error != OK:
		push_error("FACTION JOURNEY CAPTURE FAIL: %s" % error_string(error))
		quit(1)
		return
	print("FACTION_JOURNEY_CAPTURE_OK")
	quit(0)
