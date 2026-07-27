---
name: game-level-design
description: Design or review a playable level, arena, room, tutorial, hub, puzzle, or encounter for a Builda game. Use only when the user explicitly invokes $game-level-design or selects a skill book containing it; do not infer it from an ordinary implementation request. Cover spatial flow, teaching, pacing, encounters, landmarks, checkpoints, accessibility, grayboxing, sequence breaks, and softlocks.
---

# Game Level Design

Turn a gameplay promise into a navigable, teachable, and testable playable space. Own the level contract and graybox evidence. Route game-wide rules to `$game-design`, story content to `$game-narrative-design`, and numerical tuning to `$game-balance`; return implementation to the user's native task.

This is an explicit-only design workflow. Ordinary build, fix, or implementation requests stay on Codex's native path.

Read [references/level-contract.md](references/level-contract.md) before drafting or reviewing a level.

## Evidence contract

- Current scenes, scripts, collision, navigation, camera behavior, and runtime observations outrank a level document.
- A scene that imports or boots does not prove that its flow is completable, readable, or enjoyable.
- A graybox can prove topology and rule integration without proving final art, pacing, or player comprehension.
- Never invent player routes, completion times, accessibility results, or browser behavior.

## Preflight

1. Read repository instructions, the accepted gameplay contract, current scenes and scripts, adjacent levels, input/camera constraints, available assets, and recent runtime evidence.
2. State the level's job in the wider experience: what the player enters knowing, what they should learn or demonstrate, and the state in which they leave.
3. Identify production bounds: target runtime, reusable modules, content budget, target inputs, viewport, and Web constraints.
4. Ask one focused question only when two spatial or progression directions would create materially different player experiences.

## Design workflow

### 1. Define the level promise

Write one observable sentence describing what the player does and feels here. Name the mechanic, decision, or mastery moment that proves it. Reject rooms and encounters that do not support that promise, recovery, or necessary pacing.

### 2. Map critical and optional flow

Describe entry state, critical path, optional branches, gates, returns, checkpoints, failure recovery, and exit state. Every gate needs an owner and an observable unlock condition. Optional content must not carry a clue or capability required by the critical path.

### 3. Teach through play

Introduce a new demand through:

`safe introduction -> constrained practice -> combined challenge -> independent use -> recovery`

Use fewer steps when the mechanic is already known. Prefer space, consequence, and repeatable feedback over explanatory text. Identify what happens when the player ignores or misunderstands the lesson.

### 4. Shape pacing and encounters

Alternate decision pressure, execution, recovery, orientation, and reward deliberately. For each encounter, specify its purpose, starting state, player choices, escalation, completion/failure condition, reset behavior, and relationship to the level promise. Do not fill empty space with arbitrary enemy counts.

### 5. Provide redundant wayfinding

Use landmarks, sightlines, composition, lighting, motion, sound, path width, and repeated shapes as mutually reinforcing cues. Do not encode critical meaning through color alone. Preserve enough time, space, contrast, and alternate input support for the intended audience; route UI implementation details to the appropriate UI skills.

### 6. Build and exercise the graybox

When implementation is requested, create the smallest playable graybox using current project conventions. Exercise:

- the critical path from entry through success, failure, restart, and exit;
- every gate, checkpoint, shortcut, optional return, and transition;
- sequence breaks, skipped triggers, backtracking, softlocks, and unreachable states;
- player orientation after spawn, interruption, checkpoint reload, and camera transition;
- collision, navigation, input, and Web behavior on the applicable target.

Automated traversal can prove reachability or state rules; it cannot prove readability or pacing. Use `$game-playtest` for uncoached player evidence and the repository's existing tests for regression closure.

## Output contract

Return the level promise and constraints, critical/optional flow, teaching and encounter sequence, wayfinding plan, state/gate ownership, graybox implementation boundary, acceptance scenarios, evidence obtained, and remaining player questions. Keep it concise enough to implement.

Prefer updating an existing level source of truth. If a new persistent artifact is justified, use `docs/game/levels/<level-slug>.md`. A document is not required when a small code or scene change plus explicit acceptance criteria is clearer.

Finish with the exact playable path exercised, failures discovered, evidence level reached, and the next smallest level experiment.

## Attribution

This skill adapts selected methods from the MIT-licensed Donchitos/Claude-Code-Game-Studios `team-level` workflow at reviewed commit `984023ddac0d5e27624f2baacde6105e45de375f`. It removes Claude-specific runtime and approval assumptions. See [references/upstream-license.txt](references/upstream-license.txt).
