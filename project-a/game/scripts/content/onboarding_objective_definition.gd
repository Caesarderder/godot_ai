class_name OnboardingObjectiveDefinition
extends Resource

const VALID_EVENT_TYPES: Array[String] = [
	"battle_settled",
	"foundational_signal_resolved",
	"foundational_blueprint_unlocked",
	"facility_constructed",
	"factory_output_claimed",
	"hero_star_upgraded",
	"permanent_hero_star_upgraded",
]
const VALID_TARGETS: Array[String] = ["expedition", "research", "factory", "legion"]

@export var objective_id: StringName
@export var label: String = ""
@export var event_type: StringName
@export var event_types: PackedStringArray = PackedStringArray()
@export var stage_id: StringName
@export var outcome: String = ""
@export var facility_ids: PackedStringArray = PackedStringArray()
@export var archetype_ids: PackedStringArray = PackedStringArray()
@export var recipe_id: StringName
@export_enum("expedition", "research", "factory", "legion") var target: String = "expedition"
@export var stage_target: StringName
@export var cta_label: String = ""


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var id := String(objective_id)
	if id.is_empty():
		errors.append("objective_id is required")
	if label.strip_edges().is_empty():
		errors.append("%s label is required" % id)
	if cta_label.strip_edges().is_empty():
		errors.append("%s cta_label is required" % id)
	if not VALID_TARGETS.has(target):
		errors.append("%s target is invalid: %s" % [id, target])
	var accepted_types := _accepted_event_types()
	if accepted_types.is_empty():
		errors.append("%s requires one or more event types" % id)
	for accepted_type in accepted_types:
		if not VALID_EVENT_TYPES.has(accepted_type):
			errors.append("%s event type is invalid: %s" % [id, accepted_type])
	if not String(event_type).is_empty() and not event_types.is_empty():
		errors.append("%s must use event_type or event_types, not both" % id)
	if accepted_types.has("battle_settled"):
		if String(stage_id).is_empty() or not ["victory", "defeat"].has(outcome):
			errors.append("%s battle objective requires stage_id and outcome" % id)
		if String(stage_target) != String(stage_id):
			errors.append("%s battle stage_target must match stage_id" % id)
	if accepted_types.has("facility_constructed") and facility_ids.is_empty():
		errors.append("%s facility objective requires facility_ids" % id)
	if (
		accepted_types.has("hero_star_upgraded")
		or accepted_types.has("permanent_hero_star_upgraded")
	) and archetype_ids.is_empty():
		errors.append("%s growth objective requires archetype_ids" % id)
	return errors


func to_view() -> Dictionary:
	var view := {
		"id": String(objective_id),
		"label": label,
		"target": target,
		"cta_label": cta_label,
	}
	if not String(event_type).is_empty():
		view["event_type"] = String(event_type)
	if not event_types.is_empty():
		view["event_types"] = Array(event_types)
	if not String(stage_id).is_empty():
		view["stage_id"] = String(stage_id)
	if not outcome.is_empty():
		view["outcome"] = outcome
	if not facility_ids.is_empty():
		view["facility_ids"] = Array(facility_ids)
	if not archetype_ids.is_empty():
		view["archetype_ids"] = Array(archetype_ids)
	if not String(recipe_id).is_empty():
		view["recipe_id"] = String(recipe_id)
	if not String(stage_target).is_empty():
		view["stage_target"] = String(stage_target)
	return view


func _accepted_event_types() -> Array[String]:
	var accepted: Array[String] = []
	if not String(event_type).is_empty():
		accepted.append(String(event_type))
	for value in event_types:
		accepted.append(String(value))
	return accepted
