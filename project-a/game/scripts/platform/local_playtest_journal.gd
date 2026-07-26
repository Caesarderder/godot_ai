class_name LocalPlaytestJournal
extends RefCounted

const REPORT_PATH: String = "user://local_playtest_session.json"
const SCHEMA_VERSION: int = 1
const MAX_EVENTS: int = 256
const MAX_BYTES: int = 256 * 1024
const ALLOWED_EVENT_TYPES: Array[String] = [
	"session_started",
	"screen_view",
	"command_result",
	"battle_started",
	"battle_finished",
]
const ROOT_KEYS: Array[String] = [
	"schema_version",
	"product_version",
	"session_id",
	"started_at_unix",
	"last_event_at_unix",
	"privacy_notice",
	"events",
]
const EVENT_KEYS: Array[String] = ["sequence", "elapsed_seconds", "event_type", "details"]

var report_path: String = REPORT_PATH
var enabled: bool = false
var report: Dictionary = {}


func _init(path: String = REPORT_PATH) -> void:
	report_path = path


func set_enabled(value: bool, product_version: String, now_unix: int = -1) -> bool:
	enabled = value
	if not enabled:
		report.clear()
		return clear()
	var now := _now(now_unix)
	if _load_existing(product_version):
		return true
	report = _new_report(product_version, now)
	_append_event("session_started", {"reason": "opt_in"}, now)
	return _save()


func record_event(event_type: String, details: Dictionary = {}, now_unix: int = -1) -> bool:
	if not enabled or not ALLOWED_EVENT_TYPES.has(event_type):
		return false
	if report.is_empty():
		return false
	var sanitized := _sanitize_details(details)
	if not bool(sanitized.get("ok", false)):
		return false
	var clean_details := sanitized.get("details", {}) as Dictionary
	if _is_duplicate_tail(event_type, clean_details):
		return true
	var now := maxi(_now(now_unix), int(report.get("last_event_at_unix", 0)))
	_append_event(event_type, clean_details, now)
	var events := report.get("events", []) as Array
	while events.size() > MAX_EVENTS:
		events.pop_front()
		for index in events.size():
			(events[index] as Dictionary)["sequence"] = index + 1
	report["events"] = events
	return _save()


func summary(now_unix: int = -1) -> Dictionary:
	if report.is_empty():
		return {"enabled": enabled, "event_count": 0, "duration_seconds": 0}
	return {
		"enabled": enabled,
		"event_count": (report.get("events", []) as Array).size(),
		"duration_seconds": maxi(0, _now(now_unix) - int(report.get("started_at_unix", 0))),
		"started_at_unix": int(report.get("started_at_unix", 0)),
		"product_version": String(report.get("product_version", "")),
	}


func export_report(now_unix: int = -1) -> Dictionary:
	if report.is_empty():
		return {"ok": false, "error": "PLAYTEST_REPORT_EMPTY"}
	var exported := report.duplicate(true)
	exported["duration_seconds"] = maxi(0, _now(now_unix) - int(exported.get("started_at_unix", 0)))
	exported["event_count"] = (exported.get("events", []) as Array).size()
	var text := JSON.stringify(exported, "\t", true)
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return {"ok": false, "error": "PLAYTEST_REPORT_TOO_LARGE"}
	return {"ok": true, "text": text, "summary": summary(now_unix)}


func clear() -> bool:
	var ok := true
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = report_path + String(suffix)
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
			ok = false
	report.clear()
	return ok


func _load_existing(product_version: String) -> bool:
	if not FileAccess.file_exists(report_path):
		return false
	var file := FileAccess.open(report_path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		if file != null:
			file.close()
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var normalized := _normalize_json_numbers(parsed)
	if not bool(normalized.get("ok", false)):
		return false
	var candidate := normalized.get("value", {}) as Dictionary
	if not _validate_report(candidate) or String(candidate.get("product_version", "")) != product_version:
		return false
	report = candidate.duplicate(true)
	return true


func _new_report(product_version: String, now_unix: int) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"product_version": product_version,
		"session_id": "local-%d-%d" % [now_unix, Time.get_ticks_msec()],
		"started_at_unix": now_unix,
		"last_event_at_unix": now_unix,
		"privacy_notice": "Opt-in local playtest events only. No network transmission or device identifier.",
		"events": [],
	}


func _append_event(event_type: String, details: Dictionary, now_unix: int) -> void:
	var events := report.get("events", []) as Array
	events.append({
		"sequence": events.size() + 1,
		"elapsed_seconds": maxi(0, now_unix - int(report.get("started_at_unix", now_unix))),
		"event_type": event_type,
		"details": details.duplicate(true),
	})
	report["events"] = events
	report["last_event_at_unix"] = now_unix


func _is_duplicate_tail(event_type: String, details: Dictionary) -> bool:
	var events := report.get("events", []) as Array
	if events.is_empty():
		return false
	var tail := events[-1] as Dictionary
	return String(tail.get("event_type", "")) == event_type and (tail.get("details", {}) as Dictionary) == details


func _sanitize_details(details: Dictionary) -> Dictionary:
	if details.size() > 8:
		return {"ok": false}
	var clean: Dictionary = {}
	for key_value in details.keys():
		if typeof(key_value) != TYPE_STRING:
			return {"ok": false}
		var key := String(key_value)
		if key.is_empty() or key.length() > 40:
			return {"ok": false}
		var value: Variant = details[key_value]
		if typeof(value) not in [TYPE_BOOL, TYPE_INT, TYPE_STRING]:
			return {"ok": false}
		if typeof(value) == TYPE_STRING and String(value).length() > 80:
			return {"ok": false}
		clean[key] = value
	return {"ok": true, "details": clean}


func _validate_report(candidate: Dictionary) -> bool:
	if _sorted_keys(candidate) != _sorted_strings(ROOT_KEYS):
		return false
	if int(candidate.get("schema_version", 0)) != SCHEMA_VERSION:
		return false
	if typeof(candidate.get("product_version")) != TYPE_STRING:
		return false
	if typeof(candidate.get("session_id")) != TYPE_STRING or String(candidate["session_id"]).length() > 80:
		return false
	for key in ["started_at_unix", "last_event_at_unix"]:
		if typeof(candidate.get(key)) != TYPE_INT or int(candidate[key]) < 0:
			return false
	if typeof(candidate.get("privacy_notice")) != TYPE_STRING:
		return false
	if typeof(candidate.get("events")) != TYPE_ARRAY:
		return false
	var events := candidate["events"] as Array
	if events.size() > MAX_EVENTS:
		return false
	for index in events.size():
		if typeof(events[index]) != TYPE_DICTIONARY:
			return false
		var event := events[index] as Dictionary
		if _sorted_keys(event) != _sorted_strings(EVENT_KEYS):
			return false
		if int(event.get("sequence", 0)) != index + 1:
			return false
		if typeof(event.get("elapsed_seconds")) != TYPE_INT or int(event["elapsed_seconds"]) < 0:
			return false
		if typeof(event.get("event_type")) != TYPE_STRING or not ALLOWED_EVENT_TYPES.has(String(event["event_type"])):
			return false
		if typeof(event.get("details")) != TYPE_DICTIONARY or not bool(_sanitize_details(event["details"]).get("ok", false)):
			return false
	return true


func _save() -> bool:
	if not _validate_report(report):
		return false
	var text := JSON.stringify(report, "\t", true)
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return false
	var tmp_path := report_path + ".tmp"
	var bak_path := report_path + ".bak"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	file.close()
	if FileAccess.file_exists(report_path):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		if DirAccess.rename_absolute(report_path, bak_path) != OK:
			DirAccess.remove_absolute(tmp_path)
			return false
	if DirAccess.rename_absolute(tmp_path, report_path) == OK:
		return true
	if FileAccess.file_exists(bak_path) and not FileAccess.file_exists(report_path):
		DirAccess.rename_absolute(bak_path, report_path)
	return false


func _sorted_keys(value: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key in value.keys():
		if typeof(key) != TYPE_STRING:
			return []
		keys.append(String(key))
	keys.sort()
	return keys


func _sorted_strings(values: Array[String]) -> Array[String]:
	var copy := values.duplicate()
	copy.sort()
	return copy


func _normalize_json_numbers(value: Variant) -> Dictionary:
	match typeof(value):
		TYPE_FLOAT:
			var number := float(value)
			if number != floorf(number):
				return {"ok": false}
			return {"ok": true, "value": int(number)}
		TYPE_ARRAY:
			var array: Array = []
			for item in value:
				var normalized := _normalize_json_numbers(item)
				if not bool(normalized.get("ok", false)):
					return normalized
				array.append(normalized["value"])
			return {"ok": true, "value": array}
		TYPE_DICTIONARY:
			var dictionary: Dictionary = {}
			for key in (value as Dictionary).keys():
				if typeof(key) != TYPE_STRING:
					return {"ok": false}
				var normalized := _normalize_json_numbers((value as Dictionary)[key])
				if not bool(normalized.get("ok", false)):
					return normalized
				dictionary[key] = normalized["value"]
			return {"ok": true, "value": dictionary}
		_:
			return {"ok": true, "value": value}


func _now(value: int) -> int:
	return value if value >= 0 else int(Time.get_unix_time_from_system())
