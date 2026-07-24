---
name: godot-debugging
description: Use when diagnosing Godot 4.6 GDScript projects through reproducible headless runs, structured logs, minimal repros, signal tracing, and runtime inspection
---

# Godot Debugging for Builda Web

The default path is reproducible and terminal-first: capture the failure, run Godot headlessly, preserve logs, isolate a minimal reproduction, fix the cause, and rerun the same command. Editor-only tools are optional follow-up aids because remote Builda execution may not have an interactive editor.

## 1. Capture an Exact Reproduction

Record:

- the scene or command that fails;
- the first bad frame, action, or signal;
- expected versus actual behavior;
- whether the failure occurs in headless debug, Web preview, or both;
- the first relevant engine error and stack trace.

Use a deterministic seed and fixed inputs when randomness is involved. Do not start by editing code based only on the final secondary error.

## 2. Run Headlessly and Preserve Logs

Use the repository's configured Godot binary when one exists. Typical checks are:

```bash
# Import/parse the project and exit.
godot --headless --path . --editor --quit

# Run the configured main scene for a bounded number of frames.
godot --headless --path . --quit-after 300

# Add engine diagnostics when normal output is insufficient.
godot --headless --verbose --path . --quit-after 300
```

Prefer the project's existing smoke/test command over inventing a new one. Capture stdout and stderr in the task output, and report the exact exit code. Headless success does not prove Web-rendering or browser lifecycle behavior, so reproduce relevant issues again in Web preview after the deterministic check passes.

## 3. Add Focused GDScript Diagnostics

```gdscript
func require_player() -> CharacterBody2D:
    var player := get_node_or_null("Player") as CharacterBody2D
    if player == null:
        push_error("Level.require_player: Player node is missing")
    return player


func trace_state(event: StringName, details: Dictionary) -> void:
    print_debug("[state] event=%s details=%s frame=%d" % [
        event,
        details,
        Engine.get_process_frames(),
    ])
```

Use:

- `push_error()` for invalid state that must be fixed;
- `push_warning()` for recoverable but suspicious state;
- `print_debug()` for bounded diagnostics that should not remain noisy in release;
- `printerr()` when a line must be visible on stderr/CI.

Log stable identifiers, node paths, state names, and frame/sequence numbers. Do not log secrets, tokens, full prompts, or large user project contents.

## 4. Reduce to a Minimal Reproduction

Create the smallest existing scene/test path that still fails:

1. Duplicate the failing scenario only when the project already has a safe test fixture area.
2. Remove unrelated nodes and autoload interactions one group at a time.
3. Replace external inputs with fixed local values.
4. Keep the same failing assertion or log signature.
5. Confirm that restoring the suspected dependency restores the failure.

A minimal repro should name one cause, not merely hide the symptom. If a new file is unnecessary, isolate by launching a specific existing scene or test.

## 5. Trace Signals and Lifecycle

```gdscript
func dump_connections(node: Node, signal_name: StringName) -> void:
    for connection in node.get_signal_connection_list(signal_name):
        print_debug("signal=%s callable=%s flags=%s" % [
            signal_name,
            connection.get("callable"),
            connection.get("flags"),
        ])
```

Check for duplicate connections, a receiver freed across `await`, wrong handler signatures, and callbacks arriving after a scene transition. Guard delayed work with `is_instance_valid()` and explicit generation/state checks where ownership can change.

See [references/signal-tracing.md](references/signal-tracing.md) for deeper patterns.

## 6. Common Failure Signatures

| Error | Likely cause | First check |
|---|---|---|
| `Node not found` | Wrong path or access before `_ready()` | `get_node_or_null()`, runtime tree, lifecycle order |
| Null instance call | Missing export, freed node, or failed lookup | Validate assignment and `is_instance_valid()` |
| Physics state change while flushing | Mutation inside a physics callback | Use `set_deferred()` for the mutation |
| Nonexistent function | Wrong runtime type or missing script | Print `get_class()`, script path, and node path |
| Already connected | Duplicate setup path | Check `is_connected()` and lifecycle ownership |
| Index out of bounds | Stale index or empty data | Log size and index at the ownership boundary |
| Stack overflow | Recursive setter/signal loop | Trace entry count and break the feedback cycle |

## 7. Verify the Fix

Run the same headless command that reproduced the failure. Then:

- run the narrow existing regression suite;
- run a Web preview check when rendering, input, browser focus, storage, or lifecycle matters;
- remove temporary noisy logs;
- retain a named regression test or bounded assertion when practical.

The systematic flow is detailed in [references/systematic-method.md](references/systematic-method.md).

## 8. Optional Editor Tools

When an interactive editor is available, use breakpoints, the Remote scene tree, Debugger monitors, and the Profiler to inspect live state. These tools supplement the reproducible headless path; they are not required to begin diagnosis.

- Scene tree helpers: [references/scene-tree-debugging.md](references/scene-tree-debugging.md)
- Performance diagnosis: [references/performance-debugging.md](references/performance-debugging.md)

## Checklist

- [ ] Exact failure command/scene and expected result are recorded.
- [ ] Headless run exit code and first relevant error are preserved.
- [ ] Diagnostics use stable IDs, paths, frames, or sequence numbers.
- [ ] Minimal repro still produces the same failure signature.
- [ ] Root cause is verified before implementation changes expand.
- [ ] The original headless reproduction passes after the fix.
- [ ] Relevant Web-preview behavior is checked separately.
- [ ] Temporary logs are removed and a regression check remains.
