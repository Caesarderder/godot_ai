class_name CommandFingerprint
extends RefCounted


static func build(command_type: String, payload: Variant, business_key: String) -> Dictionary:
	var validation_error := validate_canonical_value(payload)
	if not validation_error.is_empty():
		return {"ok": false, "error": validation_error}
	var canonical_payload := canonical_json(payload)
	var bytes := PackedByteArray()
	bytes.append_array(_length_prefixed(command_type))
	bytes.append_array(_length_prefixed(canonical_payload))
	bytes.append_array(_length_prefixed(business_key))
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return {
		"ok": true,
		"canonical_payload": canonical_payload,
		"fingerprint": ctx.finish().hex_encode(),
	}


static func validate_canonical_value(value: Variant) -> String:
	var type_id := typeof(value)
	match type_id:
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return ""
		TYPE_ARRAY:
			for item in value:
				var item_error := validate_canonical_value(item)
				if not item_error.is_empty():
					return item_error
			return ""
		TYPE_DICTIONARY:
			var dict := value as Dictionary
			for key in dict.keys():
				if typeof(key) != TYPE_STRING:
					return "canonical payload dictionary keys must be strings"
				var child_error := validate_canonical_value(dict[key])
				if not child_error.is_empty():
					return child_error
			return ""
		_:
			return "canonical payload rejects type %s" % type_string(type_id)


static func canonical_json(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "true" if bool(value) else "false"
		TYPE_INT:
			return str(int(value))
		TYPE_STRING:
			return JSON.stringify(String(value))
		TYPE_ARRAY:
			var parts: Array[String] = []
			for item in value:
				parts.append(canonical_json(item))
			return "[" + ",".join(parts) + "]"
		TYPE_DICTIONARY:
			var dict := value as Dictionary
			var keys: Array[String] = []
			for key in dict.keys():
				keys.append(String(key))
			keys.sort()
			var dict_parts: Array[String] = []
			for key in keys:
				dict_parts.append("%s:%s" % [JSON.stringify(key), canonical_json(dict[key])])
			return "{" + ",".join(dict_parts) + "}"
		_:
			return ""


static func _length_prefixed(text: String) -> PackedByteArray:
	var data := text.to_utf8_buffer()
	var size := data.size()
	var result := PackedByteArray([
		(size >> 24) & 255,
		(size >> 16) & 255,
		(size >> 8) & 255,
		size & 255,
	])
	result.append_array(data)
	return result
