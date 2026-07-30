# Starfall: Lane Protocol

An original 2D three-lane MOBA prototype for Godot 4.7.1. It intentionally proves a small playable loop rather than claiming equivalence to any commercial MOBA.

Three-lane controls: `Tab` cycles all five Dawn heroes, `W` selects top lane, `S` selects bottom lane, `Q` casts the controlled hero's signature, `E` recovers the selected lane, `F` buys Pulse Lens, and `R` cleanly resets the match.

```bash
/opt/homebrew/bin/godot --headless --path project-c --import
/opt/homebrew/bin/godot --headless --path project-c --quit-after 2
/opt/homebrew/bin/godot --headless --path project-c -s tests/run_moba_vertical_slice_tests.gd
/opt/homebrew/bin/godot --path project-c -s tools/capture_moba_review.gd # requires a rendered session
/opt/homebrew/bin/godot --headless --path project-c -s tools/profile_moba_stress.gd # smoke only
/opt/homebrew/bin/godot --path project-c
```

See `docs/player-outcome.md`, `docs/ownership-map.md`, and `docs/progress.md` for the quality boundary and outstanding gates.

The production target and non-copying boundary are in `docs/moba-production-contract.md`. The new rule/data contracts can be checked with:

```bash
/opt/homebrew/bin/godot --headless --path project-c -s tests/run_moba_domain_tests.gd
/opt/homebrew/bin/godot --headless --path project-c -s tests/run_three_lane_interaction_tests.gd
/opt/homebrew/bin/godot --path project-c -s tools/capture_three_lane_review.gd
/opt/homebrew/bin/godot --path project-c -s tools/capture_hero_silhouette_review.gd
/opt/homebrew/bin/godot --path project-c -s tools/capture_three_lane_sequence.gd
/opt/homebrew/bin/godot --path project-c -s tools/capture_respawn_animation.gd
/opt/homebrew/bin/godot --path project-c -s tools/capture_five_hero_abilities.gd
/opt/homebrew/bin/godot --path project-c -s tools/capture_spatial_range_pair.gd
```
