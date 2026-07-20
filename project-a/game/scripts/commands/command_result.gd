class_name CommandResult
extends RefCounted


static func success(result: Dictionary = {}, receipt: Dictionary = {}) -> Dictionary:
	return {
		"ok": true,
		"code": "OK",
		"result": result.duplicate(true),
		"receipt": receipt.duplicate(true),
	}


static func failure(code: String, detail: String = "") -> Dictionary:
	return {"ok": false, "code": code, "detail": detail}
