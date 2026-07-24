---
name: objective-loop
description: Use when implementing Godot 4.6 GDScript objectives, quests, collection goals, checkpoints, revival, waves, time trials, secrets, completion, rewards, and reset lifecycle
---

# Objective Loop for Godot 4.6 Web

Own the runtime lifecycle of a measurable goal. Reuse **game-design** for rule intent, **game-level-design** for encounter and checkpoint placement, **save-load** for persistence, **game-economy** for rewards, and **narrative-runtime** for dialogue execution.

## Model

Use stable objective IDs and explicit states:

`inactive -> available -> active -> completed | failed | cancelled`

An objective definition describes conditions and presentation metadata. Runtime state records only progress, lifecycle state, generation/session identity, and committed reward state. Completion and reward delivery are separate idempotent commits so retries cannot duplicate grants.

## Event handling

Subscribe to domain events rather than polling the whole scene tree. Validate event identity, objective generation, source, and amount before applying progress. Clamp progress and make completion monotonic unless the design explicitly allows regression.

Collections count accepted item transactions, not UI totals. Waves count authoritative spawn/defeat lifecycle. Time trials use one monotonic clock owner. Secrets commit stable discovery IDs. Checkpoints record a restoration contract; revival never silently invents save authority.

## Reset and persistence

Define behavior for scene reload, retry, death, round transition, abandoned quest, and content revision. Temporary run progress and durable account progress must not share an implicit namespace. Route file format, migration, and `user://` persistence to **save-load**.

## Verification

Test duplicate/out-of-order events, completion at boundaries, reward retry, restart after completion, failure-versus-completion races, stale session events, unavailable content IDs, checkpoint restoration, and Web refresh persistence limits. Runtime play verifies goal communication and recovery clarity.
