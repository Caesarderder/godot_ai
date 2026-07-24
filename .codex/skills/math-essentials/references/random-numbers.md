# Random Number Generation

Reference for `skills/math-essentials/SKILL.md` — global random functions, `RandomNumberGenerator` (seeded), weighted random selection, noise (procedural generation).

> ← Back to [SKILL.md](../SKILL.md)

---
## 5. Random Number Generation

### Global Functions

```gdscript
var f: float = randf()                    # 0.0 to 1.0
var i: int = randi()                      # full int range
var ranged: float = randf_range(1.0, 10.0)  # 1.0 to 10.0
var ranged_int: int = randi_range(1, 6)   # 1 to 6 (inclusive)
```


### RandomNumberGenerator (Seeded)

For deterministic, reproducible randomness (procedural generation, replays).

```gdscript
var rng := RandomNumberGenerator.new()
rng.seed = 12345  # same seed = same sequence every time

var value: float = rng.randf_range(0.0, 100.0)
var roll: int = rng.randi_range(1, 20)
var normal: float = rng.randfn(0.0, 1.0)  # Gaussian distribution
```


### Weighted Random Selection

```gdscript
# Weighted random pick from a loot table
func weighted_random(table: Array[Dictionary]) -> Dictionary:
    # table = [{"item": "gold", "weight": 60}, {"item": "gem", "weight": 30}, {"item": "rare", "weight": 10}]
    var total_weight: float = 0.0
    for entry in table:
        total_weight += entry["weight"]

    var roll: float = randf() * total_weight
    var cumulative: float = 0.0
    for entry in table:
        cumulative += entry["weight"]
        if roll <= cumulative:
            return entry

    return table.back()
```


### Noise (Procedural Generation)

```gdscript
var noise := FastNoiseLite.new()
noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
noise.frequency = 0.05
noise.seed = randi()

# Sample 2D noise at a position
var height: float = noise.get_noise_2d(x, y)  # returns -1.0 to 1.0
```


---
