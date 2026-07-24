> ← Back to [SKILL.md](../SKILL.md)

# Runtime Resource Loading

## Runtime Scene Loading

```gdscript
const LEVEL_PATHS: Dictionary[StringName, String] = {
    &"tutorial": "res://levels/tutorial/tutorial.tscn",
    &"forest": "res://levels/forest/forest.tscn",
}

func load_level(level_id: StringName) -> PackedScene:
    if not LEVEL_PATHS.has(level_id):
        push_error("Rejected level id: %s" % level_id)
        return null

    var path: String = LEVEL_PATHS[level_id]
    if not path.begins_with("res://levels/"):
        push_error("Level escaped allowlisted root: %s" % path)
        return null
    if not ResourceLoader.exists(path, "PackedScene"):
        push_error("Missing level scene: %s" % path)
        return null

    var resource := ResourceLoader.load(path, "PackedScene")
    if resource is not PackedScene:
        push_error("Level is not a PackedScene: %s" % path)
        return null
    return resource
```

Use `preload()` for fixed parse-time dependencies. For data-driven choices, accept a stable ID rather
than an arbitrary path, map it through a bounded catalog, confirm the expected root, call
`ResourceLoader.exists(path, expected_type)`, and check the loaded object with `is` before use.
Extension checks and `as` casts alone are not a complete type boundary.

## Single-Thread Web Loading

Do not present `ResourceLoader.load_threaded_*` as background loading in Builda's single-threaded Web export. Preload predictable gameplay-critical resources, keep transition payloads small, and perform unavoidable `load()` calls behind an explicit loading transition. Measure browser stalls on the exported build; an animated loading indicator cannot update while a synchronous load blocks the main thread.
