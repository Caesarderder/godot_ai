class_name CommandExecutor
extends RefCounted

const Registry := preload("res://game/scripts/commands/command_class_registry.gd")
const Fingerprint := preload("res://game/scripts/commands/command_fingerprint.gd")
const Result := preload("res://game/scripts/commands/command_result.gd")
const State := preload("res://game/scripts/state/game_state.gd")
const Ledger := preload("res://game/scripts/state/receipt_ledger.gd")
const Quests := preload("res://game/scripts/domain/quests/quest_reducer.gd")

class InternalGateway extends RefCounted:
	var _executor: RefCounted
	var _capability: RefCounted

	func _init(executor: RefCounted, capability: RefCounted) -> void:
		_executor = executor
		_capability = capability

	func execute_internal(
		command_type: StringName,
		payload: Dictionary,
		business_key: String = ""
	) -> Dictionary:
		return _executor._execute_internal_authorized(
			command_type, payload, business_key, _capability
		)

var _save_port: Variant
var _clock_port: Variant
var _state: Dictionary = {}
var _reducers: Dictionary = {}
var _internal_capability := RefCounted.new()


func configure(save_port: Variant, clock_port: Variant, initial_state: Dictionary) -> void:
	_save_port = save_port
	_clock_port = clock_port
	_state = State.clone(initial_state)
	if not _state.has("receipt_ledgers") or _state.receipt_ledgers.is_empty():
		_state.receipt_ledgers = Ledger.create_empty()


func register_reducer(command_type: StringName, reducer: Callable) -> void:
	if Registry.classify(command_type) != Registry.UNKNOWN:
		_reducers[command_type] = reducer


func current_state() -> Dictionary:
	return State.clone(_state)


func execute(envelope: Dictionary) -> Dictionary:
	return _execute(envelope, "")


func execute_internal(
	_command_type: StringName,
	_payload: Dictionary,
	_business_key: String = ""
) -> Dictionary:
	return Result.failure("INTERNAL_COMMAND_FORBIDDEN")


func _create_internal_gateway() -> RefCounted:
	return InternalGateway.new(self, _internal_capability)


func _execute_internal_authorized(
	command_type: StringName,
	payload: Dictionary,
	business_key: String,
	capability: RefCounted
) -> Dictionary:
	if capability != _internal_capability:
		return Result.failure("INTERNAL_COMMAND_FORBIDDEN")
	if not Registry.is_internal(command_type):
		return Result.failure("INTERNAL_COMMAND_REQUIRED")
	var now := _now_unix()
	var envelope := {
		"command_id": "%s:%d" % [command_type, now],
		"type": str(command_type),
		"payload": payload.duplicate(true),
		"business_key": business_key,
		"expected_revision": int(_state.get("revision", 0)),
		"requested_at": now,
	}
	return _execute(envelope, _internal_capability)


func _execute(envelope: Dictionary, capability: Variant) -> Dictionary:
	var envelope_error := _validate_envelope(envelope)
	if not envelope_error.is_empty():
		return Result.failure(envelope_error)
	var command_type := StringName(str(envelope.type))
	var command_class := Registry.classify(command_type)
	if command_class == Registry.UNKNOWN:
		return Result.failure("UNKNOWN_COMMAND")
	if command_class == Registry.INTERNAL_DURABLE and capability != _internal_capability:
		return Result.failure("INTERNAL_COMMAND_FORBIDDEN")
	if int(envelope.expected_revision) != int(_state.get("revision", 0)):
		return Result.failure("REVISION_MISMATCH")

	var fingerprint_result := Fingerprint.calculate(
		str(command_type), envelope.payload, str(envelope.business_key)
	)
	if not fingerprint_result.ok:
		return Result.failure(str(fingerprint_result.get("error", "INVALID_PAYLOAD")))
	var fingerprint := str(fingerprint_result.fingerprint)
	var replay := Ledger.lookup(
		_state,
		str(envelope.command_id),
		fingerprint,
		str(envelope.business_key)
	)
	if replay.status == Ledger.STATUS_MATCH:
		var prior: Dictionary = replay.receipt
		return Result.success(prior.get("result", {}), prior)
	if replay.status != Ledger.STATUS_MISS:
		return Result.failure(str(replay.status))

	if command_class == Registry.EPHEMERAL:
		return _execute_ephemeral(command_type, envelope.payload)

	var candidate := State.clone(_state)
	var reduction := _reduce(command_type, candidate, envelope.payload)
	if not reduction.get("ok", false):
		return Result.failure(str(reduction.get("code", "INVARIANT_FAILED")))
	var events: Array = reduction.get("events", [])
	if not events.is_empty():
		candidate.quest = Quests.reduce(candidate.get("quest", {}), events)

	var receipt := {
		"command_id": str(envelope.command_id),
		"fingerprint": fingerprint,
		"business_key": str(envelope.business_key),
		"result": Dictionary(reduction.get("result", {})).duplicate(true),
		"requested_at": int(envelope.requested_at),
		"command_type": str(command_type),
	}
	if command_class == Registry.REVERSIBLE_META:
		Ledger.record_reversible(candidate, receipt)
	else:
		Ledger.record_value(candidate, receipt)
	candidate.revision = int(_state.get("revision", 0)) + 1

	var validation := State.validate(candidate)
	if not validation.ok:
		return Result.failure("INVARIANT_FAILED", str(validation.code))
	if command_class == Registry.REVERSIBLE_META:
		_state = candidate
		return Result.success(receipt.result, receipt)

	var saved_at := _now_unix()
	candidate.saved_at_unix = saved_at
	var save_result: Dictionary = _save_port.save_candidate(candidate, saved_at)
	if not save_result.get("ok", false):
		return Result.failure("SAVE_FAILED", str(save_result.get("code", "")))
	_state = candidate
	return Result.success(receipt.result, receipt)


func _execute_ephemeral(command_type: StringName, payload: Dictionary) -> Dictionary:
	if not _reducers.has(command_type):
		return Result.success()
	var reduction: Dictionary = _reducers[command_type].call({}, payload)
	if not reduction.get("ok", false):
		return Result.failure(str(reduction.get("code", "INVARIANT_FAILED")))
	return Result.success(reduction.get("result", {}))


func _reduce(
	command_type: StringName,
	candidate: Dictionary,
	payload: Dictionary
) -> Dictionary:
	if _reducers.has(command_type):
		return _reducers[command_type].call(candidate, payload)
	if Registry.is_internal(command_type):
		return _reduce_internal(command_type, candidate, payload)
	return {"ok": false, "code": "MISSING_REDUCER"}


func _reduce_internal(
	command_type: StringName,
	candidate: Dictionary,
	payload: Dictionary
) -> Dictionary:
	var now := int(payload.get("now_unix", _now_unix()))
	var old_anchor := int(candidate.get("offline_anchor_unix", now))
	var effective_end := maxi(old_anchor, now)
	match command_type:
		&"__lifecycle_pause_anchor", &"__lifecycle_heartbeat_anchor":
			candidate["offline_anchor_unix"] = effective_end
			candidate["last_seen_wall_unix"] = maxi(
				int(candidate.get("last_seen_wall_unix", 0)), now
			)
			return {
				"ok": true,
				"result": {"anchor_unix": effective_end},
				"events": [],
			}
		&"__lifecycle_resume_settle":
			var elapsed := effective_end - old_anchor
			var credited := mini(elapsed, 8 * 60 * 60)
			candidate["economy"]["offline_seconds"] = (
				int(candidate["economy"].get("offline_seconds", 0)) + credited
			)
			candidate["offline_anchor_unix"] = effective_end
			candidate["last_seen_wall_unix"] = maxi(
				int(candidate.get("last_seen_wall_unix", 0)), now
			)
			candidate["last_settled_unix"] = maxi(
				int(candidate.get("last_settled_unix", 0)), effective_end
			)
			return {
				"ok": true,
				"result": {
					"elapsed_seconds": elapsed,
					"credited_seconds": credited,
				},
				"events": [],
			}
	return {"ok": false, "code": "UNKNOWN_COMMAND"}


func _validate_envelope(envelope: Dictionary) -> String:
	var required := [
		"command_id",
		"type",
		"payload",
		"business_key",
		"expected_revision",
		"requested_at",
	]
	for key: String in required:
		if not envelope.has(key):
			return "INVALID_ENVELOPE"
	if typeof(envelope.command_id) != TYPE_STRING or envelope.command_id.is_empty():
		return "INVALID_ENVELOPE"
	if typeof(envelope.type) != TYPE_STRING or envelope.type.is_empty():
		return "INVALID_ENVELOPE"
	if typeof(envelope.payload) != TYPE_DICTIONARY:
		return "INVALID_PAYLOAD"
	if typeof(envelope.business_key) != TYPE_STRING:
		return "INVALID_ENVELOPE"
	if typeof(envelope.expected_revision) != TYPE_INT:
		return "INVALID_ENVELOPE"
	if typeof(envelope.requested_at) != TYPE_INT:
		return "INVALID_ENVELOPE"
	return ""


func _now_unix() -> int:
	return int(_clock_port.unix_time_seconds())
