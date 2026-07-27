# Role preflight and handoff protocol

Open only the relevant contract item and directly linked evidence.

| Role | Read | May update | Must hand off |
| --- | --- | --- | --- |
| producer | player promise, milestone, non-goals, drift summary | scope intent, acceptance decision, milestone closure | rules to game-design; implementation to delivery owner; evidence to QA |
| game-design | accepted promise and related rule items | rules, values, experience assumptions, testable criteria | scope decisions to producer; implementation to programming |
| programming | accepted criteria and related technical references | implementation reference and implemented state | semantic rule changes to game-design/producer |
| art | promise, related events, visual acceptance criteria | visual asset references and visual evidence notes | gameplay meaning to game-design; runtime work to programming |
| audio | promise, related events, audio acceptance criteria | audio asset references and audio evidence notes | gameplay meaning to game-design; runtime work to programming |
| qa-release | accepted criteria, implementation reference, target environment | verification evidence, verified state, drift reports | intent conflicts to producer/game-design; fixes to implementation owner |

## Handoff record

A handoff contains:

- source and target role;
- contract item ID;
- observed evidence or conflict;
- requested decision or deliverable;
- fields the recipient is allowed to update;
- blocking or non-blocking status.

Record these as the indivisible `handoff_from`, `handoff_to`, `handoff_request`,
`handoff_allowed_fields`, and `handoff_blocking` fields. `handoffs` is reserved for dependent
`GC-NNN` item IDs; it is not a substitute for the role handoff record. A drift record must also
name both disagreeing sources in `conflict_references`.

Keep one lead role. A handoff does not preload the target role or all project documents. If design
says repair cost is 1 and code applies 2, record both references, mark the item `drifted`, and hand
the decision to producer/game-design. Do not silently change either side.
