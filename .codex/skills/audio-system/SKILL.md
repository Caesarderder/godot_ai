---
name: audio-system
description: Implement or review Godot 4.6.x audio in GDScript for Builda's single-threaded Web runtime. Use for AudioStreamPlayer nodes, buses, music and SFX ownership, pooling, fades, playback type, browser autoplay, and Web sample-versus-stream limitations.
---

# Audio System

Target Godot 4.6.x, GDScript, and the single-threaded Web export.

## Ownership

Use the smallest player type:

| Need | Node |
|---|---|
| Music, ambience, UI sound | `AudioStreamPlayer` |
| 2D positional sound | `AudioStreamPlayer2D` |
| 3D positional sound | `AudioStreamPlayer3D` |

Give music, UI, and high-volume SFX explicit owners. Avoid creating an unbounded player node for every event; pool only after concurrency measurements show churn or clipping.

```gdscript
@onready var music_player: AudioStreamPlayer = $MusicPlayer

func play_music(stream: AudioStream) -> void:
    if music_player.stream == stream and music_player.playing:
        return
    music_player.stream = stream
    music_player.play()
```

## Web playback modes

Single-threaded Web exports default to Sample playback for low latency through the browser Web Audio API.

Sample playback limitations in this target:

- audio bus effects are not supported;
- reverberation and Doppler are not supported;
- procedural audio generation is not supported;
- positional audio can vary with player properties and browser behavior.

Choose Sample for ordinary low-latency UI/gameplay sounds that do not require those features. Choose Stream on an individual player or through the Web playback project setting when Godot bus effects or fuller engine mixing are required, accepting higher latency in the single-threaded export.

Do not use procedural generator streams for the default Web sample path. Test every playback-type decision in the exported browser build.

## Browser autoplay and lifecycle

Browsers may keep audio suspended until a click, tap, or key press. Design the first interaction or splash screen to unlock audio; do not interpret initial silence as a missing asset.

Browser tabs may pause processing while hidden. Do not build music sequencing around frame callbacks continuing in a background tab. On resume, reconcile desired music state with actual playback position and product expectations.

## Buses and volume

Use buses such as `Master`, `Music`, `SFX`, and `UI` only when they represent real control needs. Convert linear UI volume to decibels and define mute explicitly:

```gdscript
func set_bus_volume(bus_name: StringName, linear: float) -> void:
    var index := AudioServer.get_bus_index(bus_name)
    if index < 0:
        push_warning("Missing audio bus: %s" % bus_name)
        return
    var value := clampf(linear, 0.0, 1.0)
    AudioServer.set_bus_mute(index, value <= 0.0001)
    if value > 0.0001:
        AudioServer.set_bus_volume_db(index, linear_to_db(value))
```

Remember that effects on a bus do not affect Sample playback on Web. If the design depends on an effect, use Stream and measure latency, or bake the effect into the source asset.

## Music transitions

For a simple crossfade, keep two `AudioStreamPlayer` nodes and tween their `volume_db`. Store and replace the active transition tween so repeated requests cannot compete.

Do not assume compressed audio loop points, seek precision, or crossfade timing match desktop output. Verify loop seams and resume behavior in target browsers.

## SFX concurrency

- Set a product-level maximum for simultaneous voices.
- Reuse the oldest/quietest available player only when dropping a sound is acceptable.
- Do not restart the same critical sound every frame.
- Keep positional player counts low and verify panning/attenuation in Web.
- Normalize source loudness; avoid using bus gain to repair inconsistent assets.

## References boundary

No bundled reference is required by default. Existing `references/` files are optional legacy recipes and may include other languages or engine-version features. Do not load them automatically; any reused fragment must be reduced to target-version GDScript and tested in exported Web audio.

## Checklist

- [ ] Audio starts from or after a user gesture.
- [ ] Every player has an intentional Sample or Stream choice.
- [ ] Sample-only limitations are acceptable or effects are baked into assets.
- [ ] Stream latency is measured where full mixing is required.
- [ ] Music transitions cannot overlap unexpectedly.
- [ ] SFX concurrency is bounded.
- [ ] Hidden-tab and resume behavior is tested.
- [ ] Target browsers are tested for loop, latency, position, and volume.
