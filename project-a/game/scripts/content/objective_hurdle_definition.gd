class_name ObjectiveHurdleDefinition
extends Resource

const VALID_SCALES: Array[String] = ["小坎", "中坎", "大坎"]

@export var task_id: StringName
@export_enum("小坎", "中坎", "大坎") var scale: String = "小坎"
@export var title: String = ""
@export_multiline var reason: String = ""
@export_multiline var recovery: String = ""


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var id := String(task_id)
	if id.is_empty():
		errors.append("task_id is required")
	elif not id.begins_with("operation."):
		errors.append("%s task_id must use the operation namespace" % id)
	if not VALID_SCALES.has(scale):
		errors.append("%s scale is invalid: %s" % [id, scale])
	if title.strip_edges().is_empty():
		errors.append("%s title is required" % id)
	if reason.strip_edges().is_empty():
		errors.append("%s reason is required" % id)
	if recovery.strip_edges().is_empty():
		errors.append("%s recovery is required" % id)
	return errors
