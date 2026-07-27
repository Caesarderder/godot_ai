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
	"battle_input",
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
const FIRST_SESSION_MILESTONES: Array[String] = [
	"first_battle_started",
	"first_city_captured",
	"pressure_stage_cleared",
	"high_wall_failed",
	"foundational_signal",
	"research_lab_constructed",
	"counterattack_formation_ready",
	"counterattack_won",
	"resource_facility_constructed",
	"first_factory_output_claimed",
	"growth_chosen",
	"chapter_boss_defeated",
]

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
		return {
			"enabled": enabled,
			"event_count": 0,
			"duration_seconds": 0,
			"milestone_count": 0,
			"milestone_total": FIRST_SESSION_MILESTONES.size(),
		}
	var result := {
		"enabled": enabled,
		"event_count": (report.get("events", []) as Array).size(),
		"duration_seconds": maxi(0, _now(now_unix) - int(report.get("started_at_unix", 0))),
		"started_at_unix": int(report.get("started_at_unix", 0)),
		"product_version": String(report.get("product_version", "")),
	}
	var metrics := _derive_first_session_metrics()
	result["milestone_count"] = int(metrics.get("milestone_count", 0))
	result["milestone_total"] = int(metrics.get("milestone_total", FIRST_SESSION_MILESTONES.size()))
	result["longest_non_battle_gap_seconds"] = int(metrics.get("longest_non_battle_gap_seconds", 0))
	result["longest_manual_battle_input_gap_seconds"] = int(
		metrics.get("longest_manual_battle_input_gap_seconds", 0)
	)
	result["max_navigation_only_streak"] = int(metrics.get("max_navigation_only_streak", 0))
	return result


func export_report(now_unix: int = -1) -> Dictionary:
	if report.is_empty():
		return {"ok": false, "error": "PLAYTEST_REPORT_EMPTY"}
	var exported := report.duplicate(true)
	exported["duration_seconds"] = maxi(0, _now(now_unix) - int(exported.get("started_at_unix", 0)))
	exported["event_count"] = (exported.get("events", []) as Array).size()
	exported["first_session_metrics"] = _derive_first_session_metrics()
	exported["evidence_limit"] = (
		"Derived events can locate funnel loss and friction; only observed behavior and a neutral "
		+ "post-session interview can establish comprehension or desire to continue."
	)
	var text := JSON.stringify(exported, "\t", true)
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return {"ok": false, "error": "PLAYTEST_REPORT_TOO_LARGE"}
	return {"ok": true, "text": text, "summary": summary(now_unix)}


func _derive_first_session_metrics() -> Dictionary:
	var completed: Array[String] = []
	var milestone_seconds: Dictionary = {}
	var battle_attempts: Dictionary = {}
	var failed_command_count := 0
	var longest_non_battle_gap := 0
	var longest_manual_battle_input_gap := 0
	var manual_battle_input_count := 0
	var successful_manual_skill_count := 0
	var rejected_manual_skill_count := 0
	var manual_inputs_by_stage: Dictionary = {}
	var active_battle_stage := ""
	var manual_battle_active := false
	var manual_battle_last_input_elapsed := -1
	var navigation_streak := 0
	var max_navigation_streak := 0
	var in_battle := false
	var previous_event: Dictionary = {}
	for event_value in report.get("events", []):
		var event := event_value as Dictionary
		var event_type := String(event.get("event_type", ""))
		var details := event.get("details", {}) as Dictionary
		var elapsed := int(event.get("elapsed_seconds", 0))
		if not previous_event.is_empty():
			if not in_battle:
				longest_non_battle_gap = maxi(
					longest_non_battle_gap,
					elapsed - int(previous_event.get("elapsed_seconds", elapsed))
				)
		if event_type == "screen_view":
			navigation_streak += 1
			max_navigation_streak = maxi(max_navigation_streak, navigation_streak)
		else:
			navigation_streak = 0
		if event_type == "command_result" and not bool(details.get("ok", false)):
			failed_command_count += 1
		if event_type == "battle_started":
			in_battle = true
			var started_stage := String(details.get("stage_id", ""))
			active_battle_stage = started_stage
			manual_battle_active = bool(details.get("manual_skills", false))
			manual_battle_last_input_elapsed = elapsed if manual_battle_active else -1
			battle_attempts[started_stage] = int(battle_attempts.get(started_stage, 0)) + 1
			if started_stage == "stage_1_1":
				_mark_milestone("first_battle_started", elapsed, completed, milestone_seconds)
			if (
				started_stage == "stage_1_4"
				and completed.has("high_wall_failed")
				and int(details.get("deployed_heroes", 0)) >= 3
			):
				_mark_milestone(
					"counterattack_formation_ready",
					elapsed,
					completed,
					milestone_seconds
				)
		elif event_type == "battle_input":
			var action := String(details.get("action", ""))
			if action == "resume":
				manual_battle_active = bool(details.get("manual_skills", true))
				manual_battle_last_input_elapsed = elapsed if manual_battle_active else -1
			elif action == "skill_mode":
				if manual_battle_active and manual_battle_last_input_elapsed >= 0:
					longest_manual_battle_input_gap = maxi(
						longest_manual_battle_input_gap,
						elapsed - manual_battle_last_input_elapsed
					)
				manual_battle_active = bool(details.get("manual_skills", false))
				manual_battle_last_input_elapsed = elapsed if manual_battle_active else -1
			elif action == "pause":
				if manual_battle_active and manual_battle_last_input_elapsed >= 0:
					longest_manual_battle_input_gap = maxi(
						longest_manual_battle_input_gap,
						elapsed - manual_battle_last_input_elapsed
					)
				manual_battle_active = false
				manual_battle_last_input_elapsed = -1
			elif action in ["skill", "retreat"] and manual_battle_active:
				if manual_battle_last_input_elapsed >= 0:
					longest_manual_battle_input_gap = maxi(
						longest_manual_battle_input_gap,
						elapsed - manual_battle_last_input_elapsed
					)
				manual_battle_last_input_elapsed = elapsed
				manual_battle_input_count += 1
				if not active_battle_stage.is_empty():
					manual_inputs_by_stage[active_battle_stage] = (
						int(manual_inputs_by_stage.get(active_battle_stage, 0)) + 1
					)
				if action == "skill":
					if bool(details.get("accepted", false)):
						successful_manual_skill_count += 1
					else:
						rejected_manual_skill_count += 1
		elif event_type == "battle_finished":
			if manual_battle_active and manual_battle_last_input_elapsed >= 0:
				longest_manual_battle_input_gap = maxi(
					longest_manual_battle_input_gap,
					elapsed - manual_battle_last_input_elapsed
				)
			manual_battle_active = false
			manual_battle_last_input_elapsed = -1
			active_battle_stage = ""
			in_battle = false
			var stage_id := String(details.get("stage_id", ""))
			var outcome := String(details.get("outcome", ""))
			if stage_id == "stage_1_1" and outcome == "victory":
				_mark_milestone("first_city_captured", elapsed, completed, milestone_seconds)
			elif stage_id == "stage_1_3" and outcome == "victory":
				_mark_milestone("pressure_stage_cleared", elapsed, completed, milestone_seconds)
			elif stage_id == "stage_1_4" and outcome != "victory":
				_mark_milestone("high_wall_failed", elapsed, completed, milestone_seconds)
			elif (
				stage_id == "stage_1_4"
				and outcome == "victory"
				and completed.has("high_wall_failed")
			):
				_mark_milestone("counterattack_won", elapsed, completed, milestone_seconds)
			elif stage_id == "stage_1_5" and outcome == "victory":
				_mark_milestone("chapter_boss_defeated", elapsed, completed, milestone_seconds)
		elif event_type == "command_result" and bool(details.get("ok", false)):
			var command_type := String(details.get("command_type", ""))
			if (
				command_type == "construct_facility"
				and completed.has("high_wall_failed")
				and not completed.has("research_lab_constructed")
			):
				_mark_milestone("research_lab_constructed", elapsed, completed, milestone_seconds)
			elif (
				command_type == "claim_foundational_signal"
				and completed.has("high_wall_failed")
			):
				_mark_milestone("foundational_signal", elapsed, completed, milestone_seconds)
			elif (
				command_type == "construct_facility"
				and completed.has("counterattack_won")
			):
				_mark_milestone(
					"resource_facility_constructed",
					elapsed,
					completed,
					milestone_seconds
				)
			elif (
				command_type == "claim_factory_output"
				and completed.has("resource_facility_constructed")
			):
				_mark_milestone(
					"first_factory_output_claimed",
					elapsed,
					completed,
					milestone_seconds
				)
			elif (
				command_type == "upgrade_hero_star"
				and completed.has("first_factory_output_claimed")
			):
				_mark_milestone("growth_chosen", elapsed, completed, milestone_seconds)
		previous_event = event
	var repeated_battles := 0
	for attempts_value in battle_attempts.values():
		repeated_battles += maxi(0, int(attempts_value) - 1)
	var milestone_intervals: Dictionary = {}
	var previous_milestone := ""
	for milestone_id in FIRST_SESSION_MILESTONES:
		if not milestone_seconds.has(milestone_id):
			continue
		var milestone_elapsed := int(milestone_seconds[milestone_id])
		milestone_intervals[milestone_id] = (
			milestone_elapsed
			if previous_milestone.is_empty()
			else milestone_elapsed - int(milestone_seconds[previous_milestone])
		)
		previous_milestone = milestone_id
	var next_milestone := ""
	for milestone_id in FIRST_SESSION_MILESTONES:
		if not completed.has(milestone_id):
			next_milestone = milestone_id
			break
	return {
		"milestone_count": completed.size(),
		"milestone_total": FIRST_SESSION_MILESTONES.size(),
		"completed_milestones": completed,
		"milestone_elapsed_seconds": milestone_seconds,
		"milestone_intervals_seconds": milestone_intervals,
		"next_missing_milestone": next_milestone,
		"first_meaningful_input_seconds": int(milestone_seconds.get("first_battle_started", -1)),
		"longest_non_battle_gap_seconds": longest_non_battle_gap,
		"has_90_second_non_battle_gap": longest_non_battle_gap >= 90,
		"longest_manual_battle_input_gap_seconds": longest_manual_battle_input_gap,
		"has_90_second_manual_battle_input_gap": longest_manual_battle_input_gap >= 90,
		"manual_battle_input_count": manual_battle_input_count,
		"successful_manual_skill_count": successful_manual_skill_count,
		"rejected_manual_skill_count": rejected_manual_skill_count,
		"manual_inputs_by_stage": manual_inputs_by_stage,
		"max_navigation_only_streak": max_navigation_streak,
		"failed_command_count": failed_command_count,
		"battle_attempts": battle_attempts,
		"repeated_battle_count": repeated_battles,
		"chapter_loop_completed": completed.has("chapter_boss_defeated"),
	}


func _mark_milestone(
	milestone_id: String,
	elapsed: int,
	completed: Array[String],
	milestone_seconds: Dictionary
) -> void:
	if completed.has(milestone_id):
		return
	completed.append(milestone_id)
	milestone_seconds[milestone_id] = elapsed


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
	if event_type == "battle_input":
		return false
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
