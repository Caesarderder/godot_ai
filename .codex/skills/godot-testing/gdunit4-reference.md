# gdUnit4 Quick Reference

gdUnit4 is an optional testing framework for Godot 4.x. This reference covers the
GDScript workflow used by Builda's Godot 4.6 projects.

---

## Installation

**Option A — AssetLib (editor)**

1. Open the Godot editor, go to **AssetLib**
2. Search for "gdUnit4"
3. Download and install — this creates `addons/gdUnit4/`
4. Enable in **Project > Project Settings > Plugins**

**Option B — git submodule**

```bash
git submodule add https://github.com/MikeSchulze/gdUnit4.git addons/gdUnit4
```

Then enable the plugin in **Project > Project Settings > Plugins**.

---

## File Conventions

### GDScript

| Convention   | Rule                                                                  |
|--------------|-----------------------------------------------------------------------|
| File name    | Must start with `test_` (e.g., `test_health_component.gd`)           |
| Class        | `extends GdUnitTestSuite`                                             |
| Test method  | Must start with `func test_`                                          |

```gdscript
# tests/unit/test_health_component.gd
extends GdUnitTestSuite

func test_example() -> void:
    assert_that(1 + 1).is_equal(2)
```

---

## Lifecycle

### GDScript

```
before()
  for each test:
    before_test()
      test_*()
    after_test()
after()
```

```gdscript
extends GdUnitTestSuite

func before() -> void:
    # Runs once before ALL tests in this file
    pass

func after() -> void:
    # Runs once after ALL tests in this file
    pass

func before_test() -> void:
    # Runs before EACH test — set up fresh state here
    pass

func after_test() -> void:
    # Runs after EACH test — manual cleanup if needed
    pass
```

---

## Memory Management

### GDScript — `auto_free()`

Registers any `Object` for automatic freeing after the test. Does NOT add it to the scene tree.

```gdscript
func before_test() -> void:
    _health = auto_free(HealthComponent.new())
    add_child(_health)  # add manually if needed in the tree
```

---

## Assertions API — GDScript

All assertions start with `assert_that(value)` and chain fluently.

### Values

```gdscript
assert_that(value).is_equal(expected)
assert_that(value).is_not_equal(expected)
assert_that(value).is_null()
assert_that(value).is_not_null()
assert_that(value).is_true()
assert_that(value).is_false()
assert_that(value).is_same(other)          # reference equality
assert_that(value).is_not_same(other)
```

### Numbers

```gdscript
assert_that(n).is_greater(x)
assert_that(n).is_greater_equal(x)
assert_that(n).is_less(x)
assert_that(n).is_less_equal(x)
assert_that(n).is_between(low, high)        # inclusive
assert_that(n).is_approximately(expected, margin)
assert_that(n).is_negative()
assert_that(n).is_zero()
```

### Strings

```gdscript
assert_that(str).is_equal(expected)
assert_that(str).contains("substring")
assert_that(str).not_contains("substring")
assert_that(str).starts_with("prefix")
assert_that(str).ends_with("suffix")
assert_that(str).is_empty()
assert_that(str).is_not_empty()
assert_that(str).has_length(n)
```

### Arrays

```gdscript
assert_that(arr).is_equal([1, 2, 3])
assert_that(arr).contains([2, 3])           # subset check
assert_that(arr).not_contains([4])
assert_that(arr).contains_exactly([1, 2, 3]) # exact match, any order
assert_that(arr).is_empty()
assert_that(arr).is_not_empty()
assert_that(arr).has_size(n)
```

### Signals

```gdscript
func test_signal() -> void:
    var monitor := monitor_signals(_health)
    _health.take_damage(10)

    assert_signal(monitor).is_emitted("health_changed")
    assert_signal(monitor).is_emitted("health_changed").with_parameters([100, 90])
    assert_signal(monitor).is_not_emitted("died")
    assert_signal(monitor).is_emitted("health_changed").exactly(1)
```

---

## Mocking API — GDScript

```gdscript
# Create a mock (all methods stubbed to return null/defaults)
var mock_health := mock(HealthComponent)

# Stub a return value
do_return(75).on(mock_health).get_health()
do_return(false).on(mock_health).is_dead()

# Stub a property getter
# (use a method wrapper or spy pattern for property stubs)

# Verify a method was called
_player.health = mock_health
_player.receive_hit(10)

verify(mock_health).take_damage(10)
verify(mock_health, times(1)).take_damage(10)    # called exactly once
verify_no_interactions(mock_health)              # use before any calls

# Spy — wraps a real object, keeps real behavior, but tracks calls
var spy_health := spy(HealthComponent.new())
add_child(auto_free(spy_health))
spy_health.take_damage(10)

assert_eq(spy_health.current_health, 90)         # real method ran
verify(spy_health).take_damage(10)               # call was tracked
```

---

## CLI Commands

### GDScript tests

```bash
godot --headless \
  -s addons/gdUnit4/GdUnitRunner.gd \
  -- \
  --testsuites res://tests
```

### Common CLI flags

| Flag                          | Description                                          |
|-------------------------------|------------------------------------------------------|
| `--testsuites <path>`         | Path to test directory or specific file              |
| `--report-dir <path>`         | Output directory for HTML/XML reports                |
| `--report-count <n>`          | Number of reports to keep (default: 20)              |
| `--verbose`                   | Verbose output                                       |
| `--ignore-pause`              | Skip `pause()` calls during CI runs                  |

### Minimal CI invocation

```bash
godot --headless \
  -s addons/gdUnit4/GdUnitRunner.gd \
  -- \
  --testsuites res://tests \
  --report-dir ./reports
```

### Exit codes

| Code | Meaning                  |
|------|--------------------------|
| 0    | All tests passed         |
| 1    | One or more tests failed |
