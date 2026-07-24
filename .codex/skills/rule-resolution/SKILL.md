---
name: rule-resolution
description: Use when implementing deterministic Godot 4.6 GDScript turn order, action points, initiative, commands, undo, card decks, effect stacks, rounds, and rule resolution
---

# Rule Resolution for Godot 4.6 Web

Own ordered rule execution for turn-based, card, puzzle, strategy, sports, and simulation systems. Reuse **state-machine** for actor presentation states, **resource-pattern** for definitions, **save-load** for snapshots, **game-balance** for tuning, and **objective-loop** for win/goal lifecycle.

## Authoritative state

Keep one plain-data match state with stable participant, entity, card, and command IDs. Views submit commands; they do not mutate truth. A command validates against the current state revision, then produces deterministic state changes and domain events.

Use an explicit phase model such as:

`setup -> round start -> turn start -> action window -> resolution -> turn end -> round end -> complete`

Define who may act, when priority passes, how ties break, and what happens when an actor disappears. Reject stale commands by revision/generation before mutation.

## Cards and effects

A deck is an ordered list of stable card-instance IDs. Seed and record shuffle inputs when replayability matters. Effects enter an explicit queue/stack with source, targets, priority, and cancellation rules. Resolve until the queue is empty or a bounded safety limit trips; never recurse without a limit.

## Undo and replay

Prefer command logs plus deterministic reconstruction or bounded snapshots. Undo is allowed only across commands whose side effects are fully represented in state. Audio, animation, network calls, file writes, and random draws without recorded inputs are not reversible.

## Verification

Test turn rotation, ties, actor removal, stale commands, duplicate submission, empty decks, shuffle determinism, effect ordering, bounded loops, snapshot restore, undo boundaries, and completion races. Compare reconstructed state hashes for the same seed and command log.
