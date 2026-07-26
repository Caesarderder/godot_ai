class_name ActiveSkillDefinition
extends Resource

@export var skill_id: StringName
@export var archetype_id: StringName
@export var display_name: String = ""
@export var short_label: String = ""
@export_multiline var role_copy: String = ""
@export_multiline var effect_copy: String = ""
@export_multiline var timing_copy: String = ""


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(skill_id).is_empty():
		errors.append("skill_id is required")
	if String(archetype_id).is_empty():
		errors.append("%s archetype_id is required" % String(skill_id))
	if display_name.strip_edges().is_empty():
		errors.append("%s display_name is required" % String(skill_id))
	if short_label.strip_edges().is_empty() or short_label.length() > 2:
		errors.append("%s short_label must contain one or two characters" % String(skill_id))
	if role_copy.strip_edges().is_empty():
		errors.append("%s role_copy is required" % String(skill_id))
	if effect_copy.strip_edges().is_empty():
		errors.append("%s effect_copy is required" % String(skill_id))
	if timing_copy.strip_edges().is_empty():
		errors.append("%s timing_copy is required" % String(skill_id))
	return errors
