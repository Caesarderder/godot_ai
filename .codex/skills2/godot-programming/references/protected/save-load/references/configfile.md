# ConfigFile Settings Contract

Use `ConfigFile` as the internal persistence format for small application preferences such as audio
mix, accessibility, and control settings. Do not expose ConfigFile's arbitrary section/key/value API
as the public Settings service.

## Separate the three states

1. `SettingsDefaults`: trusted authored Resource with defaults and allowed ranges.
2. `SettingsSnapshot`: immutable or duplicate-safe typed runtime value delivered to consumers.
3. `user://settings.cfg`: untrusted persisted input that is parsed and validated into a snapshot.

The Settings service owns parsing and persistence. UI owns widgets. Audio, display, input, and
accessibility owners receive a snapshot through explicit composition-root wiring.

```gdscript
# settings_snapshot.gd
class_name SettingsSnapshot
extends RefCounted

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var reduce_motion: bool = false


func duplicate_value() -> SettingsSnapshot:
	var copy := SettingsSnapshot.new()
	copy.master_volume = master_volume
	copy.music_volume = music_volume
	copy.sfx_volume = sfx_volume
	copy.reduce_motion = reduce_motion
	return copy
```

The service API is domain-typed:

```gdscript
# settings_service.gd — register as an Autoload only when application lifetime is proven
extends Node

signal settings_changed(snapshot: SettingsSnapshot)
signal settings_persisted
signal settings_persist_failed(code: Error)

const SETTINGS_PATH := "user://settings.cfg"

var _current := SettingsSnapshot.new()
var _dirty := false
var _initialized := false


func initialize() -> Error:
	if _initialized:
		return OK

	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error == OK:
		_current = _validated_snapshot(config)
	elif error != ERR_FILE_NOT_FOUND:
		push_warning("Settings file is invalid; using defaults without overwriting it")

	_initialized = true
	return error if error != ERR_FILE_NOT_FOUND else OK


func current_snapshot() -> SettingsSnapshot:
	return _current.duplicate_value()


func update_audio_mix(master: float, music: float, sfx: float) -> void:
	_current.master_volume = clampf(master, 0.0, 1.0)
	_current.music_volume = clampf(music, 0.0, 1.0)
	_current.sfx_volume = clampf(sfx, 0.0, 1.0)
	_dirty = true
	settings_changed.emit(current_snapshot())
```

`_validated_snapshot()` must inspect each `Variant` type and clamp or reject ranges before assigning
typed fields. Missing values use trusted defaults. A corrupt file must not be silently overwritten
during initialization.

## Persistence timing

Do not call `ConfigFile.save()` on every slider event or input frame. Update the runtime snapshot and
mark it dirty, then persist on an explicit Apply/Confirm action, a bounded debounce, or a documented
lifecycle checkpoint.

`flush()` must:

1. serialize only known typed fields;
2. write to a temporary path in the same `user://` directory;
3. check the save result;
4. replace the primary only after the temporary write succeeds;
5. retain or restore a validated previous file when publication fails;
6. clear `_dirty` only after success.

`settings_changed(snapshot)` means the validated in-memory preference state changed; consumers may
apply it immediately. It does not claim disk persistence. `flush()` returns an `Error` and may emit
the separate factual `settings_persisted` or `settings_persist_failed(code)` signal. A disk failure
does not silently undo the already-applied runtime preference, and must never be reported as
persisted.

## Composition

Connect after the main application root exists:

```gdscript
func _ready() -> void:
	SettingsService.settings_changed.connect(AudioService.apply_settings)
	var error := SettingsService.initialize()
	AudioService.apply_settings(SettingsService.current_snapshot())
	if error != OK:
		_show_non_blocking_settings_warning(error)
```

The example shows wiring ownership, not permission for AudioService to query SettingsService in its
own `_ready()`. If audio is scene-owned, inject the snapshot into that scene instead of adding an
Audio Autoload.

## Checklist

- Public methods and snapshots are typed; arbitrary section/key access stays private.
- Every persisted value is type-checked and range-validated.
- Corrupt input falls back without destroying recovery evidence.
- Slider/input changes are coalesced; storage is not rewritten every frame.
- Settings persistence is recoverable and every error is checked.
- Readiness is queryable/replayable; consumers cannot miss a one-shot Autoload `_ready()` signal.
- Browser-origin persistence and clearing/eviction behavior are verified separately.
