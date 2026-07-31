# Caesar Awesome operating contract

Use this reference only when the four-stage route in `SKILL.md` does not resolve
ownership or disclosure.

## Authority table

| Concern | Authority | Durable artifact |
|---|---|---|
| Which repository facts to read before acting | Discovery procedure | Required discovery decision report |
| Knowledge-map schema, maintenance, and task/HQ lifecycle | Knowledge-map and Workbench procedures | Repository `docs/`, `docs/workbench/hq.md`, generated HTML |
| Player outcome, Test Scenario, quality gates, evidence, findings, iteration, stop state | Explicit Loop procedure | RunSpec/Progress and Loop JSON ledgers |
| Which procedure runs next | `caesar-awesome` root route | No new fact store; route only |
| Fixed serialization, mutation guards, state transition mechanics, and rollback | `caesar-awesome` managed-artifact CLI | No separate truth; validated writes to the owning artifacts |

Keep each fact in one authority surface. The CLI invokes the package's live
schemas and validator and encodes only deterministic write mechanics.

## Route matrix

| Request shape | Discovery | Docs/HQ | Loop |
|---|---:|---:|---:|
| Factual repository answer | yes | source exemptions apply | no |
| One-line/trivial edit | source exemptions apply | source exemptions apply | no |
| Non-trivial code/docs/review task | yes | yes | no unless `loop` is explicit |
| Substantial game creation or vertical slice | yes | yes | no unless `loop` is explicit |
| Visual, game-feel, performance, learning, or iterative playability improvement | yes | yes | no unless `loop` is explicit |
| Resume an existing Loop run | yes | yes | only with explicit `loop` |
| Maintain only the knowledge map/HQ | yes | yes | no |
| `docs-init` | yes | yes: init | no |
| `loop` | yes | yes | yes |

## Handoff sequence

```text
user goal
  → discovery: repository route and constraints
  → control: task card and durable knowledge lifecycle
  → explicitly enabled Loop only: RunSpec → Test Scenario → evidence-gated work
  → loop-sync: generated run node + HQ/HTML projection
  → repository validation + exact Loop state + HQ closure
```

The handoff passes identifiers and artifact paths, not rewritten contracts:

- Discovery passes selected knowledge nodes, ownership, constraints, and
  validation routes.
- Control passes the HQ task name and repository knowledge-map conventions.
- Loop execution passes `run_id`, run directory, current state, and current
  evidence/finding ledger.
- `loop-sync` creates projections but never becomes the evidence authority.
- The managed-artifact CLI accepts semantic payloads and writes the source
  artifacts; a successful command does not add a new authority layer.

## Conflict and failure handling

1. Higher-level safety and explicit user instructions take precedence.
2. Each procedure owns its declared artifacts; do not resolve conflict by blending rules.
3. Repository facts can make a skill assumption stale. Preserve the skill
   contract while following its own stale-doc/code-verification procedure.
4. If a required command, reference, schema, or script is missing, report the exact
   path and continue only with the remaining behavior that is independently
   valid. Do not emulate the missing skill from memory.
5. If Workbench writing fails, do not claim state persistence.
6. If Loop evidence is missing or stale, preserve the precise non-success state.

## Progressive-disclosure examples

### Documentation-only change

Read discovery, then the relevant docs/HQ procedure. Do not load Loop profiles,
schemas, or templates.

### Fix a deterministic save migration

Read discovery and control procedures, then the project's save/test skills. Do
not load Loop-only resources unless the user explicitly enables it.

### Improve combat readability

Without `loop`, use normal discovery and control. With explicit `loop`, read
`loop-guide.md`, then only the relevant Loop references, profiles, and schemas.

### Resume a blocked run

Require explicit `loop`. Then repeat discovery because repository facts may
have changed, re-enter Workbench control without duplicating the active task,
validate existing Loop artifacts, and resume from the recorded state.
