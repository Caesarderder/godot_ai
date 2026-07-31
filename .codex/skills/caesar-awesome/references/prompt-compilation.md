# Prompt and RunSpec compilation

Compile the user's request twice:

1. a short human-readable Gauntlet prompt;
2. a machine-readable `RunSpec` that remains authoritative.

## Extract

Derive from repository evidence and user intent:

- target player, platform, and 20–60 second player outcome;
- control, threat, meaningful choice, feedback, and resolution;
- one or two inspectable comparisons or measurements and their limits;
- engine/runtime, licensing, accessibility, scope, and budget constraints;
- named reproducible scenarios;
- independent quality gates and matching graders;
- ownership/coupling boundaries;
- host capabilities and unsupported evidence routes;
- iteration, regression, no-progress, and terminal policies.

Do not turn a feature inventory into the player outcome. Do not use `AAA`,
`beautiful`, `polished`, or `fun` as a gate without observable assertions.

## First visible deliverable

Publish exactly:

```markdown
Quality bar: [concrete comparison or measurement, plus its limit]

Gauntlet Loop prompt:
> [80–180 words in the user's language]

Execution contract: [initial runnable slice, first scenario, and first evidence]
```

The prompt must state:

- the player outcome and inspectable quality bar;
- a lead that decomposes work by evidence and change coupling;
- bounded makers and fresh critics that inspect real artifacts;
- repeated repair of evidence-backed gaps;
- a visible evidence/progress record and whole-game integration;
- original/licensed asset rules and the required performance/player evidence.

Do not insert a fixed agent count, fixed round count, detailed architecture, or
speculative task list. The prompt is a concise projection of the `RunSpec`, not a
replacement for it.

## RunSpec compilation

Create a JSON instance conforming to
`schemas/run-spec.schema.json`. Validate that:

- every gate refers to an authored Test Scenario conforming to
  `schemas/scenario.schema.json`;
- every scenario has a fast review route and strict regression route;
- every feature work unit uses a parameterized dedicated fixture with an
  action/state/viewpoint coverage matrix and one-run artifact manifest;
- the RunSpec names whole-path integration scenarios and conditional escalation
  triggers instead of using the main scene for local review;
- every required gate has an executable, human-required, or explicitly
  unsupported grader route;
- every comparison states what it cannot prove;
- budgets and terminal results are explicit;
- parallelizable work has an owner, public contract, and independent scenario;
- unavailable host capabilities do not become fictional execution steps.

Use `assets/templates/run-spec.json` as a shape example.

## Reject before execution

- no real runnable outcome;
- no authored, resettable Test Scenario for the first work unit;
- a focused feature scenario that launches the production main scene;
- screenshot-by-screenshot review instead of one declared coverage execution;
- one aggregate quality score replacing separate gates;
- critic reads only the maker report;
- visual evidence used to prove feel or fun;
- performance claims without target environment and measurement window;
- reference assets authorized as comparison but copied into the shipped game;
- infinite retry language without budgets or no-progress detection;
- prose-only state with no revision-bound evidence ledger.
