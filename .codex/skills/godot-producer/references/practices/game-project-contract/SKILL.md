---
name: game-project-contract
description: Maintain the project-level source of truth for player promise, scope, accepted rules, implementation references, verification evidence, decisions, and drift. Discover contextually for new projects or milestones, semantic scope changes, cross-role handoffs, document/runtime conflicts, and milestone or release acceptance. Do not activate for an isolated bug, visual polish, or refactor that does not change the contract.
---

# Game Project Contract

This is an internal capability of `$godot-producer`, not a seventh public skill. The producer is the
canonical owner; other roles consult this bundle through their short contract preflight.

## Activation gate

Use this capability only for:

- a new project or milestone;
- a material change to player promise, scope, rules, or acceptance criteria;
- a cross-role handoff whose meaning must survive implementation;
- a conflict between documents, implementation, or expected behavior;
- milestone, playtest, or release acceptance.

Do not start full contract governance for an isolated null fix, presentation-only adjustment, or
code cleanup with no semantic change. Read only the current role's relevant item and linked evidence,
not every project document.

## Required reading

1. Read [status-model.md](status-model.md) before changing state.
2. Read [contract-schema.md](contract-schema.md) before creating or editing an item.
3. Read [handoff-protocol.md](handoff-protocol.md) for role permissions and cross-role work.
4. Use [minimal-template.md](minimal-template.md) only when the project has no equivalent canonical
   documents.

## Project discovery

Start at `docs/index.md`. Follow its canonical contract link, normally `docs/game-contract.md`.
Large projects may split documents, but `docs/index.md` must identify exactly one canonical source
for each rule or value. Never duplicate an authoritative value to make a role-local copy.

## Operating protocol

1. Locate the smallest relevant contract item by stable ID.
2. Compare accepted intent, acceptance criteria, implementation reference, and verification evidence.
3. State the current evidence boundary: proposed, accepted, implemented, verified, deferred,
   rejected, or drifted.
4. Update only fields owned by the current role. Use a handoff for another role's field.
5. Preserve both sides of a disagreement and mark `drifted`; do not guess which side is correct.
6. Run `node scripts/validate-contract.mjs <project-root>` after structural edits.

The validator proves structure, references, state prerequisites, unique IDs, and index reachability.
It cannot prove that prose or numbers are semantically consistent, that code behaves as claimed, or
that playtest evidence is truthful.
