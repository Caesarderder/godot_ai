# Ownership and evidence map

| Owner | Surface | Public contract | Scenario | Acceptance evidence | Coupling |
|---|---|---|---|---|---|
| Integrator | `game/three_lane_arena.gd` | production input mapped to `ThreeLaneMatch` commands | `three-lane-inventory-review` | boot + capture | sequential composition/input/presentation |
| Match | `features/match/three_lane_match.gd` | `tick`, player commands, normalized `lane_position`, `summary` | three-lane match, spatial abilities and respawn | domain tests | coupled combat/economy/spatial authority |
| Legacy slice | `game/moba_game.gd`, `features/match/lane_state.gd` | `MobaGame` actions, `run_finished` | `lane_action_peak` | legacy functional test | preserved regression surface |
| Combat | `features/combat/lane_ability.gd` | cast/cooldown methods | Q/E review | functional test | independent |
| Evidence | `tools/`, `tests/` | named commands/output paths and hashed CSV manifests | action, respawn and paired range captures | scripts, state manifests and artifacts | development-only |

The root wires state and ability only. Debug review helpers are development-only and are not player input paths. Visual capture is directional until a deterministic frame driver and image-diff baseline are added.
