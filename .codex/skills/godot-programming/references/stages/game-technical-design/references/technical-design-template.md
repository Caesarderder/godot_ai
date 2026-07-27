# Technical Design Template

Use this as a selective structure, not a completeness checklist. Delete sections that do not affect the requested game or milestone.

## 1. Outcome and evidence

- Product/design source:
- Player-visible outcome:
- Target platform and input:
- Confirmed project facts:
- Inferred constraints:
- Decisions accepted for this design:
- Open hypotheses:
- Non-goals:

## 2. Current-state trace

- Main scene and entry path:
- Existing systems reused:
- Direct callers and consumers:
- Current tests/build/export routes:
- Conflicts between current code and desired behavior:

## 3. Playable sequence

Describe one concrete sequence:

```text
input/trigger -> precondition -> state change -> visible/audio feedback
-> success or failure -> recovery/retry
```

State what a reviewer must observe to believe the sequence works.

## 4. Ownership and data flow

| System or node | Owner/lifetime | State owned | Inputs/commands | Outputs/signals | Failure behavior |
| --- | --- | --- | --- | --- | --- |

Add one diagram only when it makes cross-system flow clearer.

## 5. Data contracts

For each persistent or shared record, define types, invariants, defaults, invalid-data behavior, version/migration needs, and maximum expected size. Separate immutable configuration from live runtime state.

## 6. Integration boundaries

Cover only applicable boundaries:

- scene creation and teardown;
- input and focus;
- UI and responsive coordinates;
- audio event and browser startup;
- assets and loading;
- save/load;
- localization/accessibility;
- Web export or hosting behavior.

## 7. Decisions and spikes

### ADR candidates

| Decision | Why durable/cross-cutting | Alternatives | Consequences | Rollback |
| --- | --- | --- | --- | --- |

### Risk spikes

| Question | Minimum experiment | Evidence | Proceed/adapt/abandon | Fallback |
| --- | --- | --- | --- | --- |

## 8. Vertical milestones

For each milestone include:

- player-visible result;
- exact scope and non-goals;
- owned systems/files likely affected;
- dependency and risk closed;
- acceptance observations;
- automated/headless checks;
- Web/gameplay evidence;
- residual limitation.

## 9. Handoff

- First ready milestone:
- Relevant installed skills:
- Repository commands to start with:
- Decisions implementation may make autonomously:
- Decisions that require product input:
