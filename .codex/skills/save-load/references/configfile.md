# ConfigFile — Settings


> ← Back to [SKILL.md](../SKILL.md)

---
## 2. ConfigFile — Settings

Use ConfigFile for application settings: audio volumes, display options, key bindings. It produces a human-readable INI-style file.

### GDScript

```gdscript
# settings_manager.gd — add as autoload named SettingsManager
extends Node

const SETTINGS_PATH := "user://settings.cfg"

var _config := ConfigFile.new()


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var err := _config.load(SETTINGS_PATH)
	if err != OK:
		_set_defaults()
		save_settings()


func save_settings() -> void:
	var err := _config.save(SETTINGS_PATH)
	if err != OK:
		push_error("SettingsManager: failed to save settings — error %d" % err)


func get_setting(section: String, key: String, default: Variant = null) -> Variant:
	return _config.get_value(section, key, default)


func set_setting(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)
	save_settings()


func _set_defaults() -> void:
	# Audio
	_config.set_value("audio", "master_volume", 1.0)
	_config.set_value("audio", "music_volume", 0.8)
	_config.set_value("audio", "sfx_volume", 1.0)
	# Display
	_config.set_value("display", "fullscreen", false)
	_config.set_value("display", "vsync", true)
	_config.set_value("display", "resolution_scale", 1.0)
```

**Usage:**

```gdscript
# Read
var vol: float = SettingsManager.get_setting("audio", "master_volume", 1.0)

# Write
SettingsManager.set_setting("audio", "master_volume", 0.5)
```



**Usage:**


---
