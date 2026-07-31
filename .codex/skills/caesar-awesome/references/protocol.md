# Caesar Loop protocol

Use this document to translate the skill contract into an inspectable run.

## Canonical artifacts

| Artifact | Authority |
|---|---|
| `RunSpec` | Goal, player outcome, scenarios, gates, constraints, budgets, and stop policy |
| `HostCapabilities` | What the current orchestration host can actually execute |
| `Progress` | Current state, active unit, frozen gates, iteration counters, and decisions |
| `IterationResult` | One maker attempt, changes, produced evidence, and next request |
| `EvidenceRecord` | Revision-bound observation or measurement supporting one claim |
| `Finding` | Open, resolved, accepted, or blocked gap with severity and evidence |

The schemas under `schemas/` define stable machine-readable boundaries. The
examples under `assets/templates/` are starting instances, not hidden state.

`Progress.continuation_anchor` is the durable cross-Turn resume surface. The
managed writer derives its goal, scope, and in-scope dimension snapshot from
RunSpec and updates its next action during state transitions. A resumed agent
must validate the run and reconstruct work from this anchor, current revision,
gate state, findings, and evidence rather than from chat recollection.

## State machine

```text
draft
  → scenario_authoring
  → baselining
  → slice_building
  → unit_looping
  → integrating
  → player_validating
  → completion_review
  → completed
```

Any active state may transition to:

- `blocked`: an external decision or dependency is required;
- `human_required`: a required experiential gate needs an unavailable person;
- `capability_unavailable`: the host or evidence rig cannot run a required route;
- `budget_exhausted`: a declared cost, time, turn, or retry limit was reached;
- `no_material_progress`: the no-progress window expired;
- `regression_limit`: accepted/frozen behavior repeatedly regressed;
- `user_stopped`: the user ended the run;
- `failed`: an unrecoverable protocol or environment error occurred.

Do not use a terminal label to conceal missing evidence. Record every unavailable
gate separately.

## Transition gates

| Transition | Required evidence |
|---|---|
| `draft → scenario_authoring` | Valid `RunSpec`, capability audit, ownership and evidence routes |
| `scenario_authoring → baselining` | Every required initial gate has a validated reusable Test Scenario |
| `baselining → slice_building` | Baseline or explicit `missing` record for each required claim |
| `slice_building → unit_looping` | Real end-to-end playable path boots and exposes the target outcome |
| `unit_looping → integrating` | Active work units closed or explicitly deferred; local gates evaluated |
| `integrating → player_validating` | Integrated revision passes required automated/runtime gates |
| `integrating → completion_review` | No required human gate exists |
| `player_validating → completion_review` | Target-player evidence recorded or gate marked unavailable |
| `completion_review → completed` | Every required gate has fresh passing evidence and no required finding is open |

## Inner-loop decision

Choose a work item by:

1. excluding blocked and unsupported gaps;
2. excluding work outside the run scope;
3. protecting frozen gates;
4. ranking player impact, severity, evidence strength, coupling cost, and
   reversibility;
5. selecting one bounded gap whose acceptance can be observed this iteration.

Do not blindly alternate between the current highest critic scores. Detect
oscillation through repeated findings, reverts, unchanged evidence, or parameter
changes that move back and forth. Pivot the approach or stop after the configured
retry/no-progress threshold.

## Test Scenario gate

Do not start a maker iteration until its Test Scenario is authored and validated.
A scenario is a durable review instrument, not a screenshot convenience. It must:

- name the player-facing question and linked gates;
- establish state deterministically where feasible;
- exercise real shipping systems through public or development-only adapters;
- define inputs, camera/view, seed/clock, warm-up, shutter or measurement window;
- expose direct observations and failure conditions;
- reset temporal and persistent state;
- provide a fast review route and a strict regression route;
- use a dedicated feature fixture for local work and parameterize its subject;
- cover declared action/state/viewpoint cases in one launch where feasible;
- emit one execution ID, exact case results, and a complete artifact manifest;
- remain isolated from shipping gameplay logic.

The fast route optimizes critic turnaround. The strict route optimizes comparable,
repeatable evidence. They share the focused fixture and coverage matrix, but only
strict-route evidence can close a deterministic regression gate. A critic first
inspects the consolidated execution bundle and may request another focused run
only when a declared extra-launch trigger is met.

## Evidence lifecycle

Every evidence record must identify:

- claim and gate;
- source revision or build identifier;
- named scenario;
- environment and target platform/device;
- artifact path or command;
- grader and grader version;
- direct observation;
- result and confidence;
- limitations.

Relevant source, asset, configuration, tool, scenario, or grader changes make
only the affected evidence stale. `revision-set` must name affected gate IDs (or
explicitly select all gates for a genuinely global change). Unaffected evidence
keeps its source revision and records the revision through which its impact was
audited. Stale evidence remains in history but cannot close a current gate.

## Critic integrity

A fresh critic must:

- run in a context isolated from the maker;
- inspect the actual artifact or runtime evidence;
- not receive maker rationale or desired verdict;
- receive randomized A/B identity when paired comparison is practical;
- use a versioned rubric and calibration examples where available;
- return observations separately from inference;
- not modify the candidate under review.

If the host cannot provide these properties, label the review `non_independent`.
Every required model or mixed gate must set `independent_critic: true`. Passing
evidence for such a gate must be a `model_critique` with
`grader.independence: independent` and a non-empty child `agent_thread_id`.
Self-review and non-independent critique remain historical or directional
evidence and cannot close the gate.

## Whole-game quality ledger

Every RunSpec must account for the complete thirteen-dimension quality ledger:
assets/modeling; materials/shaders/lighting; motion/VFX; UI/UX;
interaction/camera/physics; gameplay/levels/AI; balance/economy/progression;
narrative/content; audio; learning/replay; accessibility/localization;
correctness/data/lifecycle; and performance/stability.

Mark each dimension `in_scope` or `not_applicable` with a concrete rationale.
Every in-scope dimension must reference at least one required gate. This ledger
does not force work on irrelevant surfaces; it prevents a focused success from
silently becoming a whole-game completion claim.

## Conditional global integration

Local improvement is not completion, but the production main scene is not a
local review harness. Continue maker–critic iterations in dedicated focused
fixtures. Run a named whole-path integration scenario only when the RunSpec
trigger fires: focused gates produced an accepted candidate, a shared contract
or composition root changed, the declared batch/wave closes, or completion
review is next. Run the main scene at most once per wave/revision unless the
integration run itself was invalid.

At that checkpoint, the integrator checks the complete player path and re-runs
affected frozen gates. A candidate that improves its target but causes an
out-of-budget regression is rejected or reverted.

The integration loop is the only loop that may declare a completion candidate.
If integration, player validation, or completion review exposes a required gap,
return to `unit_looping`, persist the next action in the continuation anchor,
and keep the rejected completion attempt in history.

## Run directory and Workbench projection

Use this repository-local layout so validation, handoff, and replay do not depend
on chat history:

```text
<run-dir>/
├── run-spec.json
├── progress.json
├── host-capabilities.json        # optional
├── evidence/*.json
├── findings/*.json
└── iterations/*.json
```

`RunSpec`, `Progress`, `EvidenceRecord`, `Finding`, and `IterationResult` remain
authoritative. If Caesar Workbench exists, `loop-sync` validates these artifacts,
generates `docs/workbench/loops/<run-id>.md` as a durable knowledge-map node, and
produces a concise `loop #<run_id>` projection in `docs/workbench/hq.md`. These
projections support discovery, situational awareness, handoff, and review
routing; they must not be used to close gates or reconstruct missing evidence.
