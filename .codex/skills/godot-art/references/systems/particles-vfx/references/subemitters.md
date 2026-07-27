# Subemitters


> ← Back to [SKILL.md](../SKILL.md)

---
## 6. Subemitters

Subemitters are child particle systems that spawn in response to parent particle events.

### Trigger Modes

| Mode           | Spawns When                          | Key Property            |
|----------------|--------------------------------------|-------------------------|
| `Constant`     | At regular intervals per particle    | `frequency` (per second)|
| `At End`       | When a parent particle dies          | `amount_at_end`         |
| `At Collision` | When a particle hits a collision node| `amount_at_collision`   |

### Setup

1. Create two GPUParticles3D nodes in the same scene
2. On the parent's ParticleProcessMaterial → Sub Emitter → assign the child system
3. Set the sub emitter **Mode** and amount/frequency

```gdscript
# Parent material setup
var parent_mat := ParticleProcessMaterial.new()
parent_mat.sub_emitter_mode = ParticleProcessMaterial.SUB_EMITTER_AT_END
parent_mat.sub_emitter_amount_at_end = 8
parent_mat.sub_emitter_keep_velocity = true

# Assign child particle system as sub-emitter
$ParentParticles.process_material = parent_mat
parent_mat.sub_emitter_node = $ChildParticles.get_path()
```



### Limitations

- Child particle **amount** caps the total active sub-emitter particles
- `explosiveness` has no effect on subemitters
- A system cannot be its own subemitter
- Subemitters can chain (sub-sub-emitters) but watch performance

---
