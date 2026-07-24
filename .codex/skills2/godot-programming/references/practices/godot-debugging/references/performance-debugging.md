# Performance Debugging

Reference for `skills/godot-debugging/SKILL.md` — Profiler reading, Monitors tab usage, draw-call bottleneck identification, physics-tick monitoring.

> ← Back to [SKILL.md](../SKILL.md)

---
## 5. Performance Debugging

### Profiler

Open **Debugger > Profiler**, press **Start** while the game is running, play through the scenario you want to measure, then press **Stop**.

- **Frame Time** column — total time per frame in milliseconds.
- **Self** column — time spent in that function excluding callees; the primary bottleneck indicator.
- **Calls** column — call frequency; a function called thousands of times per frame is a candidate for optimisation.
- Click any function name to jump to its source.

```gdscript
# Profile a specific block manually
var start := Time.get_ticks_usec()
_run_expensive_operation()
var elapsed := Time.get_ticks_usec() - start
print("_run_expensive_operation took: %d µs" % elapsed)
```


### Monitors

**Debugger > Monitors** — key metrics to watch:

| Monitor | What to look for |
|---|---|
| `Time > FPS` | Below target (e.g. 60 fps) indicates frame budget overrun |
| `Time > Process` | High value means `_process()` callbacks are expensive |
| `Time > Physics Process` | High value means `_physics_process()` or physics sim is expensive |
| `Render > Total Draw Calls` | Compare representative scenes against the project's measured frame budget and baseline |
| `Render > Video RAM` | Repeated growth across the same scenario warrants checking retained resources and cache behavior |
| `Object > Object Count` | Growing count across identical scenes indicates nodes are not freed |
| `Physics 3D > Active Bodies` | Large count with simple scenes suggests objects are not sleeping |

### Separating Script CPU from Rendering Cost

```gdscript
# Save script CPU by pausing optional updates while the object is off-screen.
@onready var _vis: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D

func _ready() -> void:
    _vis.screen_entered.connect(_on_screen_entered)
    _vis.screen_exited.connect(_on_screen_exited)

func _on_screen_entered() -> void:
    set_process(true)

func _on_screen_exited() -> void:
    set_process(false)
```

`set_process(false)` only stops this node's `_process()` callback. It does not hide
a `MeshInstance3D` and does not itself reduce draw calls. Measure rendering and
script time separately; if an object truly must stop rendering, change the
renderer-owning node's visibility as an explicit gameplay/visual decision.

- Enable **Rendering > Debug > Draw Calls** in the editor Viewport menu to visualise batching.
- Use `RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)` for runtime draw call counts.

### Physics Tick Monitoring

```gdscript
# Track physics ticks to detect spiral-of-death (physics can't keep up)
var _physics_ticks_this_second := 0
var _second_timer := 0.0

func _physics_process(delta: float) -> void:
    _physics_ticks_this_second += 1

func _process(delta: float) -> void:
    _second_timer += delta
    if _second_timer >= 1.0:
        print("Physics ticks last second: ", _physics_ticks_this_second,
              " (target: ", Engine.physics_ticks_per_second, ")")
        _physics_ticks_this_second = 0
        _second_timer -= 1.0
```


- If ticks per second fall below `Engine.physics_ticks_per_second`, reduce physics complexity or lower `physics_ticks_per_second` in Project Settings.

---
