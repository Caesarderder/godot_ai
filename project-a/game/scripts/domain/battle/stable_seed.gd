class_name StableSeed
extends RefCounted

const DOMAIN := "battle-seed-v1"


static func battle_parts(
	content_version: String, stage_id: String, attempt: int, run_seed_token: String
) -> PackedStringArray:
	return PackedStringArray([DOMAIN, content_version, stage_id, str(attempt), run_seed_token])


static func sha256_hex(parts: PackedStringArray) -> String:
	return _digest(parts).hex_encode()


static func signed_seed(parts: PackedStringArray) -> int:
	var digest := _digest(parts)
	var little_endian := PackedByteArray()
	for index in range(7, -1, -1):
		little_endian.append(digest[index])
	return little_endian.decode_s64(0)


static func _digest(parts: PackedStringArray) -> PackedByteArray:
	var bytes := PackedByteArray()
	for field in parts:
		var encoded := field.to_utf8_buffer()
		var length := encoded.size()
		bytes.append((length >> 24) & 0xff)
		bytes.append((length >> 16) & 0xff)
		bytes.append((length >> 8) & 0xff)
		bytes.append(length & 0xff)
		bytes.append_array(encoded)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish()
