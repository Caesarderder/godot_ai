# Design Integrity and Scope Review

Use this review when design, implementation, and current milestone may have drifted.

## Compare three layers

| Layer | Question |
| --- | --- |
| Accepted contract | What player promise, rules, first playable, and non-goals were actually agreed? |
| Implemented reality | What do current data, code, scenes, and runtime evidence do? |
| Active scope | What is required for the next player-visible milestone, and what remains deferred? |

Classify each difference as `intentional change`, `implementation defect`, `stale document`, `unaccepted expansion`, or `unknown`. Do not resolve an unknown by expanding scope.

## Propagate real changes

When one rule changes, trace only affected owners: player state, encounters/levels, balance data, UI/feedback, narrative conditions, saves/migrations, tests, and release risk. Update the authoritative contract and implementation owners; do not create a parallel document suite.

## Scope checks

- Every active system supports the promise, recovery, or a required delivery constraint.
- Content counts come from the playable variation required, not a template quota.
- Deferred ideas have no accidental implementation dependency.
- Optional content does not own a critical rule or clue.
- A removed mechanic has no stale UI, save, narrative, test, or tutorial contract.
- Evidence distinguishes accepted intent from implemented and exercised behavior.
