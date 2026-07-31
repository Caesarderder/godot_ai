# Caesar Awesome managed artifacts

Use this reference whenever creating, updating, or removing Caesar-controlled
Markdown or Loop JSON. The CLI is the write authority for fixed structure; the
the selected Caesar procedures remain the semantic authority.

## Mandatory rule

Do not hand-write managed frontmatter, `RunSpec`, `Progress`, ledger indexes, gate
state, generated Loop nodes, or HQ projections when the corresponding command
exists. Prepare an input JSON payload, invoke the command, inspect its result,
and retain the validation output.

The CLI uses only Python's standard library. It delegates Loop schema validation
to `scripts/validate_loop_protocol.py`, plan-path validation to
`scripts/validate_plan_paths.py`, and repository knowledge-map validation to
`tools/docs_lint.py` when that repository provides it.

Run every command from the repository root. Input and output paths must remain
inside that repository.

Before returning any Caesar command list or path-bearing plan, validate the
draft itself:

```bash
python3 .codex/skills/caesar-awesome/scripts/validate_plan_paths.py < plan.txt
```

This rejects retired sibling Skill paths, nested layouts, old commands, the old
external Workbench writer, and project-generated state inside Skill assets.

## Generate input templates

Begin from tool-emitted structure instead of inventing JSON keys:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py template \
  --kind <node|run-spec|host|evidence|finding|iteration> \
  --output .caesar-input/<name>.json
```

The command reuses live Caesar Loop templates for Loop artifacts, emits the
fixed knowledge-node input shape for `node`, and refuses to overwrite an
existing file. Replace semantic placeholder values, then pass the JSON into the
corresponding mutation command.

## Knowledge nodes

Create or replace a node from a JSON specification:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py node-upsert \
  --path docs/<area>/<node>.md --spec <repo-local-node-spec.json>
```

When updating an existing node, also pass `--expect-km-id <current-km-id>`.
The tool refuses silent node-identity changes.

Required node-spec keys:

```json
{
  "km_id": "reference.example",
  "km_type": "reference",
  "domain": "workflow",
  "status": "active",
  "owner": "maintainers",
  "source_of_truth": ["path/or/command:..."],
  "validated_by": ["command:python3 tools/docs_lint.py"],
  "tags": ["workflow:task-routing"],
  "related": ["map.workflows"],
  "title": "Example",
  "body": "Markdown body without frontmatter or the H1."
}
```

The tool owns `last_verified`, frontmatter order, Markdown framing, repository
containment, lint, and rollback.

Delete only an unreferenced non-required node:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py node-remove \
  --path docs/<area>/<node>.md \
  --expect-km-id reference.example \
  --reason "Superseded by reference.new-example" \
  --confirm delete:reference.example
```

Deletion fails on an ID mismatch, inbound `related`/`KM` reference, missing
reason, wrong confirmation, or docs-lint regression.

## Loop creation and specification

Prepare a complete RunSpec payload following the live Caesar Loop schema, but
omit or ignore `schema_version`; the tool owns it.

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py loop-init \
  --run-dir docs/workbench/loop-data/<run-id> \
  --spec <repo-local-run-spec-input.json> --revision <commit-or-build-id>
```

The command validates the RunSpec, creates append-only ledger directories, and
derives the initial Progress gate map. It refuses a non-empty target directory.

Update a RunSpec without changing its run ID or removing evaluated/frozen gates:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py loop-spec \
  --run-dir <run-dir> --spec <new-run-spec.json> --expect-run-id <run-id> \
  --reason "Scenario contract updated before baselining."
```

When an active run only needs new bounded scenarios, gates, or ownership rows,
prefer the append-only extension form instead of copying and editing the whole
RunSpec. The extension JSON may contain only `scenarios`, `quality_gates`,
`ownership`, and `dimension_gate_bindings`; existing or repeated scenario/gate
IDs are rejected. Bind every new required gate to a relevant existing quality
dimension through that mapping:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py loop-spec \
  --run-dir <run-dir> --extend <run-spec-extension.json> \
  --expect-run-id <run-id> --reason "Add the next bounded work unit."
```

An evaluated gate or its linked Test Scenario cannot change until the gate and
evidence are explicitly marked stale.

Record the observed host capabilities through the live schema:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py host-set \
  --run-dir <run-dir> --input <host-capabilities.json> \
  --reason "Observed capabilities at run start."
```

The tool owns `schema_version` and supplies `observed_at` when absent. Unknown or
unobserved capabilities must remain `unknown` or `unsupported`; the command does
not infer support.

When the tested build or commit changes, update the revision explicitly:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py revision-set \
  --run-dir <run-dir> --revision <new-commit-or-build-id> \
  --affected-gate-id <gate-id> \
  --reason "Candidate implementation changed."
```

Repeat `--affected-gate-id` for the exact impact set. Use `--all-gates` only for
a genuinely global change. The operation atomically marks affected Evidence
stale, unfreezes affected gates, carries unrelated Evidence through the new
revision while preserving its source revision, and updates `Progress.revision`.
A state transition cannot change revision implicitly.

## State, evidence, findings, and gates

Apply exactly one legal state transition:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py loop-transition \
  --run-dir <run-dir> --state scenario_authoring \
  --revision <revision> --active-unit "author scenario_x" \
  --reason "RunSpec and capability audit are ready."
```

After recording a `completion_candidate` IterationResult for the active bounded
work unit, close that unit before entering integration:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py work-unit-close \
  --run-dir <run-dir> --reason "Focused work unit accepted." \
  --next-action "Run the declared integration checkpoint."
```

The command refuses to clear ownership unless the latest IterationResult belongs
to the active unit, has `completion_candidate` status, and no Finding remains
open. Do not edit `Progress.active_work_unit` directly.

Forward transitions follow the Caesar Loop state machine. Any active state may
enter a precise terminal result. `completed` additionally requires every
required gate to pass, a non-empty evidence ledger, and no open findings.

Append a schema-valid artifact:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py artifact-add \
  --run-dir <run-dir> --kind evidence --input <evidence.json>
```

Kinds are `evidence`, `finding`, and `iteration`. The tool owns
`schema_version`, `run_id`, filenames, duplicate protection, Progress ledger
indexes, and exact iteration increments.

Pass a gate only with fresh passing evidence for the same run, gate, and current
revision:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py gate-set \
  --run-dir <run-dir> --gate-id <gate-id> --status pass \
  --evidence-id <evidence-id> --reason "Strict scenario passed."
```

Update—not delete—a finding:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py finding-set \
  --run-dir <run-dir> --finding-id <finding-id> --status resolved \
  --evidence-id <current-passing-acceptance-evidence-id> \
  --reason "Current evidence proves the acceptance check."
```

`resolved` requires current passing Evidence for the Finding's gate and current
revision. `accepted_risk`, `rejected`, and blocked states remain distinct
decisions and must not impersonate evidence-backed resolution.

Evidence, findings, iterations, rejected attempts, and terminal results are
historical ledgers. Never physically delete them. Use `freshness: stale`,
`resolved`, `accepted_risk`, or `rejected` as defined by the source schemas.

Mark superseded evidence and its gate stale together:

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py evidence-stale \
  --run-dir <run-dir> --evidence-id <evidence-id> \
  --reason "Scenario or tested revision changed."
```

## Validation and projection

```bash
python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py validate \
  --run-dir <run-dir>

python3 .codex/skills/caesar-awesome/scripts/caesar_artifacts.py sync \
  --run-dir <run-dir> --task "<matching HQ task>"
```

`sync` validates first, then calls the existing Workbench writer to generate the
Loop knowledge node, HQ projection, and HTML. Do not edit those projections to
repair source JSON.
