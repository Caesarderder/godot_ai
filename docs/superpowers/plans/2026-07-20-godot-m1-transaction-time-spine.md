---
km_id: reference.godot-m1-transaction-time-spine-plan
km_type: reference
domain: architecture
status: draft
owner: implementation
last_verified: 2026-07-20
source_of_truth:
  - docs/superpowers/specs/2026-07-20-godot-m1-transaction-time-spine-design.md
validated_by:
  - gut-m1-suite
tags:
  - risk:exact-once
  - quality:acceptance-gate
related:
  - reference.godot-m1-transaction-time-spine-design
  - reference.state-command-lifecycle
---

# Godot M1 Transaction and Time Spine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and verify the complete Godot M1 durable command, state, persistence, receipt, quest replay, and lifecycle/offline foundation inside `project-a/`.

**Architecture:** Pure RefCounted domain objects hold serializable state and command logic; Autoload Nodes adapt Godot lifecycle and filesystem services. `CommandExecutor` is the sole mutation boundary and performs candidate-save-swap for durable work. GUT tests introduce every behavior through red-green-refactor cycles.

**Tech Stack:** Godot 4.7.1 stable, typed GDScript, GUT 9.7.1, JSON/FileAccess/DirAccess/Crypto.

## Global Constraints

- Work only in `project-a/game/**`, `project-a/tests/**`, and this plan's evidence; do not change the declared TapTap/Godot route.
- Do not modify `project-a/addons/godot_ai/**`.
- Preserve existing unrelated worktree changes, including `project-a/project.godot`.
- Persist only null/bool/int/String/Array/string-key Dictionary values; never persist Node or Resource.
- Durable commands must persist before memory swap and success.
- Save paths are `user://save_v1.json`, `.tmp`, `.bak`, and timestamped `.corrupt-*`.
- Offline time uses only `offline_anchor_unix` and caps credit at 28,800 seconds.
- Every production behavior starts with a failing GUT test.

---

### Task 1: GameState schema and validator

**Files:**
- Create: `project-a/game/scripts/state/game_state.gd`
- Test: `project-a/tests/unit/state/test_game_state.gd`

**Interfaces:**
- Produces: `GameState.create_new(now_unix: int, save_id: String, run_seed: int) -> Dictionary`
- Produces: `GameState.clone(state: Dictionary) -> Dictionary`
- Produces: `GameState.validate(state: Dictionary) -> Dictionary` with `{ok, code}`

- [ ] Write tests asserting the complete v1 keys, first-boot time values, deep-clone isolation, primitive-only validation, and rejection of missing/negative revision.
- [ ] Run the focused test and verify RED because `game_state.gd` is absent.
- [ ] Implement constants, deterministic default containers, deep duplication, recursive primitive validation, and stable validation codes.
- [ ] Re-run the focused test and full existing suite; expect all green.
- [ ] Commit the test and implementation together.

### Task 2: Sealed command registry and canonical fingerprint

**Files:**
- Create: `project-a/game/scripts/commands/command_class_registry.gd`
- Create: `project-a/game/scripts/commands/command_fingerprint.gd`
- Test: `project-a/tests/unit/commands/test_command_protocol.gd`

**Interfaces:**
- Produces: `CommandClassRegistry.classify(type: StringName) -> int`
- Produces: `CommandClassRegistry.is_internal(type: StringName) -> bool`
- Produces: `CommandFingerprint.canonical_json(value: Variant) -> Dictionary`
- Produces: `CommandFingerprint.calculate(type: String, payload: Variant, business_key: String) -> Dictionary`

- [ ] Write classification tests for all M1 command families, unknown commands, and attempted caller class overrides.
- [ ] Write canonical tests for UTF-8 byte-sorted keys, nested arrays/dictionaries, integer-only numbers, and float/Node/Resource rejection.
- [ ] Write a golden fingerprint test that independently assembles `uint32_be(length)||UTF-8` segments and compares SHA-256 hex.
- [ ] Run the focused test and verify RED due to missing protocol classes.
- [ ] Implement the sealed maps, canonical encoder, length prefix, and Crypto SHA-256 calculation.
- [ ] Re-run focused and full tests; expect all green, then commit.

### Task 3: Receipt ledger and pure quest replay guard

**Files:**
- Create: `project-a/game/scripts/state/receipt_ledger.gd`
- Create: `project-a/game/scripts/domain/quests/quest_reducer.gd`
- Test: `project-a/tests/unit/commands/test_receipt_ledger.gd`
- Test: `project-a/tests/unit/quests/test_quest_reducer.gd`

**Interfaces:**
- Produces: `ReceiptLedger.lookup(state, command_id, fingerprint, business_key) -> Dictionary`
- Produces: `ReceiptLedger.record_value(state, receipt) -> void`
- Produces: `ReceiptLedger.record_causal(state, receipt) -> void`
- Produces: `ReceiptLedger.record_reversible(state, receipt, capacity := 512) -> void`
- Produces: `QuestReducer.reduce(quest_state: Dictionary, events: Array) -> Dictionary`

- [ ] Write tests for same-ID replay, command-ID mismatch, business-key mismatch, lifetime value retention, 512 reversible eviction, and causal retention after 600 entries.
- [ ] Write quest tests proving duplicate event IDs do not advance progress and terminal/claimed quests ignore old or new matching events.
- [ ] Run focused tests and verify RED due to missing ledger/reducer.
- [ ] Implement dictionary-indexed lifetime ledgers, a bounded reversible order, and a side-effect-free quest reducer.
- [ ] Re-run focused and full tests; expect all green, then commit.

### Task 4: Save codec, migration, validation, and recovery

**Files:**
- Create: `project-a/game/scripts/persistence/save_codec.gd`
- Create: `project-a/game/scripts/persistence/save_migrations.gd`
- Modify: `project-a/game/scripts/autoloads/save_manager.gd`
- Test: `project-a/tests/unit/persistence/test_save_codec.gd`
- Test: `project-a/tests/integration/test_save_recovery.gd`
- Create: `project-a/tests/fixtures/saves/save_v0.json`
- Create: `project-a/tests/fixtures/saves/save_corrupt.json`

**Interfaces:**
- Produces: `SaveCodec.encode(state: Dictionary) -> String`
- Produces: `SaveCodec.decode(text: String) -> Dictionary` with `{ok, state, code}`
- Produces: `SaveMigrations.to_current(raw: Dictionary) -> Dictionary`
- Produces on SaveManager: `configure_paths_for_test(base_path: String)`, `save_candidate(candidate, saved_at_unix) -> Dictionary`, `load_state() -> Dictionary`

- [ ] Write codec and migration tests for v1 round-trip, v0 defaults, invalid JSON, invalid engine objects, and field equality.
- [ ] Write filesystem tests for tmp rejection, primary preference, corrupt-primary preservation, validated backup recovery, and low-revision rejection.
- [ ] Run focused tests and verify RED against the current signal-only SaveManager.
- [ ] Implement canonical encoding/decoding, deterministic migration, isolated test paths, single-writer guard, tmp write/flush/readback, backup, replace, installed-primary verification, and corrupt preservation.
- [ ] Re-run focused and full tests; expect all green, then commit.

### Task 5: CommandExecutor candidate-save-swap and crash matrix

**Files:**
- Create: `project-a/game/scripts/commands/command_result.gd`
- Create: `project-a/game/scripts/commands/command_executor.gd`
- Test: `project-a/tests/integration/test_command_executor.gd`
- Test: `project-a/tests/integration/test_command_crash_matrix.gd`

**Interfaces:**
- Produces: `CommandExecutor.configure(save_port, clock_port, initial_state)`
- Produces: `CommandExecutor.execute(envelope: Dictionary) -> Dictionary`
- Produces: `CommandExecutor.execute_internal(type: StringName, payload: Dictionary, business_key: String) -> Dictionary`
- Produces: `CommandExecutor.current_state() -> Dictionary`
- Consumes: GameState, registry, fingerprint, receipt ledger, quest reducer, and `save_port.save_candidate`.

- [ ] Write tests for unknown type, expected revision, ID/key mismatch, duplicate receipt return, and external internal-command denial.
- [ ] Write injected P0-P4 save-failure tests proving pre-save failures do not swap, post-install retry returns the receipt, and value delta occurs exactly once.
- [ ] Run focused tests and verify RED due to missing executor.
- [ ] Implement envelope validation, internal capability, candidate clone/reducers/invariants/receipt, durable persistence, post-save swap, reversible ring/debounce seam, and stable error results.
- [ ] Re-run focused and full tests; expect all green, then commit.

### Task 6: Offline settlement and lifecycle internal commands

**Files:**
- Create: `project-a/game/scripts/domain/idle/offline_settlement.gd`
- Modify: `project-a/game/scripts/autoloads/app_lifecycle.gd`
- Test: `project-a/tests/unit/idle/test_offline_settlement.gd`
- Test: `project-a/tests/integration/test_lifecycle_commands.gd`

**Interfaces:**
- Produces: `OfflineSettlement.calculate(state: Dictionary, now_unix: int) -> Dictionary` with `{effective_end, elapsed_seconds, credited_seconds}`
- Produces on AppLifecycle: `configure(executor, clock)`, `poll_heartbeat()`, and notification forwarding without direct state/save writes.
- Consumes: executor internal commands `__lifecycle_pause_anchor`, `__lifecycle_heartbeat_anchor`, `__lifecycle_resume_settle`.

- [ ] Write calculation tests for normal delta, rollback, exact 8h, and 48h jump.
- [ ] Write lifecycle tests for internal authorization, 250ms edge debounce, pause failure memory stability, 20 heartbeats to t=1200 plus resume at t=1500 crediting exactly 300 once, duplicate resume, and returned-clock catch-up.
- [ ] Run focused tests and verify RED because settlement and lifecycle wiring are absent.
- [ ] Implement pure settlement math, three internal reducers, heartbeat scheduling seam, edge debounce, and serialized pause retry budget.
- [ ] Re-run focused and full tests; expect all green, then commit.

### Task 7: Game bootstrap and first durable save

**Files:**
- Modify: `project-a/game/scripts/autoloads/game.gd`
- Test: `project-a/tests/integration/test_game_m1_bootstrap.gd`
- Modify: `project-a/tests/integration/test_project_bootstrap.gd`

**Interfaces:**
- Produces on Game: `signal game_ready`, `get_state() -> Dictionary`, `execute_command(envelope) -> Dictionary`.
- Consumes: SystemClock, SaveManager, EventBus, CommandExecutor, and AppLifecycle.

- [ ] Write tests proving first boot initializes anchor/last-seen to now, last-settled to zero, performs one durable save before `game_ready`, grants no offline credit, and existing autoload order remains intact.
- [ ] Run focused tests and verify RED against the M0 boot flag.
- [ ] Implement load-or-create bootstrap, executor ownership, lifecycle configuration, event emission after commit, and the public command facade.
- [ ] Re-run focused and full tests; expect all green, then commit.

### Task 8: M1 exit gate and independent verification

**Files:**
- Preserve: `project-a/tools/verify_m0.sh` (its recursive GUT command already includes all `tests/**`).
- Create: `project-a/tools/verify_m1.ps1` for the current Windows environment.

**Interfaces:**
- Produces: one finite command that runs editor import, mobile/compatibility startup, and all GUT tests with Godot 4.7.1.

- [ ] Write the verifier script with explicit executable/project arguments, nonzero propagation, and no network or addon modification.
- [ ] Run formatting/diagnostics on changed GDScript files.
- [ ] Run editor, mobile, compatibility, and complete GUT suites; require zero failures and zero parser errors.
- [ ] Run targeted crash/replay/offline/backup suites again and capture counts.
- [ ] Inspect `git diff --check`, protected-addon hash/status, and unrelated working-tree preservation.
- [ ] Dispatch an independent reviewer/verifier; fix every HIGH/CRITICAL issue and rerun the full gate.
- [ ] Commit the final verifier/evidence-safe adjustments.
