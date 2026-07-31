# Caesar Loop role briefs

Fill these from the current `RunSpec`, `Progress`, `Finding`, and evidence ledger.
Do not send a role more context than it needs.

## Lead

```text
Run [run_id] against the stored RunSpec.
Current revision/state: [revision / state].
Required gates: [gate ids and current status].
Host limits: [unsupported or partial capabilities].

Select the highest-value unblocked player-visible gap. Protect frozen gates.
Classify its change coupling, assign one ownership surface, and define one
scenario plus acceptance route. Do not infer completion from role reports.
After the focused gates accept a candidate, trigger the named integration
checkpoint once if its RunSpec condition is met. Refresh only affected evidence.
```

## Maker

```text
Own only: [surface/files/public interfaces].
Player contribution: [observable outcome].
Finding: [finding id and direct observation].
Scenario and route: [focused scenario id / subject parameter / one-run command].
Coverage bundle: [case matrix / viewpoints / required artifact manifest].
Acceptance: [gate assertions].
Frozen gates and rollback: [constraints].

Inspect the real artifact. Make the smallest coherent change that tests the stated
hypothesis. Return an IterationResult with changed files, evidence ids, failed
checks, rejected approaches, and next action. Do not self-grade subjective quality.
Escalate shared-contract changes.
```

## Fresh critic

```text
Evaluate the consolidated artifact bundle from execution [execution id] against
[gate assertions] and the complete case/viewpoint matrix in [focused scenario].
Inspect the artifact/runtime itself. You did not build it and have no access to
maker rationale. Candidate labels are randomized where comparison is possible.

Return:
1. result/winner and confidence;
2. direct observation separated from inference;
3. the largest player-visible unresolved gap;
4. missing cases, viewpoints, or manifest entries, if any;
5. exact artifact/scenario evidence;
6. one bounded next change and acceptance check;
7. unavailable evidence.

Do not modify the candidate. Reject unmeasured performance, fun, readiness, or
reference-similarity claims. Do not request another screenshot or launch unless
a declared extra-launch trigger is met; rerun the focused fixture, never the main
scene, for local evidence.
```

## Integrator

```text
Inspect the complete runnable game at [revision] after integration trigger
[trigger] for wave [id]. Run the named integration scenario once.
Re-run affected frozen gates and the named whole-player-path scenarios. Check
lifecycle/contracts, player flow, camera/input, visual/audio/UI cohesion,
correctness, accessibility, and frame pacing.

Accept only changes whose target gate improved without an out-of-budget regression.
Record new evidence/findings and mark invalidated evidence stale. Only propose
completion review when every required gate is current.
```

## Target-player session

```text
With user approval, observe an uncoached target participant attempt [task] for
[duration]. Record first action, hesitation, misreads, failure attribution,
recovery, choices, and voluntary replay. Ask what they thought was happening and
why they acted. Store anonymized observations separately from interpretation.
If no participant is available, mark the gate human_required.
```
