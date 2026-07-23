extends GutTest

const QuestCatalog := preload("res://game/scripts/domain/quests/quest_catalog.gd")
const QuestService := preload("res://game/scripts/domain/quests/quest_service.gd")
const QuestReducer := preload("res://game/scripts/domain/quests/quest_reducer.gd")


func test_default_catalog_contains_five_major_and_sixteen_minor_quests() -> void:
	var definitions: Dictionary = QuestCatalog.definitions()
	var major := 0
	var minor := 0
	for definition: Dictionary in definitions.values():
		major += int(definition["category"] == "major")
		minor += int(definition["category"] == "minor")
	assert_eq(major, 5)
	assert_eq(minor, 16)
	assert_eq(QuestService.create_default()["quests"].size(), 21)


func test_catalog_state_is_compatible_with_existing_event_reducer() -> void:
	var state: Dictionary = QuestService.create_default()
	var reduced: Dictionary = QuestReducer.reduce(state, [{
		"event_id": "battle-1", "type": "battle_won", "amount": 1,
	}])
	assert_eq(reduced["quests"]["major-01"]["progress"], 1)
	assert_true(reduced["quests"]["major-01"]["terminal"])


func test_completed_reward_can_only_be_claimed_once() -> void:
	var state: Dictionary = QuestService.create_default()
	state["quests"]["major-01"]["terminal"] = true
	var first: Dictionary = QuestService.claim_reward(state, "major-01")
	assert_true(first["ok"])
	assert_eq(first["reward"], QuestCatalog.definitions()["major-01"]["reward"])
	assert_true(first["quest_state"]["quests"]["major-01"]["claimed"])

	var second: Dictionary = QuestService.claim_reward(first["quest_state"], "major-01")
	assert_false(second["ok"])
	assert_eq(second["code"], "ALREADY_CLAIMED")
	assert_eq(second["reward"], {})


func test_incomplete_reward_cannot_be_claimed() -> void:
	var state: Dictionary = QuestService.create_default()
	var result: Dictionary = QuestService.claim_reward(state, "minor-01")
	assert_false(result["ok"])
	assert_eq(result["code"], "QUEST_INCOMPLETE")
	assert_eq(result["quest_state"], state)


func test_stage_access_never_depends_on_quest_progress_or_claims() -> void:
	var empty_state := {}
	var default_state: Dictionary = QuestService.create_default()
	default_state["quests"]["major-01"]["terminal"] = true
	assert_true(QuestService.can_start_stage("stage-1-5", empty_state))
	assert_true(QuestService.can_start_stage("stage-1-5", default_state))

