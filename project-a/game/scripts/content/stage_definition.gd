class_name StageDefinition
extends Resource

@export var stage_id: StringName
@export_range(1, 99, 1) var chapter: int = 1
@export_range(1, 99, 1) var stage_in_chapter: int = 1
@export var display_name: String = ""
@export_range(1, 1000000, 1) var recommended_power: int = 1
@export_range(1000, 100000, 50) var enemy_power_bp: int = 10000
@export_range(1000, 100000, 50) var solo_pressure_bp: int = 10000
@export_range(1000, 20000, 50) var structure_hp_bp: int = 10000
@export_multiline var threat_summary: String = ""
@export_multiline var counter_hint: String = ""


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(stage_id).is_empty():
		errors.append("stage_id is required")
	if chapter <= 0 or stage_in_chapter <= 0:
		errors.append("%s chapter coordinates must be positive" % String(stage_id))
	var expected_id := "stage_%d_%d" % [chapter, stage_in_chapter]
	if not String(stage_id).is_empty() and String(stage_id) != expected_id:
		errors.append("%s does not match chapter coordinates %s" % [String(stage_id), expected_id])
	if display_name.strip_edges().is_empty():
		errors.append("%s display_name is required" % String(stage_id))
	if recommended_power <= 0:
		errors.append("%s recommended_power must be positive" % String(stage_id))
	if enemy_power_bp <= 0 or solo_pressure_bp <= 0 or structure_hp_bp <= 0:
		errors.append("%s basis-point tuning must be positive" % String(stage_id))
	if threat_summary.strip_edges().is_empty():
		errors.append("%s threat_summary is required" % String(stage_id))
	if counter_hint.strip_edges().is_empty():
		errors.append("%s counter_hint is required" % String(stage_id))
	return errors
