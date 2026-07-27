extends RefCounted


func run(_tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var encoded := TemplateSaveEnvelope.encode({"score": 10})
    var decoded := TemplateSaveEnvelope.decode(encoded)
    if not decoded.get("ok", false) or decoded.get("payload", {}).get("score") != 10:
        failures.append("valid envelope did not round-trip")
    var rejected := TemplateSaveEnvelope.decode({"version": 0, "payload": {}})
    if rejected.get("ok", true) or rejected.get("error") != "unsupported_version":
        failures.append("unsupported version did not fail explicitly")
    return failures
