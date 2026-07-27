extends SceneTree

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const MetaProgressionServiceScript := preload(
	"res://game/scripts/domain/meta/meta_progression_service.gd"
)
const NotificationSummaryScript := preload(
	"res://game/scripts/presentation/notification_summary.gd"
)
const NotificationBadgeScript := preload(
	"res://game/scripts/presentation/notification_badge.gd"
)
const LogisticsServiceScript := preload(
	"res://game/scripts/domain/factory/logistics_service.gd"
)
const NewPlayerWelfareServiceScript := preload(
	"res://game/scripts/domain/meta/new_player_welfare_service.gd"
)
const StarterGiftServiceScript := preload(
	"res://game/scripts/domain/meta/starter_gift_service.gd"
)

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := GameStateScript.create_new(20260727, 100)
	var empty := NotificationSummaryScript.derive(state, 100)
	_eq(int(empty["total"]), 1, "built-base fixtures expose exactly one newcomer gift")

	state.quests["completed"]["legacy.quest"] = true
	state.achievements["completed"]["legacy.achievement"] = true
	var legacy := NotificationSummaryScript.derive(state, 100)
	_eq(
		int(legacy["goal_claimable"]),
		1,
		"legacy buckets add no dots beyond the reachable newcomer gift"
	)

	state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
	]
	state.meta_progression.commander_xp = 300
	MetaProgressionServiceScript.refresh(state, 100)
	state.meta_progression.season_merit = 350
	var completed_mission_id := ""
	for mission_id in state.meta_progression.missions:
		var mission := state.meta_progression.missions[mission_id] as Dictionary
		mission["progress"] = int(mission.get("target", 1))
		completed_mission_id = String(mission_id)
		break
	var goals := NotificationSummaryScript.derive(state, 100)
	_ok(int(goals["goals_action"]) > 0, "claimable mission or welfare lights action")
	_ok(int(goals["goals_pass"]) > 0, "commander and pass rewards light pass")
	_ok(int(goals["goal_claimable"]) > 0, "goal total aggregates reachable tabs")
	var completed_mission := (
		state.meta_progression.missions[completed_mission_id] as Dictionary
	)
	_ok(
		bool(MetaProgressionServiceScript.claim_mission(
			state,
			completed_mission_id,
			int(completed_mission.get("generation", 0))
		).get("ok", false)),
		"claimable mission can be claimed through its real domain path"
	)
	_ok(
		bool(NewPlayerWelfareServiceScript.claim(state).get("ok", false)),
		"claimable welfare can be claimed through its real domain path"
	)
	_ok(
		bool(NewPlayerWelfareServiceScript.open_logistics_case(state).get("ok", false)),
		"opened welfare case clears its actionable notification"
	)
	_ok(
		bool(StarterGiftServiceScript.claim(state, "rookie_departure_v1").get("ok", false)),
		"research milestone gift can be claimed through its real domain path"
	)
	_ok(
		bool(StarterGiftServiceScript.claim(state, "new_game_supply_v1").get("ok", false)),
		"1-3 gift can be claimed through its real domain path"
	)
	_eq(
		int(NotificationSummaryScript.derive(state, 100)["goals_action"]),
		0,
		"action notification disappears after all real claims"
	)
	_ok(
		bool(MetaProgressionServiceScript.claim_all_commander_levels(state).get("ok", false)),
		"commander rewards can be claimed through their real domain path"
	)
	_ok(
		bool(MetaProgressionServiceScript.claim_all_pass_levels(state).get("ok", false)),
		"pass rewards can be claimed through their real domain path"
	)
	_eq(
		int(NotificationSummaryScript.derive(state, 100)["goals_pass"]),
		0,
		"pass notification disappears after all real claims"
	)

	state.factory.facility_work = {
		"work_type": "upgrade",
		"facility_id": "command_center",
		"started_at_unix": 100,
		"completes_at_unix": 105,
		"target_level": 2,
	}
	_eq(
		int(NotificationSummaryScript.derive(state, 104)["factory_work_ready"]),
		0,
		"factory work stays dark before completion"
	)
	_eq(
		int(NotificationSummaryScript.derive(state, 105)["factory_work_ready"]),
		1,
		"factory work lights exactly at completion"
	)
	_ok(
		bool(LogisticsServiceScript.claim_facility_work(state, 105).get("ok", false)),
		"completed factory work can be claimed through its real domain path"
	)
	_eq(
		int(NotificationSummaryScript.derive(state, 105)["factory_ready"]),
		0,
		"factory notification disappears after the real claim"
	)

	var host := Control.new()
	host.custom_minimum_size = Vector2(100, 48)
	root.add_child(host)
	var badge := NotificationBadgeScript.new() as NotificationBadge
	host.add_child(badge)
	await process_frame
	badge.set_count(0)
	_ok(not badge.visible, "zero count hides the badge")
	badge.set_count(100)
	_ok(badge.visible and badge.text == "99+", "large counts cap at 99+")
	_ok(
		badge.mouse_filter == Control.MOUSE_FILTER_IGNORE
			and badge.focus_mode == Control.FOCUS_NONE,
		"badge never steals click or focus from its destination"
	)
	host.queue_free()
	await process_frame

	if failures.is_empty():
		print("NOTIFICATION_SYSTEM_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("NOTIFICATION_SYSTEM_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _ok(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _eq(actual: Variant, expected: Variant, message: String) -> void:
	_ok(actual == expected, "%s (expected %s, got %s)" % [message, expected, actual])
