---
km_id: reference.godot-m1-transaction-time-spine-design
km_type: reference
domain: architecture
status: draft
owner: architecture
last_verified: 2026-07-20
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
validated_by:
  - user-design-approval
tags:
  - risk:exact-once
  - quality:acceptance-gate
related:
  - reference.state-command-lifecycle
  - decision.durable-domain-kernel
---

# Godot M1 Transaction and Time Spine Design

## Status and scope

This design implements milestone M1 inside `project-a/` on Godot 4.7.1 with
GDScript and GUT. It does not change the repository's declared development
route, TapTap documents, or `project-a/addons/godot_ai/**`. Existing unrelated
working-tree changes are preserved.

M1 establishes the durable state, command, persistence, quest-event, and
lifecycle foundations required by M2-M5. It does not implement hero generation,
combat simulation, equipment content, facilities, or player-facing screens.

## Acceptance boundary

M1 is complete only when automated tests prove all of the following:

- command classes are sealed by a registry and cannot be overridden by callers;
- command fingerprints use the approved canonical encoding and SHA-256 formula;
- durable commands persist candidate state and receipts before swapping memory;
- retries return the original receipt without applying value twice;
- command ID and business-key reuse mismatches are rejected without mutation;
- lifecycle internal commands require an unforgeable executor-owned capability;
- pause, heartbeat, and resume update the four time fields atomically;
- offline settlement uses only `offline_anchor_unix`, never exceeds eight hours,
  and handles rollback and large forward jumps without duplicate rewards;
- task-causal receipt/event retention survives the 600-command replay cases;
- save v1 round trips, migrates v0, ignores incomplete temporary files, and
  restores a validated backup while preserving corrupt primary data;
- the existing M0 editor, mobile, compatibility, and GUT verification stays green.

## Architecture

### Persistent state

`GameState` is a pure data object backed by dictionaries, arrays, strings,
integers, and booleans. It never stores Nodes, Resources, scenes, callables, or
transient battle state. Its serialized schema contains:

- identity/version: `schema_version`, `content_version`, `save_id`, `run_seed`,
  `revision`;
- future-domain containers: `roster`, `inventory`, `formation`, `economy`,
  `camp`, `quest`, `pity`, `stage_progress`, `attempt_counters`;
- idempotency: `receipt_ledgers`;
- time: `saved_at_unix`, `last_seen_wall_unix`, `last_settled_unix`,
  `offline_anchor_unix`.

The persistent key is always `revision`. Internal writer variables may use
`state_revision`, but they must serialize as `revision`.

### Command boundary

`CommandExecutor` is the only persistent-state writer. A sealed
`CommandClassRegistry` maps known command types to:

- `DURABLE_VALUE`;
- `INTERNAL_DURABLE`;
- `REVERSIBLE_META`;
- `EPHEMERAL`.

The command envelope cannot carry a durability override. Unknown commands
return `UNKNOWN_COMMAND`. Internal lifecycle commands are callable only through
`execute_internal`, which injects an executor-owned capability that ordinary
callers cannot construct.

Durable execution is ordered as follows:

1. validate envelope, revision, command type, and fingerprint;
2. return a prior receipt or reject an ID/key mismatch when applicable;
3. clone the current state into a candidate;
4. apply the domain reducer and collect domain events;
5. apply the pure quest reducer to the same candidate;
6. validate invariants and append the receipt;
7. assign audit time and increment candidate revision;
8. persist and validate the candidate snapshot;
9. swap the in-memory state;
10. emit events and return success.

Any failure before persistence completes leaves the in-memory state unchanged
and returns an error. Reversible metadata swaps atomically in memory and is
persisted through a 1000 ms debounce. A durable barrier cancels pending
debounce work before writing its candidate. Ephemeral commands never touch
state, receipts, quests, or persistence.

### Canonical fingerprint

The allowed payload graph consists only of null, boolean, integer, UTF-8 string,
ordered array, and string-keyed dictionary. Floats and engine objects are
rejected. Dictionary keys are ordered by UTF-8 bytes and canonical JSON contains
no insignificant whitespace.

The fingerprint is:

`SHA-256(LP(type) || LP(canonical_payload) || LP(business_key))`

where `LP(value)` is a four-byte unsigned big-endian UTF-8 byte length followed
by the bytes. A duplicate command ID with the same fingerprint returns its
original receipt. Reusing a command ID or business key with a different
fingerprint returns the corresponding hard mismatch error and performs no work.

### Receipts and quest events

Value/business receipts remain for the lifetime of the save. Task-causal
receipts and consumed event IDs remain until all consumers are terminal and
claimed or retired; terminal quests permanently ignore matching replayed
events. Only reversible commands that transfer no value and advance no quest
may be evicted through the 512-entry ring.

`QuestReducer` is pure: it consumes domain events and updates candidate quest
state. It cannot issue commands, grant rewards independently, access UI, or
persist. M1 provides generic event consumption and deduplication; concrete
M2-M4 quest content remains out of scope.

## Persistence

The canonical files are `user://save_v1.json`, `save_v1.json.tmp`, and
`save_v1.json.bak`. `SaveManager` is a single writer and rejects candidates whose
revision is lower than the last durable revision.

Durable write order is:

1. encode the candidate to canonical save JSON;
2. write the temporary file, flush, and close it;
3. read, parse, migrate, and validate the temporary snapshot;
4. copy the current valid primary to backup when present;
5. replace the primary with the validated temporary snapshot;
6. read and validate the installed primary before reporting success.

On boot, an incomplete or corrupt temporary file is ignored. A valid primary is
preferred. Only when the primary is invalid may a validated backup be restored;
the bad primary is preserved with a timestamped `.corrupt-*` suffix. A v0
snapshot is migrated deterministically to v1 without losing recognized fields.

Godot does not expose a portable fsync/atomic-replace guarantee for every target
filesystem. M1 therefore promises exact-once behavior within the approved
single-device, single-writer, application-crash scope, using the strongest
flush/close/replace sequence available through `FileAccess` and `DirAccess`.

## Time and lifecycle

The four fields have one responsibility each:

- `saved_at_unix`: audit time assigned immediately before encoding a candidate;
- `last_seen_wall_unix`: monotonic maximum observed wall time for diagnostics;
- `last_settled_unix`: most recent successful offline-settlement end time;
- `offline_anchor_unix`: the sole offline accrual origin.

`AppLifecycle` remains the only Godot notification owner and does not mutate
state or call `SaveManager` directly. It forwards debounced edges to sealed
executor commands:

- pause: advance anchor and last-seen to `max(old, now)` and save durably;
- heartbeat: every 60 foreground seconds perform the same durable advance;
- resume: compute `effective_end=max(anchor, now)`, credit
  `min(effective_end-anchor, 8h)`, and commit credit, anchor, settled time,
  last-seen time, and receipt in one snapshot.

Pause and resume edges are independently deduplicated for 250 ms. A failed pause
does not advance memory; retries are serialized within a five-second budget.
Clock rollback grants zero and never decreases anchor/settled fields. A 48-hour
jump grants eight hours once while advancing the anchor to the observed time.

First boot creates a state with `offline_anchor_unix=last_seen_wall_unix=now`
and `last_settled_unix=0`. `game_ready` is emitted only after the first durable
snapshot succeeds, and first boot grants no offline reward.

## Error contract

Command results use stable codes including `OK`, `UNKNOWN_COMMAND`,
`INVALID_ENVELOPE`, `INVALID_PAYLOAD`, `REVISION_MISMATCH`,
`COMMAND_ID_REUSE_MISMATCH`, `BUSINESS_KEY_REUSE_MISMATCH`,
`INTERNAL_COMMAND_FORBIDDEN`, `INVARIANT_FAILED`, and `SAVE_FAILED`.

Failures never return success, emit committed domain events, or expose an
unpersisted durable candidate. Logs may contain IDs and error codes but must not
dump an entire user save.

## Test-driven implementation

Every production behavior is introduced through a failing GUT test. The order is:

1. state defaults and validation;
2. sealed command classification;
3. canonical payload and fingerprint golden cases;
4. duplicate and mismatch receipt behavior;
5. candidate/save/swap ordering and injected failure points;
6. save round trip, v0 migration, tmp rejection, and backup recovery;
7. lifecycle authorization and time-field rules;
8. 20-minute heartbeat plus five-minute resume, rollback, and 48-hour jump;
9. 600 task-causal replay and reversible-ring eviction;
10. bootstrap integration and full M0 regression.

Each test must first fail for the missing behavior, then pass with the minimum
implementation. Tests use isolated `user://` paths or injectable persistence
ports so they do not depend on a developer's real save.

## Planned file ownership

Existing files to revise:

- `project-a/game/scripts/autoloads/game.gd`
- `project-a/game/scripts/autoloads/save_manager.gd`
- `project-a/game/scripts/autoloads/app_lifecycle.gd`

New implementation directories:

- `project-a/game/scripts/state/`
- `project-a/game/scripts/commands/`
- `project-a/game/scripts/persistence/`
- `project-a/game/scripts/domain/quests/`
- `project-a/game/scripts/domain/idle/`

New tests and fixtures live under `project-a/tests/unit/`,
`project-a/tests/integration/`, and `project-a/tests/fixtures/saves/`.

`project-a/addons/godot_ai/**`, TapTap files, route declarations, and gameplay
systems beyond M1 are explicitly excluded.
