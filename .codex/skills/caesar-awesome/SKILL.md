---
name: caesar-awesome
description: Self-contained Caesar repository system combining knowledge-map discovery, local Workbench task control, durable documentation, managed Markdown/JSON tools, and an explicitly enabled game-production Loop. Use for repository implementation, review, testing, documentation, or knowledge-map work. Use `caesar-awesome:docs-init` to initialize a knowledge map and `caesar-awesome:loop` to explicitly enable or resume reusable Test Scenarios and evidence-gated maker–critic game loops; never infer Loop activation from the task topic alone.
---

# Caesar Awesome

Own repository discovery, knowledge-map/HQ control, managed artifacts, and the
explicitly enabled game-production Loop directly. Keep detailed procedures
progressively disclosed through `commands/`, `references/`, `profiles/`,
`schemas/`, `assets/`, and `scripts/`. Do not invent host, test, runtime,
reviewer, or human capabilities.

Read [references/operating-contract.md](references/operating-contract.md) when
routing is ambiguous, a run resumes, or ownership between repository knowledge
and game evidence is unclear.

## Explicit commands

Recognize these stable command forms:

| Command | Effect |
|---|---|
| `caesar-awesome:docs-init` or `$caesar-awesome docs-init` | Initialize or structurally normalize the repository knowledge map through [commands/docs-init.md](commands/docs-init.md). |
| `caesar-awesome:loop` or `$caesar-awesome loop` | Explicitly enable a new Caesar Loop run or resume an existing run for the current request. |

Read [references/explicit-commands.md](references/explicit-commands.md) when a
command is present, both commands are combined, natural-language activation is
ambiguous, or a missing map/previous Loop run could tempt implicit activation.

An unambiguous user instruction to “开启/启动 Caesar Loop” is equivalent to the
`loop` command. Merely mentioning a game, quality, iteration, playability,
visuals, game feel, performance, screenshots, vertical slices, or an existing
Loop artifact is not activation.

Without `docs-init`, do not initialize a missing knowledge map or perform a
repository-wide structural normalization. The default Docs route may discover,
read, update, or review an existing map; if none exists, report that fact and
continue with the smallest safe repository discovery.

Without `loop`, do not load Loop-only references or profiles, create or
resume RunSpec/Progress ledgers, call Loop mutation or `loop-sync` commands, or
describe the task as a Loop run. Normal repository tests and focused validation
remain available.

Treat this package's current files as the only Caesar execution surface. Never
use a remembered Caesar path, command, or separate Skill name. Before returning
a plan, command list, handoff, or review that contains Caesar paths, pipe that
text through `scripts/validate_plan_paths.py`; correct every rejected path
instead of explaining or preserving it.

## Progressive route

### 1. Discover — always first

Read [references/docs-discovery.md](references/docs-discovery.md) before
implementation or external tool discovery. Execute its smallest relevant
knowledge-map pass and publish its required decision report.

Stop expanding the docs tree as soon as the repository route, constraints,
ownership, validation, and documentation sync targets are known.

### 2. Control — for non-trivial repository work

Read [references/workbench-and-knowledge-map.md](references/workbench-and-knowledge-map.md).
Follow the selected command/reference route only as far as the task requires.

Start the Workbench task before implementation. During work, record only
important decisions, scope changes, blockers, and durable Loop projections.
Keep long-term facts in the project knowledge map, not only in HQ or chat.

When a task needs structured human observation in the browser, read
[references/human-validation.md](references/human-validation.md). Define the
reusable validation spec as JSON, sync it into HQ, and collect sessions through
the rendered Workbench. A browser session is raw observation data; it never
passes a Loop gate or registers Evidence by itself.

For pure answers, one-line edits, or an explicit user request to skip HQ, retain
the documented exemptions; do not create a stricter substitute.

### 3. Produce — only after the explicit `loop` command

Select this stage only when the user explicitly invokes `caesar-awesome:loop`,
`$caesar-awesome loop`, or unambiguously asks to start Caesar Loop. Never infer
activation from task shape. Then:

1. Read [references/loop-guide.md](references/loop-guide.md) completely.
2. Load only the Loop references and [profiles](profiles/) required for
   the current run or work unit.
3. Create or resume its authoritative JSON/ledger artifacts.
4. On resume, validate the run directory and read `Progress.continuation_anchor`
   before selecting work. Reconcile its goal, scope, in-scope quality dimensions,
   active unit, and revision against `RunSpec`; never resume from chat memory.
5. Inventory all thirteen whole-game quality dimensions. Mark each one
   `in_scope` or `not_applicable` with a rationale, and bind every in-scope
   dimension to at least one required gate before completion.
6. Author and validate a parameterized, task-specific Test Scenario before
   baselining or changing the work unit. Default to a dedicated feature fixture
   whose single run covers the action/state/viewpoint matrix and emits one
   review bundle; reserve the main scene for declared integration checkpoints.
7. Execute the evidence-gated maker–critic rules. A required
   model or mixed gate closes only with passing evidence from an independent
   child-agent critic carrying its thread identity; maker self-review remains
   directional evidence only.
8. Apply the declared integration rules without replacing them with a generic
   review loop.
9. Use `loop-sync` after material scenario, gate,
   evidence, finding, iteration, decision, or state changes.

Do not load Loop-only references merely because the repository contains a game or the
request concerns game creation, quality, playability, visuals, feel, performance,
or iteration.

### 4. Write managed artifacts through tools

Read [references/managed-artifacts.md](references/managed-artifacts.md) before
creating, updating, or removing Caesar-controlled Markdown or Loop JSON.

Use `scripts/caesar_artifacts.py` whenever its command covers the mutation. Do
not hand-build fixed frontmatter, RunSpec/Progress structure, ledger filenames,
gate state, evidence indexes, generated Loop knowledge nodes, or HQ projections.
The tool owns formatting, generated fields, legal state transitions, repository
containment, append-only history, validation, atomic replacement, and rollback.

AI-authored content still supplies semantic inputs such as player outcomes,
scenario contracts, observations, findings, and node bodies. Pass those inputs
to the tool as JSON; do not treat tool-owned structure as creative prose.

For a new artifact, follow this fixed sequence:

`template → fill semantic values → managed mutation → validate → sync`

When a bounded Loop unit has a recorded `completion_candidate`, use the managed
`work-unit-close` command before transitioning to integration; never clear the
Progress field by hand.

Use the CLI `template` command instead of inventing keys or copying a stale
example from chat.

Do not use a generic JSON editor to bypass a rejected managed operation. Fix the
semantic input or report the exact gate that blocked it. Never physically delete
Loop evidence, findings, iterations, rejected attempts, or terminal results.

### 5. Close — preserve both completion meanings

Before handing off:

1. Run the repository validations selected by the discovery route and active
   procedures.
2. Synchronize durable facts and generated Loop knowledge nodes through the
   Workbench writer.
3. If Caesar Loop was selected, report its exact protocol state. Never translate
   `human_required`, `capability_unavailable`, `budget_exhausted`, another
   terminal non-success result, or missing evidence into success.
4. Finish the Workbench task only when the repository task itself is genuinely
   complete. A Workbench completed card does not close a Loop gate, and a Loop
   state does not replace the repository task summary.
5. Report the docs route, procedures actually loaded, artifacts changed,
   validations, Loop state when applicable, and residual risks.

## Context budget rules

- Level 1: rely on this skill's metadata only for triggering.
- Level 2: load this file to select the route.
- Level 3: load only the command, reference, profile, or schema selected for the
  current stage.
- Never bulk-load all references, profiles, and schemas “for completeness.”
- Never replace required complete reading of a selected procedure with a
  summary or cached recollection.

Validate the standalone package after changing this skill or any resource path:

```bash
python3 .codex/skills/caesar-awesome/scripts/verify_composition.py
python3 .codex/skills/caesar-awesome/scripts/test_caesar_artifacts.py
python3 .codex/skills/caesar-awesome/scripts/test_workbench_hq.py
python3 .codex/skills/caesar-awesome/scripts/validate_plan_paths.py < plan.txt
```
