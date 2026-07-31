# Quality gate assessment card

Assess only from directly inspected evidence. An assessment prioritizes work; it is not a release claim.

| Dimension | Inspect | Failure signals |
|---|---|---|
| Composition and hierarchy | player camera / named shots | unclear focal point, unreadable threat or objective |
| Form and material | close detail and movement | flat silhouette, tiled/procedural repetition, incoherent roughness/light response |
| Lighting and atmosphere | exterior, interior, action scenarios | crushed values, floating objects, no depth separation, unstable exposure |
| Motion and impact | input, firing, hit, damage, death/recovery | latency, missing anticipation/follow-through, no readable cause/effect |
| Gameplay legibility | blind first attempt | player cannot identify goal, risk, affordance, or result |
| Frame pacing | representative play at target settings | hitches, compilation stutters, resource growth, misleading average FPS |
| Cohesion | full run after a wave | individually polished parts with incompatible scale, color, camera, or audio |

For every assessment, attach the `gate_id`, scenario, revision, artifact path or
command, direct observation, inference (if any), confidence, grader version, and
largest next gap. Use `not_run`, `human_required`, or `unsupported` when evidence
is unavailable. Never average assessments into a quality claim. Assessments
prioritize work; they cannot certify fun, readiness, or release quality.

## Gate vector

Report quality as independent gate state:

```text
build: pass
functional: pass
visual_composition: fail
game_feel: human_required
frame_pacing: stale
accessibility: not_run
player_learning: human_required
```

One aggregate number must not hide a failed required gate. When a gate passes,
freeze it if the RunSpec requests `freeze_on_pass`; later integration must rerun
it whenever a relevant source or environment changes.

## Evidence-rig audit

- Capture gates use an isolated, repeatable scenario with fixed camera/state/frame budget; if temporal state can leak, use a fresh session/page per capture.
- A focused feature review emits one execution bundle covering every declared
  case and viewpoint. Prefer a contact sheet, indexed sequence, timeline, and
  assertion report over repeated manual screenshot requests.
- The capture driver controls the shutter frame. Wall-clock boot duration, browser round trips, and warm-up must not silently advance simulation.
- Pixel-neutral claims compare against a canonical baseline with a pixel diff; a visible-improvement claim needs independent comparative review instead.
- Performance profiles exercise representative play, not only a static camera, and report percentiles, worst hitches, compilation/resource attribution, and run-to-run spread.
- Keep failed gates and rejected candidate changes alongside passing evidence.
- Bind evidence to the current revision, scenario, environment, and grader
  version; mark it stale after relevant changes.
- Randomize A/B identity and withhold maker rationale for independent critique.
- Detect critic drift with versioned rubrics and calibrated example judgments
  where the project has them.

## Exit checklist

- [ ] Player outcome contract and quality bar are explicit.
- [ ] Baseline exists for every claim being improved.
- [ ] A reusable focused fixture and complete one-run coverage bundle exist where local visual comparison matters.
- [ ] Builders and critics were separated for important units.
- [ ] At least one integration pass inspected the complete game.
- [ ] Build/runtime, functional, and performance gates were run or explicitly marked unavailable.
- [ ] Target-player evidence exists for core-loop fun/readability, or is explicitly outstanding.
- [ ] Parallel work was limited to independent ownership boundaries; coupled work received an integration owner.
- [ ] Evidence, inference, failed gates, and rejected changes are retained in the progress artifact.
- [ ] Known gaps and evidence limits are reported honestly.
- [ ] Required gates have current evidence for the integrated revision.
- [ ] No required finding remains open or disguised as an aggregate score.
