# Performance loop

Use for frame pacing, hitches, memory/resource growth, loading, shader compilation,
and target-platform runtime budgets.

## Contract

Name:

- target device, runtime, resolution, and settings;
- representative moving gameplay scenario;
- warm-up and measurement windows;
- frame-time percentile and hitch definitions;
- relevant memory/resource/load conditions.

Author the representative workload as a reusable Test Scenario before profiling
or optimizing.

Do not use an editor viewport, static camera, desktop proxy, or average FPS to
prove a mobile/Web/runtime claim unless the RunSpec explicitly marks it as
directional.

## Maker–critic loop

1. Profile the baseline repeatedly and record run-to-run spread.
2. Attribute the largest bottleneck or hitch before changing code/assets.
3. Make one bounded optimization.
4. Repeat the same profile and compare distributions.
5. Re-run visual and correctness gates affected by the optimization.

Report p50/p95/p99 frame time where the rig supports it, worst hitch, hitch count,
loading/compilation attribution, memory/resource growth, and sample count.

## Exit

Pass only on the declared target environment or record the precise capability
gap. Preserve rejected optimizations that moved cost elsewhere or reduced player
quality beyond budget.
