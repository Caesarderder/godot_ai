class_name TemplateSaveEnvelope
extends RefCounted

const CURRENT_VERSION: int = 1


static func encode(payload: Dictionary) -> Dictionary:
    return {
        "version": CURRENT_VERSION,
        "payload": payload.duplicate(true),
    }


static func decode(value: Variant) -> Dictionary:
    if not value is Dictionary:
        return {"ok": false, "error": "not_dictionary", "payload": {}}
    var envelope: Dictionary = value
    if envelope.get("version", -1) != CURRENT_VERSION:
        return {"ok": false, "error": "unsupported_version", "payload": {}}
    var payload: Variant = envelope.get("payload")
    if not payload is Dictionary:
        return {"ok": false, "error": "invalid_payload", "payload": {}}
    return {"ok": true, "error": "", "payload": payload.duplicate(true)}
