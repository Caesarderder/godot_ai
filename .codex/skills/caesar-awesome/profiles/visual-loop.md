# Visual loop

Use for composition, silhouette, materials, lighting, atmosphere, VFX, animation
presentation, and HUD hierarchy.

Read `../references/visual-production-pipeline.md` before assigning visual work.

## Scenarios

Author the task-specific Test Scenario before visual changes. At minimum define:

- establishing/gameplay;
- close form/material;
- UI under action;
- alternate lighting or gameplay stress when relevant.

Put these conditions into one focused scenario's coverage matrix and capture
them as indexed checkpoints in one execution bundle where feasible. Fix camera,
viewport, state, seed, settle-frame budget, and temporal reset for strict
comparisons. If the rig is not deterministic, label comparisons `directional`.

## Maker–critic loop

1. Preserve a canonical baseline.
2. Give the maker one player-visible gap and the coupled look owner.
3. Run the focused scenario once and verify its case/viewpoint/artifact manifest.
4. Randomize A/B identity and give a fresh critic the consolidated bundle,
   rubric, and limits—not the maker narrative.
5. Record winner, confidence, direct observation, one bounded repair, and
   unavailable evidence.
6. Reject a visual win that breaks gameplay legibility, accessibility, or the
   performance budget.

Do not respond to each critic question with another manual screenshot. A missing
declared checkpoint reruns the focused fixture under its extra-launch policy; a
new hypothesis updates the scenario contract before more evidence is collected.

Use pixel diff only for pixel-neutral regression claims. Visual improvement needs
comparative judgment; a lower pixel difference is not an aesthetic score.

## Exit

Pass the declared visual gates separately. Do not infer game feel or fun from
captures.
