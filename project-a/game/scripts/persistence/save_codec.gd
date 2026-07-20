class_name SaveCodec
extends RefCounted

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const SaveMigrationsScript := preload("res://game/scripts/persistence/save_migrations.gd")


static func encode(state: Dictionary) -> String:
	var validation := GameStateScript.validate(state)
	if not validation.ok:
		return ""
	return JSON.stringify(state, "", true, false)


static func decode(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return _failure("INVALID_JSON")
	if typeof(json.data) != TYPE_DICTIONARY:
		return _failure("INVALID_ROOT")
	var normalized: Variant = _normalize_json_value(json.data)
	if typeof(normalized) != TYPE_DICTIONARY:
		return _failure("INVALID_VALUE")
	var state := SaveMigrationsScript.to_current(normalized)
	if state.is_empty():
		return _failure("UNSUPPORTED_SCHEMA")
	var validation := GameStateScript.validate(state)
	if not validation.ok:
		return _failure(validation.code)
	return { "ok": true, "state": state, "code": "OK" }


static func _failure(code: String) -> Dictionary:
	return { "ok": false, "state": { }, "code": code }


static func _normalize_json_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			return int(value) if is_finite(value) and floor(value) == value else value
		TYPE_ARRAY:
			var normalized_array: Array = []
			for item: Variant in value:
				normalized_array.append(_normalize_json_value(item))
			return normalized_array
		TYPE_DICTIONARY:
			var normalized_dictionary := { }
			for key: Variant in value:
				normalized_dictionary[key] = _normalize_json_value(value[key])
			return normalized_dictionary
		_:
			return value
