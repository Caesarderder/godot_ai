---
name: godot-testing
description: Use when detecting, writing, and running tests for Godot 4.6 GDScript projects, preferring an existing GUT or gdUnit4 setup and headless verification
---

# Godot Testing for Builda Web

Builda defaults to Godot 4.6.x and GDScript. Reuse the project's existing test framework and commands. Never install, download, enable, or upgrade a test addon automatically.

## 1. Detect the Existing Test Setup

Before writing tests, inspect the repository:

```bash
rg -n "gut|gdUnit4|GdUnit" project.godot addons tests .github 2>/dev/null
rg --files addons tests 2>/dev/null | rg "(gut|gdUnit4|test_)"
```

Check, in order:

1. repository scripts and CI commands;
2. `addons/gut/plugin.cfg` or `addons/gdUnit4/plugin.cfg`;
3. enabled plugins in `project.godot`;
4. existing test base classes and naming conventions;
5. test configuration files and report directories.

If both frameworks appear, follow the framework already used by the nearest tests. Do not migrate frameworks as part of an ordinary feature fix.

If no framework exists, run the project's existing headless smoke checks and report the gap. Propose a framework separately; addon installation requires explicit user authorization and project review.

## 2. Default Framework Path

For a GDScript project with no conflicting established convention, prefer GUT after it has been explicitly approved and added to the project. If gdUnit4 is already installed and used by nearby GDScript tests, keep using it.

| Existing evidence | Action |
|---|---|
| GUT addon/config/tests | Write a GUT test matching nearby files |
| gdUnit4 addon/config/tests | Write a gdUnit4 GDScript test matching nearby files |
| Both | Follow the closest subsystem's established framework |
| Neither | Do not install; run smoke checks and request a separate setup decision |

## 3. Write the Smallest Regression Test

A test should reproduce one public behavior and fail for the original bug. For GUT:

```gdscript
extends GutTest

var subject: HealthComponent


func before_each() -> void:
    subject = add_child_autofree(HealthComponent.new())
    subject.max_health = 100
    subject.current_health = 100


func test_damage_clamps_health_at_zero() -> void:
    subject.apply_damage(150)
    assert_eq(subject.current_health, 0)
```

Keep Arrange, Act, and Assert visible. Prefer behavior through the public API over private-state assertions.

For scene tests, instantiate only the minimum scene under test. Use the framework's auto-free facility so teardown is deterministic.

## 4. TDD Loop

1. **Red:** run the narrow test and confirm it fails for the intended reason.
2. **Green:** implement the smallest behavior change.
3. **Refactor:** clean up without changing the contract.
4. Rerun the narrow test, related suite, and project smoke gate.

Do not accept a test that starts green unless it is documenting already-correct behavior for a separate reason. See [references/tdd-workflow.md](references/tdd-workflow.md) for the longer workflow; adapt examples to the detected GDScript framework.

## 5. Run Headlessly

Prefer repository scripts. When GUT is installed at its standard path, the narrow baseline is:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests
```

Use the exact gdUnit4 runner command already present in repository scripts or CI because addon versions differ. Do not guess a runner path and do not fetch a newer addon to make a command work.

Record the command, exit code, passed/failed count, and first failure. A headless suite does not prove Web rendering, browser input, storage, or lifecycle behavior; add the appropriate Web-preview check for those surfaces.

See [references/running-tests.md](references/running-tests.md) only after confirming which framework and addon version are installed.

## 6. Common GUT Assertions

| Assertion | Purpose |
|---|---|
| `assert_eq(actual, expected)` | Equality |
| `assert_true(value)` / `assert_false(value)` | Boolean contract |
| `assert_null(value)` / `assert_not_null(value)` | Optional values |
| `assert_almost_eq(actual, expected, margin)` | Float tolerance |
| `assert_has(collection, item)` | Membership |
| `watch_signals(object)` + `assert_signal_emitted()` | Signal behavior |

Watch signals before performing the action. For async behavior, await a specific signal/frame with a bounded framework timeout; do not use arbitrary sleeps.

Additional patterns are in [references/testing-patterns.md](references/testing-patterns.md).

## 7. What Not to Test

- Godot engine internals such as whether `add_child()` works;
- private implementation details that can change without behavior changing;
- pixel-perfect rendering in a unit suite;
- timing-sensitive values without a tolerance;
- unrelated invalid inputs outside the documented contract;
- addon installation or editor state as a side effect of running a test.

## Checklist

- [ ] Existing framework, version, runner, and naming convention were detected first.
- [ ] No addon was installed, enabled, upgraded, or downloaded automatically.
- [ ] New test matches the nearest GDScript test convention.
- [ ] The regression test failed for the intended reason before the fix.
- [ ] Test covers one public behavior and has deterministic cleanup.
- [ ] Signals are watched before the triggering action.
- [ ] Async waits are bounded by framework timeouts, not sleeps.
- [ ] Narrow test, related suite, and project smoke gate pass headlessly.
- [ ] Web-specific behavior has separate runtime evidence where needed.
