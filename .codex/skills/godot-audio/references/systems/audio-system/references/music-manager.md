# Persistent Music Service

Use an application-lifetime Music/Audio service only when music must continue or crossfade across
route replacement. Otherwise keep the music player in the screen or level scene.

When global lifetime is proven, prefer an authored scene:

```text
AudioService
├── MusicA (AudioStreamPlayer)
└── MusicB (AudioStreamPlayer)
```

Register `audio_service.tscn` under the application service composition root or as one narrow
Autoload. The stable player subtree belongs in `.tscn`; the root behavior belongs in `.gd`.

```gdscript
extends Node

@export_range(0.0, 10.0, 0.1) var crossfade_duration := 1.5

@onready var _player_a: AudioStreamPlayer = %MusicA
@onready var _player_b: AudioStreamPlayer = %MusicB

var _active_player: AudioStreamPlayer
var _transition: Tween


func _ready() -> void:
	_active_player = _player_a


func play_music(stream: AudioStream, from_position: float = 0.0) -> void:
	if stream == null:
		push_warning("AudioService received a null music stream")
		return
	if _active_player.stream == stream and _active_player.playing:
		return

	_cancel_transition()
	var next_player := _player_b if _active_player == _player_a else _player_a
	next_player.stream = stream
	next_player.volume_db = -80.0
	next_player.play(maxf(from_position, 0.0))

	_transition = create_tween().set_parallel(true)
	_transition.tween_property(_active_player, "volume_db", -80.0, crossfade_duration)
	_transition.tween_property(next_player, "volume_db", 0.0, crossfade_duration)
	_transition.chain().tween_callback(_active_player.stop)
	_active_player = next_player


func stop_music(fade_duration: float = 1.0) -> void:
	_cancel_transition()
	_transition = create_tween()
	_transition.tween_property(_active_player, "volume_db", -80.0, maxf(fade_duration, 0.0))
	_transition.tween_callback(_active_player.stop)


func set_music_volume(linear: float) -> void:
	var index := AudioServer.get_bus_index(&"Music")
	if index < 0:
		push_warning("Missing Music audio bus")
		return
	var value := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(index, value <= 0.0001)
	if value > 0.0001:
		AudioServer.set_bus_volume_db(index, linear_to_db(value))


func shutdown() -> void:
	_cancel_transition()
	_player_a.stop()
	_player_b.stop()
	_player_a.stream = null
	_player_b.stream = null


func _cancel_transition() -> void:
	if _transition != null and _transition.is_valid():
		_transition.kill()
	_transition = null
```

The application or flow coordinator calls this service through its typed dependency. Feature scripts
emit music intent to their owner; they do not reach an unrelated global MusicManager from arbitrary
locations.

Verify repeated requests, interrupted crossfades, route replacement, hidden-tab resume, browser audio
unlock, loop seams, and Sample-versus-Stream behavior in the exported Web build.
