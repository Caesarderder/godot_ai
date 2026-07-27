# Contract schema

The minimal canonical project structure is:

```text
docs/
├── index.md
└── game-contract.md
```

`docs/index.md` routes by role and task. `docs/game-contract.md` is the small-project source of truth.
Split large contracts only when the index names one canonical source for every item.

## Document metadata

`game-contract.md` starts with YAML frontmatter containing:

- `contract_version`: positive integer;
- `project_id`: stable lowercase kebab-case ID;
- `last_updated`: `YYYY-MM-DD`.

## Item format

Each item uses `## GC-NNN: Title` and these single-line fields:

```markdown
- owner: producer
- status: proposed
- accepted_intent: ...
- acceptance_criteria: ...
- implementation_reference: —
- verification_evidence: —
- conflict_references: —
- handoffs: —
- handoff_from: —
- handoff_to: —
- handoff_request: —
- handoff_allowed_fields: —
- handoff_blocking: —
- deviation: —
- last_updated: YYYY-MM-DD
- last_verified: —
```

Allowed owners are `producer`, `game-design`, `programming`, `art`, `audio`, and `qa-release`.
Allowed statuses are defined in [status-model.md](status-model.md). Use `—` for intentionally empty
evidence; never omit a field.

Implementation references use existing, stable repository-relative paths and, when useful, a symbol
such as `scripts/combat/tower.gd#apply_damage`. They must remain inside the project; URLs, URIs,
missing paths, path traversal, absolute paths, and fixed line numbers are invalid. `handoffs` is `—`
or a comma-separated list of dependent contract IDs. Every referenced ID must exist.

A `proposed` item needs a non-empty intent. An `accepted` item also needs acceptance criteria.
`implemented` additionally needs an implementation reference. `verified` additionally needs
verification evidence and `last_verified`. `deferred` and `rejected` need a deviation note.

The five `handoff_*` fields form one indivisible handoff record: source role, target role, requested
decision/deliverable, fields the recipient may update, and `true`/`false` blocking state. Set all five
or set all five to `—`. A `drifted` item requires accepted intent, criteria, a deviation,
`conflict_references` naming both conflicting sources, and a complete owner handoff.
