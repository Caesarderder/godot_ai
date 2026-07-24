# Saving Trusted Authored Resources

`ResourceSaver` is appropriate for trusted authoring/build-time output under `res://`, such as a
controlled editor import or generator that creates project definitions. It is not the persistence
format for runtime save slots, imported player data, settings, downloaded mods, or other files that
can be modified outside the trusted authoring pipeline.

```gdscript
@tool
extends EditorScript

const OUTPUT_PATH := "res://data/generated/internal_definition.tres"


func _run() -> void:
	var definition := GeneratedDefinition.new()
	var error := ResourceSaver.save(definition, OUTPUT_PATH)
	if error != OK:
		push_error("Failed to save trusted authored Resource: %d" % error)
```

The generator chooses a fixed allowlisted project path. Do not accept a caller-provided path. This
editor-time recipe is not included in shipped runtime behavior.

| Format | Use |
| --- | --- |
| `.tres` | Human-readable, diffable trusted project definitions |
| `.res` | Compact trusted project definitions when text diffs are unnecessary |

Never load `.tres` or `.res` from `user://`, user uploads, imported saves, downloaded content, or
user-editable paths. Resources can include script-bearing object graphs. Route all user-controlled
settings and saves through the validation, schema, migration, bounds, and recovery contracts in
`save-load`.
