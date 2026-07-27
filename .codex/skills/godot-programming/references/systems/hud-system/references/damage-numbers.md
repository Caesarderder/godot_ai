# Damage Numbers

Reference for `skills/hud-system/SKILL.md` — floating damage-number scene with rise-and-fade tween and a pooled spawner. GDScript.

> ← Back to [SKILL.md](../SKILL.md)

---
## 4. Damage Numbers

Damage numbers are short-lived `Label` nodes that float upward and fade out. Spawn one per damage event; release it after the tween completes. For high-frequency damage (e.g. rapid-fire weapons) a simple manual pool avoids per-hit allocation.

### GDScript — DamageNumber scene (single instance)

```gdscript
## damage_number.gd — attach to a Label; root of a small PackedScene
class_name DamageNumber
extends Label

## Pixels to travel upward during the animation.
@export var rise_distance: float = 40.0

## Duration (seconds) for the full rise-and-fade.
@export var lifetime: float = 0.7

## Optional: tint critical hits differently before spawning.
@export var critical_color: Color = Color(1.0, 0.3, 0.1)
@export var normal_color: Color   = Color(1.0, 1.0, 1.0)


func show_damage(amount: int, is_critical: bool = false) -> void:
    text           = str(amount) if not is_critical else "!" + str(amount)
    modulate.a     = 1.0
    add_theme_font_size_override("font_size", 24 if not is_critical else 32)
    modulate       = critical_color if is_critical else normal_color
    _play_animation()


func _play_animation() -> void:
    var tween := create_tween()
    tween.set_parallel(true)

    # Rise upward
    tween.tween_property(self, "position:y", position.y - rise_distance, lifetime) \
        .set_ease(Tween.EASE_OUT) \
        .set_trans(Tween.TRANS_QUAD)

    # Fade out (start fading at halfway point)
    tween.tween_property(self, "modulate:a", 0.0, lifetime * 0.5) \
        .set_delay(lifetime * 0.5) \
        .set_ease(Tween.EASE_IN)

    tween.finished.connect(queue_free)
```



### GDScript — Spawner (attach to the HUD or a DamageNumbersLayer Node2D)

```gdscript
## damage_number_spawner.gd
extends Node

@export var damage_number_scene: PackedScene

## Simple pool: pre-instantiate a fixed number and recycle them.
## For low-frequency damage, omit pooling and just instantiate directly.
const POOL_SIZE := 20
var _pool: Array[DamageNumber] = []
var _pool_index: int = 0


func _ready() -> void:
    for i in POOL_SIZE:
        var dn: DamageNumber = damage_number_scene.instantiate()
        dn.visible = false
        add_child(dn)
        _pool.append(dn)


## Call this from any node that receives damage events.
## `world_position` is the attacker or victim's global position in world space.
## Keep this spawner's CanvasLayer transform at identity: the converted value is
## in viewport/HUD canvas coordinates, not OS screen coordinates.
func spawn(world_position: Vector2, amount: int, is_critical: bool = false) -> void:
    # Convert world canvas coordinates to viewport/HUD canvas coordinates.
    var hud_pos: Vector2 = get_viewport().get_canvas_transform() * world_position

    # Wraps around — if POOL_SIZE is too small, older labels get recycled mid-animation.
    var dn := _pool[_pool_index % POOL_SIZE]
    _pool_index += 1

    dn.position = hud_pos
    dn.visible  = true
    dn.show_damage(amount, is_critical)
```



**Connecting to a damage event (GDScript):**

```gdscript
# In the HUD root or the DamageNumberSpawner's _ready:
EventBus.damage_dealt.connect(func(pos: Vector2, amount: int, crit: bool) -> void:
    $DamageNumbersLayer/DamageNumberSpawner.spawn(pos, amount, crit)
)
```



**Pool notes:** The simple modular pool above recycles labels before they finish animating if POOL_SIZE is too small. Increase the pool size or skip pooling entirely for games with infrequent hits. A more robust pool tracks which instances are free using a `free_list` array.

---
