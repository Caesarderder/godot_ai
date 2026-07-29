# Project B verification plan

## Evidence levels

- Static: files and references exist.
- Engine-valid: import, parse, and bounded main-scene start pass.
- First-playable verified: real scene lifecycle reaches win, loss, and restart through public gameplay owners.
- Visual-reviewed: current runtime captures pass a structured independent review.
- Human-observed: requires representative people and is not part of automated completion.

No test or screenshot proves “AAA,” fun, or superiority over a current commercial game.

## Deterministic checks

`tests/run_fps_vertical_slice_tests.gd` loads the real `fps_game.tscn` and verifies:

1. input actions and main scene exist;
2. player reset restores spawn, health, motion, and active input state;
3. rifle rejects fire during cadence/reload, decrements ammo once, and completes reload from reserve;
4. a stable attack instance cannot damage the same target twice;
5. accepted hits clamp health and death is idempotent;
6. enemy attack intent reduces player health only while the run is active;
7. eliminating all enemies yields exactly one victory;
8. lethal player damage yields exactly one failure;
9. restart restores all enemies, player, weapon, objective, run stats, and HUD;
10. signal connections do not multiply across repeated restart.

## Commands

```bash
godot --version
godot --headless --path project-b --import
godot --headless --path project-b --quit-after 3
godot --headless --path project-b -s tests/run_fps_vertical_slice_tests.gd
godot --path project-b -s tools/capture_fps_review.gd
git diff --check
```

Record that local Godot is 4.7.1 while the target contract is 4.6.3. A local 4.7.1 pass does not close the 4.6.3 release gate.

## Capture contract

The capture tool loads the real main scene at 1280×720 and uses public debug/setup entry points to establish deterministic states:

- `quiet_entry.png`
- `combat_peak.png`
- `low_health_reload.png`
- `victory.png`
- `failure.png`

It must wait for rendered frames, save viewport pixels under `project-b/artifacts/`, report failures, and exit nonzero on missing nodes or save errors.

## Independent harsh visual verdict

For every visual iteration, a separate reviewer receives the current capture, visual contract, and no implementation explanation. Output:

```json
{
  "score": 0,
  "verdict": "reject|revise|pass",
  "category_match": "near-future tactical FPS",
  "differences": [],
  "suggestions": [],
  "reasoning": ""
}
```

Passing threshold is `score >= 90`, but the score means “passes this project’s visual-direction contract,” not parity with Call of Duty. The reviewer must reject flat lighting, weak silhouettes, unreadable target/threat state, UI obstruction, inconsistent materials, default-control styling, and screenshots that avoid peak combat.

## Completion report

Report each surface separately: exact engine version, import, bounded start, scene-loop test, capture command, inspected images, critic verdict, browser/export status, and human playtest status. Use `NOT RUN` instead of converting missing evidence into warnings.
