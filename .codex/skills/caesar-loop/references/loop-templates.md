# Caesar Loop templates

Use these as task prompts. Replace bracketed fields with project evidence. Keep each task scoped to one outcome.

## Generated Gauntlet prompt

Generate this from the user's requirement; do not expose bracketed placeholders in the final prompt.

```
Build [outcome] for [target player/platform]. Compare the running result against
[concrete quality bar]. Act as the lead: decide the smallest independently judgeable
units and keep coupled concerns together; only parallelize units with explicit
ownership, stable interfaces, and named evidence scenarios. The host orchestrator,
not the game repository, owns agent scheduling and persistence. For each important unit, use a builder and
a fresh harsh critic with no builder rationale; the critic must inspect the real
artifact and evidence, run blind A/B against the bar when practical, select the
winner, and return the largest meaningful gap. Loop that gap back to a builder until
we meet the bar or I stop the run. Maintain a live progress page. Use only licensed
or original shipped assets. After each wave, run a fresh whole-game integration pass
and prove visual, performance, functional, and target-player claims with the matching
evidence. Do not stop at "pretty good."
```

## Lead brief

```
Run the published Gauntlet Loop prompt for [GAME / FEATURE].

Player outcome: [a player can … in 20–60 seconds].
Quality bar: [specific reference situation or measurable target].
Constraints: [engine, platform, licensing, performance, scope].
Evidence rig: [named scenarios, capture command/path, tests, profiling route].
Orchestration boundary: [host capabilities and visible progress artifact].
Ownership map: [composition root; feature/subsystem owners; shared contracts;
development-only scenarios; validation-tool routes].

First inspect the project and baseline. Build the smallest playable vertical slice.
Keep the composition root thin: it wires lifecycle and feature registration but
does not absorb feature logic. Keep feature internals owned by their feature; cross
feature dependencies use declared public APIs, interfaces, events, schemas, or
engine-native equivalents rather than private-state coupling. Keep dev
scenarios/debug controls and evidence tools out of shipping runtime logic and the
production control path.
Decompose work by change coupling; classify every unit as independent or coupled.
Parallelize only the independent units; give coupled rendering, camera/input, shared
runtime-contract, and cross-cutting performance work one owner at a time. Record
the wave plan, canonical baseline, and integrator handoffs in the progress log.
For each important unit, use a builder and a fresh independent critic that inspects
the running artifact and evidence. Iterate on the largest proven gap. After each
wave, run one whole-game integration pass. Never claim visual, performance, or fun
quality without the matching evidence. Maintain a concise progress log.
```

## Builder brief

```
Own only: [files/subsystem/interface].
Player outcome contribution: [what becomes clearer, more responsive, more legible].
Scenario: [named repeatable scenario and command].
Bar and current largest gap: [specific observable gap].
Acceptance: [visual/performance/functional metric].
Constraints: [do not edit / preserve determinism / budgets].

Inspect the running artifact first. Implement the smallest change that closes this
gap. Run the stated evidence route. Return changed files, before/after evidence,
failed checks, rejected approaches, and unresolved risks. Do not self-grade against
the bar. Escalate shared-contract changes instead of editing outside your boundary.
```

## Fresh critic brief

```
Evaluate [artifact] against [bar] using [capture/build/profile/player evidence].
You did not build it. Inspect the artifact itself, not the builder's report.

When possible, compare blind: label the two candidates A/B before deciding.
Return only:
1. winner (A, B, or tie) and confidence;
2. the single largest player-visible gap;
3. exact scenario/artifact plus concrete evidence from pixels, runtime behavior, measurements, or playtest;
4. one bounded next change and its acceptance check;
5. blockers or evidence you could not inspect.

Reject “looks AAA,” “feels good,” or unmeasured performance claims.
```

## Integration brief

```
Inspect the complete running game after a Caesar Loop wave. Check the player path,
lighting/exposure/tonemapping, camera and input feel, asset/style consistency,
cross-system events, performance, UI readability, and regressions in named scenarios.
Rank the top three evidence-backed integration defects. Fix only conflicts within
the assigned scope or create bounded follow-up units. Re-run the project gates.
Separate direct evidence from inference, and preserve failed gates or rejected
changes so the next wave does not repeat them.
```

## Target-player session

```
Ask the user to provide or approve a target player who did not build the feature;
do not contact or recruit participants autonomously. Give the player no solution or
design explanation. Ask them to [task] for 5–10 minutes. Observe where they hesitate,
misread feedback, lose, recover, choose, or voluntarily replay. Then ask:
“What did you think was happening?”, “What felt best/worst?”, and “Would you play
again? Why?” Record anonymized observations separately from interpretation. If no
participant is available, prepare this session and mark the player gate outstanding.
```
