# Defensive version migration

Run migrations only after the loader has confirmed that the root is a dictionary and `version` is an integer-valued number in the supported range. Migrate a deep duplicate, never live scene state.

```gdscript
func _migrate(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	var version := int(data.get("version", -1))

	while version < CURRENT_VERSION:
		var migrated := false
		match version:
			1:
				migrated = _migrate_v1_to_v2(data)
			2:
				migrated = _migrate_v2_to_v3(data)
			_:
				push_error("No migration from save version %s" % version)
				return {}
		if not migrated:
			push_error("Invalid schema while migrating version %s" % version)
			return {}
		version += 1
		data["version"] = version

	return data


func _migrate_v1_to_v2(data: Dictionary) -> bool:
	if not data.has("player") or typeof(data.player) != TYPE_DICTIONARY:
		return false
	var player := data.player as Dictionary
	if not player.has("inventory"):
		player["inventory"] = []
	elif typeof(player.inventory) != TYPE_ARRAY:
		return false
	return true


func _migrate_v2_to_v3(data: Dictionary) -> bool:
	if not data.has("player") or typeof(data.player) != TYPE_DICTIONARY:
		return false
	var player := data.player as Dictionary
	if not player.has("health"):
		if not player.has("hp"):
			return false
		player["health"] = player["hp"]
		player.erase("hp")
	return true
```

Each step accepts exactly one historical schema and advances exactly one version. After the loop, run the complete current-schema validator, including byte, collection, type, identifier, and numeric-range limits.

Never silently coerce a future version. A newer save may contain semantics the current build cannot preserve; return a clear unsupported-version error and leave runtime state unchanged.
