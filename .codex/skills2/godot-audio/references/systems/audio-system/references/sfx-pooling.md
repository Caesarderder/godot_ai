# Scene-owned SFX Pooling

Pool only after measurements show player churn, clipping, or an intentional voice cap. The default
owner is the feature/world scene that emits the sounds, not an Autoload.

## Non-positional pool

Attach this script to a feature-owned Node or an `sfx_pool.tscn` instanced by the feature:

```gdscript
class_name SfxPool
extends Node

@export_range(1, 64, 1) var pool_size: int = 16

var _players: Array[AudioStreamPlayer] = []
var _index := 0


func _ready() -> void:
	for _slot in pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_players.append(player)


func play(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null or _players.is_empty():
		return
	var player := _players[_index]
	_index = (_index + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = clampf(pitch_scale, 0.01, 4.0)
	player.play()
```

The feature root injects or references its owned pool:

```gdscript
@onready var sfx_pool: SfxPool = %SfxPool


func _on_impact(stream: AudioStream) -> void:
	sfx_pool.play(stream, -3.0, randf_range(0.9, 1.1))
```

An application-lifetime pool is justified only for genuinely global, non-positional UI sounds that
must survive route replacement. Even then, expose it through the Audio service contract rather than
another unrelated global singleton.

## Positional 2D pool

A positional pool belongs to the world whose coordinate space it uses:

```gdscript
class_name SfxPool2D
extends Node2D

@export_range(1, 64, 1) var pool_size: int = 16

var _players: Array[AudioStreamPlayer2D] = []
var _index := 0


func _ready() -> void:
	for _slot in pool_size:
		var player := AudioStreamPlayer2D.new()
		player.bus = &"SFX"
		add_child(player)
		_players.append(player)


func play_at(stream: AudioStream, world_position: Vector2, volume_db: float = 0.0) -> void:
	if stream == null or _players.is_empty():
		return
	var player := _players[_index]
	_index = (_index + 1) % _players.size()
	player.global_position = world_position
	player.stream = stream
	player.volume_db = volume_db
	player.play()
```

Do not Autoload a positional pool: route changes can replace the world, coordinate space, listener,
and attenuation expectations. Tear the pool down with its owning world.

## Pool policy

- Define the product voice cap and which sounds may be interrupted.
- Prefer free/oldest/quietest selection when round-robin interruption harms important cues.
- Never restart the same SFX every frame.
- Clear streams and stop players on owner teardown when route replacement can overlap audio.
- Verify simultaneous voices, positional behavior, and Sample/Stream choice in Web.
