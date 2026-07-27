# Audio Settings Integration

Audio consumes a validated Settings snapshot. It does not discover SettingsService or persist
preferences itself.

```gdscript
# audio_service.gd
extends Node


func apply_settings(snapshot: SettingsSnapshot) -> void:
	_apply_bus_volume(&"Master", snapshot.master_volume)
	_apply_bus_volume(&"Music", snapshot.music_volume)
	_apply_bus_volume(&"SFX", snapshot.sfx_volume)


func _apply_bus_volume(bus_name: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_warning("Missing audio bus: %s" % bus_name)
		return

	var value := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(index, value <= 0.0001)
	if value > 0.0001:
		AudioServer.set_bus_volume_db(index, linear_to_db(value))
```

The application composition root wires the systems after consumers exist:

```gdscript
func _ready() -> void:
	SettingsService.settings_changed.connect(AudioService.apply_settings)
	SettingsService.initialize()
	AudioService.apply_settings(SettingsService.current_snapshot())
```

The settings UI calls a typed Settings method. It does not call AudioServer and write storage in the
same slider callback. Settings emits a duplicate-safe snapshot; Audio applies it immediately; Settings
coalesces persistence through Apply/Confirm, a bounded debounce, or an explicit lifecycle checkpoint.

## Boundaries

- AudioService owns bus application, persistent music, and browser unlock/resume only when those need
  application lifetime.
- SettingsService owns validated preferences and persistence.
- Feature scenes own local/positional SFX.
- A missing bus produces a local warning and does not mutate Settings.
- The initial snapshot is queried/replayed after connection; consumers cannot miss startup state.
- Browser Sample-versus-Stream limitations, autoplay unlock, and hidden-tab resume require exported
  Web evidence.
