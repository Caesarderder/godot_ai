# Game-production Loop guide

This procedure is dormant unless the user explicitly invokes
`caesar-awesome:loop`, `$caesar-awesome loop`, or unambiguously asks to
开启/启动 Caesar Loop. Do not select it from game or quality task signals alone.

Operate as an evidence-gated orchestration protocol for game production:

> Compile ambiguous quality intent into player outcomes, reproducible scenarios,
> and multidimensional quality gates; then improve the real runnable game through
> specialized maker–critic inner loops and a whole-game integration loop.

Do not treat a prompt, critic score, screenshot, passing unit test, or builder
summary as proof that a game outcome was achieved.

## Protocol boundary

Separate four surfaces:

1. **Skill:** compile intent, select profiles, and interpret evidence.
2. **Host:** schedule agents, isolate contexts/workspaces, enforce permissions and
   budgets, persist sessions, and stop or resume runs.
3. **Game evidence rig:** build and launch the game, establish scenarios, capture
   output, profile representative play, and expose test results.
4. **Evaluators:** apply code, model, and human graders to inspected outcomes.

Never claim that the repository supplies a host capability that was not observed.
Compile unavailable capabilities into explicit `unsupported` or
`human_required` gates instead of pretending to execute them.

## Start every run

1. Inspect the repository knowledge route, current game, runtime, ownership,
   validation commands, and existing evidence.
2. Read [references/protocol.md](protocol.md).
3. Record observed host abilities using
   [references/schemas/host-capabilities.schema.json](../schemas/host-capabilities.schema.json).
4. Compile the request into a `RunSpec` using
   [references/prompt-compilation.md](prompt-compilation.md) and
   [references/schemas/run-spec.schema.json](../schemas/run-spec.schema.json).
5. Publish the short human-readable block required by prompt compilation. Treat
   the stored `RunSpec`, not that prose block, as the execution contract.
6. Create or update the visible progress artifact and evidence ledger. Bind every
   result to the current revision/build, environment, scenario, and grader.
7. Inventory all thirteen whole-game quality dimensions in the RunSpec. Mark
   exclusions explicitly as `not_applicable`; every `in_scope` dimension must
   link to a required gate before the run can complete.
8. Before baselining or modifying a work unit, author and validate its reusable
   Test Scenario using
   [references/test-scenario-authoring.md](test-scenario-authoring.md)
   and
   [references/schemas/scenario.schema.json](../schemas/scenario.schema.json).

Do not substitute ad hoc main-scene play, manual navigation, or a conveniently
timed screenshot for an authored Test Scenario.

When resuming across a host Turn or context boundary, validate the run directory
and read `Progress.continuation_anchor` before reading chat history. Its goal,
scope, and in-scope dimension snapshot must still match RunSpec. Use its
`next_action`, current revision, active unit, open findings, and stale gates to
reconstruct work; repair artifact drift before making another candidate.

Use the examples in `assets/templates/`. Validate protocol files with:

```bash
python3 .codex/skills/caesar-awesome/scripts/validate_loop_protocol.py
```

## Select only the necessary inner loops

Load the matching profile before creating a work unit:

| Claim or gap | Profile |
|---|---|
| Build, state, interaction, restart, save, regression | [correctness](../profiles/correctness-loop.md) |
| Composition, material, lighting, VFX, HUD presentation | [visual](../profiles/visual-loop.md) |
| Input response, movement, camera, impact, combat feel | [game feel](../profiles/game-feel-loop.md) |
| Frame time, hitches, memory/resource growth, loading | [performance](../profiles/performance-loop.md) |
| Goal comprehension, learning, recovery, choice, replay | [player learning](../profiles/player-learning-loop.md) |

Keep visual, correctness, performance, accessibility, and player-experience gates
separate. Never average them into a single readiness score.

For visual production, additionally read
[references/visual-production-pipeline.md](visual-production-pipeline.md).
Before parallel work, read
[references/project-structure.md](project-structure.md).

## Execute one evidence-gated work unit

Express every unit as:

`owner → player contribution → allowed surface → scenario → gate → evidence route → rollback`

Then:

1. Select the highest-value unblocked gap that can be judged with current
   capabilities. Respect already frozen gates.
2. Author or reuse a task-specific Test Scenario. Prove that it establishes,
   drives, observes, and resets the intended state through shipping systems.
   For feature work, use a parameterized dedicated fixture and batch the declared
   action/state/viewpoint matrix into one review execution.
3. Give the maker one bounded gap, ownership boundary, scenario, acceptance
   assertions, current evidence, and rollback condition.
4. Make the maker change the real artifact and produce an `IterationResult`.
5. Run deterministic graders before subjective graders.
6. When model critique is appropriate, use a fresh isolated child-agent critic.
   Hide builder
   rationale, desired conclusions, candidate order, and revision identity.
   Record the child thread identity in Evidence. Maker self-review,
   `non_independent` critique, or independent critique without a child thread ID
   may guide another iteration but cannot pass a required model or mixed gate.
7. Make the critic inspect the consolidated execution bundle before asking for
   more evidence. Record the verdict as evidence and the actionable defect as a
   `Finding`.
8. Accept the candidate only if its target gate improves without invalidating a
   frozen gate or exceeding the regression budget.
9. Repeat, pivot, escalate, or stop according to the state machine and budgets.

Use [references/loop-templates.md](loop-templates.md) for role briefs
and [references/quality-scorecard.md](quality-scorecard.md) for
assessment structure.

## Integrate at declared checkpoints

Do not inspect the whole runnable game after each local maker–critic iteration.
The production main scene is an integration surface, not a feature review
instrument. Keep local review in the focused fixture and reuse its one-run
artifact bundle.

Run the RunSpec's named whole-path integration scenario only after a declared
trigger: focused gates pass for an accepted candidate, shared contracts or the
composition root changed, the bounded wave closes, or completion review is next.
Use at most one main-scene launch per wave and revision unless the run itself was
invalid. Then re-run affected frozen gates and check:

- player path and objective continuity;
- shared contracts and lifecycle;
- camera, input, lighting, audio, UI, and style cohesion;
- correctness and save/restart regressions;
- target-platform frame pacing and resource behavior;
- evidence freshness at the integrated revision.

Integration owns shared-contract changes. Builders must not silently edit outside
their ownership boundary. Do not rerun an unchanged integrated revision.

## Evidence and completion rules

Prefer graders in this order:

1. build, tests, static rules, and environment-state assertions;
2. reproducible runtime scenarios and measurements;
3. deterministic capture/diff for pixel-neutral claims;
4. fresh comparative model critique for subjective observable claims;
5. target-player observation for comprehension, feel, and fun.

An agent assessment may prioritize visual or experiential work, but cannot prove
fun, target-player understanding, accessibility on unavailable devices, or
release readiness.

Only enter `completed` when every in-scope whole-game quality dimension is
covered by a required gate, every required gate has current evidence for the
integrated revision, every gate requiring subjective critique has independent
child-agent critic evidence, and no required finding remains open. Otherwise finish with
the precise protocol result such as `budget_exhausted`, `no_material_progress`,
`human_required`, `capability_unavailable`, `regression_limit`, `user_stopped`,
or `failed`.

Preserve rejected candidates, stale evidence, failed gates, unavailable evidence,
and disproven approaches so a later run does not repeat them.

## Project progress projection

When the repository provides Caesar Workbench, keep the run visible without
creating a second source of truth:

1. Store one run in a repository-local directory containing `run-spec.json`,
   `progress.json`, optional `host-capabilities.json`, and the `evidence/`,
   `findings/`, and `iterations/` ledgers.
2. After scenario, gate, finding, evidence, iteration, decision, or state changes,
   validate and project the run into both the project knowledge map and HQ:

   ```bash
   python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py loop-sync \
     --run-dir "run-directory" --task "matching HQ task"
   ```

3. Treat the generated `docs/workbench/loops/<run-id>.md` node, the `loop` fence
   in `docs/workbench/hq.md`, and the HTML dashboard as read-only projections.
   Repair disagreement from the JSON artifacts and sync again; never repair the
   run by editing a projection.
4. Do not move the HQ task to completed until the Caesar Loop completion rules
   are satisfied. Terminal non-success states remain visible with their precise
   result.
