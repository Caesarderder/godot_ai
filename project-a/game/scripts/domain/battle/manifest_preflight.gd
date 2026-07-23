class_name BattleManifestPreflight
extends RefCounted

const GENERATOR_VERSION := "m5-preflight-v5"


static func file_sha256(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "missing artifact: %s" % path)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(file.get_buffer(file.get_length()))
	return context.finish().hex_encode()


static func verify_artifacts(manifest: Dictionary) -> bool:
	for path in manifest["artifact_hashes"]:
		if file_sha256(path) != manifest["artifact_hashes"][path]:
			return false
	return true
