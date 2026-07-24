# Contract status model

Use exactly one status per contract item.

| Status | Meaning | Minimum evidence |
| --- | --- | --- |
| `proposed` | Suggested, not approved for production | intent and owner |
| `accepted` | Approved production baseline | accepted intent and acceptance criteria |
| `implemented` | Implementation exists; not yet verified | accepted prerequisites and stable implementation reference |
| `verified` | Acceptance criteria were exercised | implementation reference, verification evidence, and verification date |
| `deferred` | Intentionally postponed | reason or dependency in deviation note |
| `rejected` | Explicitly declined | reason in deviation note |
| `drifted` | Sources disagree or behavior deviates | both conflicting references and an owner handoff |

State is evidence, not optimism. Never jump from design intent to `implemented`, or from automated
structure checks to `verified`. A verified item that later conflicts with code or acceptance criteria
returns to `drifted` until the canonical owner resolves it.

Producer accepts or rejects scope and milestone intent. The owning implementation role records
`implemented`. QA records verification evidence and may mark `verified` only when the accepted
criteria were actually exercised. Any role may report `drifted`; only the relevant canonical owner
resolves the disputed intent.
