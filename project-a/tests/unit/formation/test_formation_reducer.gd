extends GutTest

const FormationReducerScript := preload("res://game/scripts/domain/formation/formation_reducer.gd")

const ROSTER_IDS: Array[String] = ["h1", "h2", "h3", "h4", "h5"]


func _slots() -> Dictionary:
	return {"front_1": "h1", "front_2": "h2", "back_1": "h3", "back_2": "h4"}


func test_two_front_two_back_contract_accepts_four_distinct_roster_heroes() -> void:
	assert_true(FormationReducerScript.validate(_slots(), ROSTER_IDS).valid)


func test_validation_rejects_missing_duplicate_unknown_and_extra_slots() -> void:
	var invalid: Dictionary = _slots()
	invalid.erase("back_2")
	invalid.front_2 = "h1"
	invalid.back_1 = "deleted"
	invalid.reserve = "h5"
	var validation: Dictionary = FormationReducerScript.validate(invalid, ROSTER_IDS)
	assert_false(validation.valid)
	assert_eq(validation.errors.size(), 4)


func test_set_formation_is_a_pure_reducer_and_rejects_dangling_ids() -> void:
	var original: Dictionary = {"slots": _slots(), "revision": 9}
	var changed_slots: Dictionary = {
		"front_1": "h5", "front_2": "h2", "back_1": "h3", "back_2": "h1"
	}
	var changed: Dictionary = FormationReducerScript.reduce(
		original, {"type": "set_formation", "slots": changed_slots}, ROSTER_IDS
	)
	assert_eq(changed.slots, changed_slots)
	assert_eq(original.slots, _slots(), "reducer must not mutate its input")
	var rejected: Dictionary = FormationReducerScript.set_formation(
		changed, {"front_1": "deleted", "front_2": "h2", "back_1": "h3", "back_2": "h1"}, ROSTER_IDS
	)
	assert_eq(rejected, changed)
