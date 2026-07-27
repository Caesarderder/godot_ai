---
name: ability-progression
description: Use when implementing Godot 4.6 GDScript stats, modifiers, levels, experience, abilities, cooldowns, status effects, unlocks, and skill trees for Web games
---

# Ability and Progression for Godot 4.6 Web

Own runtime stats and ability lifecycle. Reuse **resource-pattern** for authored definitions, **save-load** for persistence, **state-machine** for actor state, **combat-system** for damage resolution, **game-balance** for numeric tuning, and **godot-ui** for presentation.

## Separate definitions from runtime state

- Immutable definitions: stable ID, tags, base values, prerequisites, costs, cooldown, and presentation references.
- Runtime state: current level/XP, active modifiers, remaining cooldowns, charges, learned IDs, and status durations.
- Derived values: recompute from base plus ordered modifiers; do not persist caches unless a measured need proves it.

Use stable IDs across saves and content revisions. Never persist `Node`, `Callable`, or scene references. Validate loaded IDs against the current definition registry and preserve unknown-ID migration behavior in **save-load**.

## Deterministic modifier pipeline

Resolve in documented phases such as:

`base -> flat additions -> multiplicative modifiers -> caps -> final`

Give each modifier a source ID, operation, value, priority, tags, stack rule, and lifetime. Removal is by source/instance identity, never by approximate value. Define whether duration advances during pause and whether reapplication refreshes, stacks, replaces, or rejects.

## Ability lifecycle

`request -> eligibility -> reserve cost -> activate -> commit/cancel -> cooldown -> ready`

Eligibility checks resource cost, learned state, actor state, target validity, charges, and cooldown without side effects. Consume costs at one named commit point. Cancellation before commit must roll back reservations; after commit it follows the ability's explicit refund policy.

## Progression

Use monotonic XP thresholds or a clearly documented alternative. A single grant may cross several levels; process all crossings deterministically and emit one structured summary. Skill-tree unlocks require stable node IDs, validated prerequisites, and an explicit respec transaction.

## Verification

Test modifier order, duplicate sources, expiry boundaries, save/load reconstruction, multi-level grants, cooldown pause semantics, insufficient cost, cancel before/after commit, and content-ID migration. Runtime verification must still cover feedback clarity and whether the progression is understandable.
