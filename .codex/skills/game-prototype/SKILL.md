---
name: game-prototype
description: Build or repair the real first playable for a Builda Godot 4.6 GDScript Web game. Use only when the user explicitly invokes $game-prototype or selects a skill book containing it; do not infer it from an ordinary implementation request. Own implementation and current engine evidence; do not substitute a browser-only mockup, another engine, a design document, or an unrun code sample.
---

# Game Prototype

Own the first playable as a real Godot project. Implement the smallest loop that proves the game's
promise, integrate it into the current repository, and gather direct evidence. A plausible scene tree
or clean code review is not a playable result.

Target Godot 4.6.x, GDScript, Compatibility rendering, and Builda's single-threaded Web export.

Activation is explicit-only: ordinary build, fix, or implementation requests stay on Codex's native
path unless the user selects this workflow by name or through a skill book.

Read [references/first-playable-definition.md](references/first-playable-definition.md) before planning.
Read [references/verification.md](references/verification.md) before claiming completion.

## Required loop

The first playable must contain all of:

`input → world response → readable feedback → success or failure → restart → valid initial state`

Implement both success and failure. If the concept does not use traditional winning or losing, define
equivalent completion and interruption outcomes that exercise recovery and replay.

## Preflight

1. Read repository instructions, `project.godot`, current main scene, export presets, nearby scripts,
   assets, tests, and the accepted product-design/playable contract.
2. Preserve a coherent existing project. Do not replace scenes or structure merely to match examples.
3. Confirm the target loop, controls, perspective, success, failure, restart, and minimum feedback.
4. Identify the configured Godot executable and exact version. Do not download or switch engines.
5. List the minimum files and domain skills required. Avoid speculative systems and empty scaffolding.

If product behavior is still materially ambiguous, return the smallest design question to
`$game-design`. Do not make a genre convention silently binding.

## Implementation sequence

### 1. Establish a bootable project

Use `$godot-project-setup` only as needed. Keep a valid main scene, Compatibility renderer, semantic
Input Map actions, and responsive project settings. Add an autoload only when the current loop proves
a project-wide lifetime requirement.

### 2. Build one ownership spine

Choose a scene root that owns run state and the transition between playing, success, failure, and
restart. Give player, world/challenge, and HUD narrowly defined responsibilities. Use direct typed
calls or local signals for known relationships; consult `$godot-architecture` rather than introducing
a broad event bus.

### 3. Implement input and world response

Route semantic actions through the appropriate input callbacks. Make at least one deliberate player
input change meaningful world state. Use the relevant controller, physics, navigation, or UI skills
for the actual game type.

### 4. Implement feedback with the mechanic

Add the minimum feedback that makes cause and result legible: motion, state change, sound, hit or
selection cue, HUD update, or short transition. Do not postpone all feedback to a polish phase because
feedback is part of validating the interaction.

### 5. Complete the run lifecycle

Implement reachable success and failure states. Stop or redirect gameplay input appropriately, show
the outcome, and provide a restart action. Restart must reset owned mutable state, spawned objects,
timers, UI, and input mode without duplicated signal connections or stale async work.

### 6. Add proportionate checks

Test deterministic rules and restart-sensitive state using the project's existing framework. If no
framework exists, do not install one automatically; add the smallest deterministic smoke mechanism
the repository already supports and record the coverage gap.

### 7. Import, start, and export

Run current verification after implementation, not only before it. Use repository scripts first;
otherwise follow the command shapes in `verification.md`. Capture commands, exit codes, and failures.

### 8. Exercise the complete loop

Produce current execution evidence for the required loop. Prefer an interactive Godot run in which
the operator reaches success, failure, and restart. When interaction is unavailable, use a
scene-level integration driver that exercises semantic input or the same public gameplay entry
points, advances the real scene, observes feedback state, reaches both outcomes, restarts, and asserts
the documented initial state. A unit test of isolated rule objects is supporting evidence, not a
substitute for this scene lifecycle check.

## Scope control

Include only content needed to:

- teach the immediate goal;
- allow the core decision or skill expression;
- produce success and failure;
- demonstrate one reason to retry.

Use placeholder or existing assets when they preserve readability. Do not build progression, save
data, multiple levels, extensive menus, or final art unless the first-playable contract needs them to
prove the promise.

## Evidence and failure semantics

- **Import failure**: the project is not engine-valid; fix it before claiming a playable.
- **Start failure**: the main scene is not runnable; fix it before closing.
- **Loop not exercised**: report `ENGINE BOOT VERIFIED`, not a completed first playable.
- **Tests unavailable**: report `NOT RUN` with the missing framework or command; do not pass it.
- **Export unavailable**: report whether the preset, templates, binary, or environment is missing.
- **Browser run unavailable**: report an engine-verified prototype, not a Web-verified one.
- **Subjective fun unknown**: hand off a runnable build and explicit playtest hypothesis; do not claim
  the mechanic is fun from code inspection.

Do not weaken the loop to make checks pass. Fix the failure or preserve it as an explicit blocker or
concern according to the requested milestone.

## Completion gate

Claim **FIRST PLAYABLE VERIFIED** only when:

- the implementation matches the accepted contract;
- input changes the world through a player-visible rule;
- critical feedback communicates that change;
- success and failure are both reachable;
- restart produces a clean initial state;
- Godot import succeeds;
- the configured main scene starts in a bounded run;
- relevant deterministic checks pass;
- a current interactive run or scene-level integration driver exercises input, world response,
  feedback, success, failure, and restart against the real scene lifecycle.

If implementation, import, and start succeed but the loop was not exercised, report **ENGINE BOOT
VERIFIED — PLAYABLE LOOP NOT VERIFIED**. Report Web export and browser evidence separately. A first
playable cannot be called a verified Web prototype until export and browser runtime checks pass.

Finish with changed files, the implemented loop, exact evidence, missing evidence, and the next
playtest or vertical-slice step. Return integration ownership to the user's task.
