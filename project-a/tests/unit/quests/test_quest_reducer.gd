extends GutTest

const QuestReducer := preload("res://game/scripts/domain/quests/quest_reducer.gd")


func _quest_state() -> Dictionary:
	return {
		"quests": {
			"formation": {
				"event_type": "formation_changed",
				"target": 2,
				"progress": 0,
				"terminal": false,
				"claimed": false,
				"consumed_event_ids": [],
			}
		}
	}


func test_duplicate_event_id_advances_quest_only_once() -> void:
	var original := _quest_state()
	var event := {"event_id": "event-1", "type": "formation_changed", "amount": 1}
	var first := QuestReducer.reduce(original, [event])
	var replay := QuestReducer.reduce(first, [event])

	assert_eq(first.quests.formation.progress, 1)
	assert_eq(replay.quests.formation.progress, 1)
	assert_eq(original.quests.formation.progress, 0, "reducer must not mutate its input")


func test_terminal_quest_permanently_ignores_matching_events() -> void:
	var state := _quest_state()
	state.quests.formation.progress = 2
	state.quests.formation.terminal = true
	state.quests.formation.claimed = true

	var reduced := QuestReducer.reduce(
		state,
		[{"event_id": "late-event", "type": "formation_changed", "amount": 5}]
	)

	assert_eq(reduced.quests.formation.progress, 2)
	assert_false(reduced.quests.formation.consumed_event_ids.has("late-event"))


func test_six_hundred_unique_causal_events_remain_consumed() -> void:
	var state := _quest_state()
	state.quests.formation.target = 1000
	var events: Array = []
	for index in range(600):
		events.append({
			"event_id": "event-%d" % index,
			"type": "formation_changed",
			"amount": 1,
		})

	var reduced := QuestReducer.reduce(state, events)
	var replayed := QuestReducer.reduce(
		reduced,
		[events[0], events[255], events[511]]
	)

	assert_eq(reduced.quests.formation.progress, 600)
	assert_eq(reduced.quests.formation.consumed_event_ids.size(), 600)
	assert_eq(replayed.quests.formation.progress, 600)
