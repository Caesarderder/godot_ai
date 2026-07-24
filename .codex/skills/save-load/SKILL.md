---
name: save-load
description: Use when implementing or repairing Godot 4.6 GDScript save systems, settings, save slots, JSON schemas, migrations, atomic writes, backups, bounded loading, and browser persistence for single-threaded Web exports.
---

# Save and Load in Godot 4.6

Treat a save file as untrusted input even when it lives under `user://`. Validate its name, size, syntax, schema, and version before applying any state.

> Linked references are a legacy archive. Load and use only their Godot 4.6-compatible GDScript sections.

## Choose a format

| Format | Use for | Boundary |
| --- | --- | --- |
| `ConfigFile` | Small settings and controls | Still check load/save error codes |
| JSON | Versioned game saves and import/export | Validate types, ranges, and identifiers |
| Custom `Resource` | Trusted authored data | Never load user-supplied scripts/resources |

Read [references/configfile.md](references/configfile.md) for settings. Use [references/json-saves.md](references/json-saves.md) as the canonical save-slot implementation.

## Required save pipeline

1. Convert caller input to a validated slot ID; never concatenate arbitrary text into a path.
2. Build a plain data snapshot with a root integer `version`.
3. Validate the snapshot against the current schema before serialization.
4. Serialize and reject output above the configured byte limit.
5. Write to a temporary file in the same directory, call `flush()`, and close it.
6. Move the previous primary file to a backup, then rename the temporary file to the primary path.
7. Restore the backup if final publication fails.

Writing directly to the primary file can leave a truncated save after interruption. A temporary file plus same-directory rename narrows that failure window; retaining one validated backup provides recovery when the primary is missing or corrupt.

## Required load pipeline

1. Validate the slot ID and derive only known paths.
2. Reject missing, oversized, or unreadable files before parsing.
3. Require a JSON `Dictionary`, a supported integer version, and the expected root fields.
4. Migrate incrementally on a detached data structure.
5. Validate the current schema after migration.
6. Apply data only after all validation succeeds.
7. If the primary fails, attempt the backup and report that recovery occurred.

Do not partially mutate the scene while parsing. Loading must either produce one validated snapshot or leave runtime state unchanged.

## Slot and schema rules

- Restrict slot IDs to a short allowlist such as ASCII letters, digits, `_`, and `-`.
- Reject empty names, separators, dots used for traversal, absolute paths, and overlong values.
- Keep filename construction in one helper.
- Cap file bytes and collection lengths before allocating or spawning nodes.
- Validate required keys and exact value types; clamp or reject gameplay ranges intentionally.
- Reject future versions rather than guessing how to interpret them.
- Use stable content IDs, not arbitrary saved resource or scene paths, when reconstructing objects.

Read [references/version-migration.md](references/version-migration.md) for incremental migration and [references/save-architecture.md](references/save-architecture.md) for stable per-object ownership.

## Browser persistence

In Web exports, `user://` is browser-managed storage associated with the deployed origin. A successful local write does not guarantee permanent retention: private browsing, storage eviction, clearing site data, or changing the origin can remove or isolate saves.

- Check `OS.is_userfs_persistent()` to inform the player, but do not treat `true` as a guarantee because the platform can report false positives.
- Test persistence in the deployed browser origin, including reload and restart.
- Save at explicit checkpoints; do not rely only on a page-close callback.
- Surface write/load failures to the player.
- Offer export/import or authenticated cloud sync for saves that must survive browser storage loss.
- Version imported/cloud data through the same validation pipeline.
- Do not assume native filesystem paths or atomic durability guarantees beyond the browser-backed `user://` behavior.

## Checklist

- [ ] Slot IDs pass a strict allowlist before any path is constructed.
- [ ] Saves use `user://`; runtime code never writes `res://`.
- [ ] Temporary write, flush, close, backup, publish, and rollback errors are checked.
- [ ] Primary corruption can fall back to one validated backup.
- [ ] Read and serialized byte sizes are capped.
- [ ] Root type, version, required fields, nested types, ranges, and collection lengths are validated.
- [ ] Migration runs incrementally and validation runs again afterward.
- [ ] Runtime state changes only after the entire snapshot is valid.
- [ ] Web retention limitations are reflected in UX and verification.
- [ ] Implementation uses Godot 4.6 GDScript and requires no threads.
