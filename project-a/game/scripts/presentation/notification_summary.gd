class_name NotificationSummary
extends RefCounted

const MetaProgressionServiceScript := preload(
	"res://game/scripts/domain/meta/meta_progression_service.gd"
)
const NewPlayerWelfareServiceScript := preload(
	"res://game/scripts/domain/meta/new_player_welfare_service.gd"
)
const LogisticsServiceScript := preload(
	"res://game/scripts/domain/factory/logistics_service.gd"
)


static func derive(state: RefCounted, now_unix: int) -> Dictionary:
	if state == null:
		return _empty()
	var factory_queue_ready := 0
	var factory_work_ready := 0
	if state.get("factory") != null:
		for order_value in state.factory.production_queue:
			if typeof(order_value) != TYPE_DICTIONARY:
				continue
			if int((order_value as Dictionary).get("completes_at_unix", 0)) <= now_unix:
				factory_queue_ready += 1
		var facility_work := state.factory.facility_work as Dictionary
		if (
			not facility_work.is_empty()
			and LogisticsServiceScript.facility_work_completes_at(facility_work) <= now_unix
		):
			factory_work_ready = 1
	var quest_claimable := _unclaimed_count(state.get("quests"))
	var achievement_claimable := _unclaimed_count(state.get("achievements"))
	var meta := MetaProgressionServiceScript.claimable_summary(state)
	var welfare := NewPlayerWelfareServiceScript.snapshot(state)
	var welfare_claimable := (
		int(bool(welfare.get("claimable", false)))
		+ int(bool(welfare.get("case_openable", false)))
	)
	var action_claimable := (
		int(meta.get("missions", 0))
		+ welfare_claimable
	)
	var pass_claimable := int(meta.get("pass", 0)) + int(meta.get("commander", 0))
	var goals_achievement_claimable := (
		int(meta.get("achievements", 0))
	)
	# Legacy production orders are still reported for migration diagnostics, but the
	# current factory screen has no order-claim route. Never light an unreachable dot.
	var factory_ready := factory_work_ready
	var goal_claimable := action_claimable + pass_claimable + goals_achievement_claimable
	return {
		"factory_queue_ready": factory_queue_ready,
		"factory_work_ready": factory_work_ready,
		"factory_ready": factory_ready,
		"quest_claimable": quest_claimable,
		"achievement_claimable": achievement_claimable,
		"welfare_claimable": welfare_claimable,
		"goals_action": action_claimable,
		"goals_pass": pass_claimable,
		"goals_achievements": goals_achievement_claimable,
		"goal_claimable": goal_claimable,
		"total": factory_ready + goal_claimable,
	}


static func _unclaimed_count(bucket_value: Variant) -> int:
	if typeof(bucket_value) != TYPE_DICTIONARY:
		return 0
	var bucket := bucket_value as Dictionary
	var completed := bucket.get("completed", {}) as Dictionary
	var claimed := bucket.get("claimed", {}) as Dictionary
	var count := 0
	for item_id in completed:
		if not claimed.has(item_id):
			count += 1
	return count


static func _empty() -> Dictionary:
	return {
		"factory_queue_ready": 0,
		"factory_work_ready": 0,
		"factory_ready": 0,
		"quest_claimable": 0,
		"achievement_claimable": 0,
		"welfare_claimable": 0,
		"goals_action": 0,
		"goals_pass": 0,
		"goals_achievements": 0,
		"goal_claimable": 0,
		"total": 0,
	}
