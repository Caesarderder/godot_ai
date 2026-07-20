class_name CommandFingerprint
extends RefCounted

const INVALID_PAYLOAD := "INVALID_PAYLOAD"


static func canonical_json(value: Variant) -> Dictionary:
	var encoded := _encode(value)
	if not encoded["ok"]:
		return {"ok": false, "error": INVALID_PAYLOAD}
	return {"ok": true, "value": encoded["value"]}


static func calculate(
	command_type: String, payload: Variant, business_key: String
) -> Dictionary:
	var canonical := canonical_json(payload)
	if not canonical["ok"]:
		return canonical
	var bytes := PackedByteArray()
	_append_length_prefixed(bytes, command_type)
	_append_length_prefixed(bytes, canonical["value"])
	_append_length_prefixed(bytes, business_key)
	var hashing := HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK:
		return {"ok": false, "error": "HASH_FAILED"}
	if hashing.update(bytes) != OK:
		return {"ok": false, "error": "HASH_FAILED"}
	return {
		"ok": true,
		"canonical_payload": canonical["value"],
		"fingerprint": hashing.finish().hex_encode(),
	}


static func _encode(value: Variant) -> Dictionary:
	match typeof(value):
		TYPE_NIL:
			return {"ok": true, "value": "null"}
		TYPE_BOOL:
			return {"ok": true, "value": "true" if value else "false"}
		TYPE_INT:
			return {"ok": true, "value": str(value)}
		TYPE_STRING:
			return {"ok": true, "value": JSON.stringify(value)}
		TYPE_ARRAY:
			return _encode_array(value)
		TYPE_DICTIONARY:
			return _encode_dictionary(value)
		_:
			return {"ok": false}


static func _encode_array(values: Array) -> Dictionary:
	var parts: Array[String] = []
	for value: Variant in values:
		var encoded := _encode(value)
		if not encoded["ok"]:
			return {"ok": false}
		parts.append(encoded["value"])
	return {"ok": true, "value": "[" + ",".join(parts) + "]"}


static func _encode_dictionary(values: Dictionary) -> Dictionary:
	var keys: Array[String] = []
	for key: Variant in values:
		if typeof(key) != TYPE_STRING:
			return {"ok": false}
		keys.append(key)
	_sort_utf8(keys)
	var parts: Array[String] = []
	for key: String in keys:
		var encoded := _encode(values[key])
		if not encoded["ok"]:
			return {"ok": false}
		parts.append(JSON.stringify(key) + ":" + encoded["value"])
	return {"ok": true, "value": "{" + ",".join(parts) + "}"}


static func _sort_utf8(keys: Array[String]) -> void:
	for index: int in range(1, keys.size()):
		var key := keys[index]
		var insertion_index := index
		while insertion_index > 0 and _utf8_less(key, keys[insertion_index - 1]):
			keys[insertion_index] = keys[insertion_index - 1]
			insertion_index -= 1
		keys[insertion_index] = key


static func _utf8_less(left: String, right: String) -> bool:
	var left_bytes := left.to_utf8_buffer()
	var right_bytes := right.to_utf8_buffer()
	var shared_length := mini(left_bytes.size(), right_bytes.size())
	for index: int in shared_length:
		if left_bytes[index] != right_bytes[index]:
			return left_bytes[index] < right_bytes[index]
	return left_bytes.size() < right_bytes.size()


static func _append_length_prefixed(target: PackedByteArray, value: String) -> void:
	var encoded := value.to_utf8_buffer()
	var length := encoded.size()
	target.append((length >> 24) & 0xff)
	target.append((length >> 16) & 0xff)
	target.append((length >> 8) & 0xff)
	target.append(length & 0xff)
	target.append_array(encoded)
