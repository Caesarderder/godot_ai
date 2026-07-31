# Test Scenario authoring

Author the review instrument before modifying the game. For a feature work unit,
default to a dedicated, development-only test scene or component fixture. It
must instantiate the real shipping owner through public adapters, not navigate
the production main scene. The scenario determines which facts a critic can
observe, how quickly they can observe them, and whether later iterations remain
comparable.

## Scenario design

Start from one subtask and ask:

1. What player-facing question must this work answer?
2. Which exact state exposes success and failure most clearly?
3. Which shipping systems must be exercised?
4. What inputs or timeline create the decisive moment?
5. What must be captured, measured, or asserted?
6. What state can leak between runs?
7. How will a fresh critic reproduce this without builder explanation?
8. Which action, state, direction, and viewpoint cases can one launch cover?
9. Which subject parameter lets the fixture accept the next compatible asset or
   feature without cloning the scene?

Create an instance of `schemas/scenario.schema.json`.

## Focused fixture first

Classify each scenario as `focused_feature` or `whole_path_integration`.

- A `focused_feature` scenario must use `dedicated_test_scene`. Parameterize the
  subject, such as `weapon_id`, and keep a stable extension contract for future
  compatible subjects.
- A `whole_path_integration` scenario may use `main_scene`, but only through the
  RunSpec's conditional integration policy.
- Local maker–critic iterations use the focused fixture. Do not launch the main
  scene to inspect one weapon, enemy, UI panel, effect, or other bounded work
  unit.

For a weapon fixture, one run should normally cover single fire, sustained fire,
partial reload, empty-magazine/dry-fire, recovery, multiple aim directions, and
canonical first-person/side/rear/muzzle/target views. Adapt the matrix to the
feature; do not hard-code weapon assumptions into a generic project.

## One-run coverage matrix

Write `coverage_matrix` before implementation. Every case names its state,
stimuli, viewpoints, assertions, and observation IDs. Prefer
`single_run_matrix`: sequence all cases in one launch, reset case-local state
inside the fixture, and emit one consolidated artifact manifest containing the
state trace, time-series data, captures/contact sheet or video, assertions, and
exit status.

The critic reviews that bundle as a whole. Do not request one screenshot, rerun,
request another angle, and rerun again. An extra launch is allowed only for a
declared trigger such as an incomplete manifest, a failure that contaminated
later cases, or a claim that genuinely requires fresh-process isolation.

## Required architecture

Keep scenario setup in a development-only surface. It may use a documented debug
adapter to establish seed, state, pose, inventory, encounter phase, camera, or
time, but the observed action and consequence must flow through the same shipping
systems used by players.

Do not:

- duplicate gameplay logic inside the scenario;
- write test-only success paths into production code;
- rely on manual walking or arbitrary wall-clock delays;
- reuse dirty save, particle, decal, exposure, animation, or temporal history;
- capture whichever frame happens to look favorable;
- make a screenshot-only scenario for a time-dependent claim.

## Two routes

Every scenario defines:

### Fast review route

Optimize for maker/critic turnaround. Launch directly into the decisive state,
produce the smallest useful artifacts, and target a short bounded duration. This
route may use bounded determinism and directional visual evidence.

### Strict regression route

Optimize for comparable evidence. Use a fresh process/page/session where temporal
state can leak; fix environment, seed, clock, viewport, camera, warm-up, stimulus,
observation window, output names, and failure exit code.

The routes must share the same fixture, subject parameter, coverage intent, and
artifact vocabulary. A fast route cannot close a strict gate merely because it
is convenient.

## Validation before use

When a scenario is first authored, or its contract/fixture changes, run it twice
from a clean reset. Confirm:

- it reaches the same decisive state;
- its actions use real runtime owners;
- its outputs and failure conditions are unambiguous;
- it does not mutate unrelated persistent state;
- a fresh reviewer can run it from the contract alone;
- runtime and artifact production fit the declared turnaround budget.

Only then establish the baseline and begin the maker–critic loop. Do not repeat
this qualification on every candidate revision unless the scenario contract,
fixture, adapter, environment, or evidence rig changed.

## Reuse and versioning

Treat a useful scenario as durable project infrastructure. Keep its ID stable,
version its contract when semantics change, and map it to multiple gates only
when the observation windows genuinely cover them. Record scenario changes as
evidence-invalidating changes.

After a candidate changes, invalidate only gates whose owned shipping surface,
scenario adapter, environment, or grader was affected. Carry unrelated evidence
forward explicitly; do not make a local revision stale every screenshot and
frozen gate in the run.
