---
name: game-vertical-slice
description: Build or evaluate a representative vertical slice of a Godot 4.6 GDScript Web game. Use only when the user explicitly invokes $game-vertical-slice or selects a skill book containing it; do not infer it from an ordinary implementation request. Do not use for a disposable mechanic prototype or treat an existing prototype as production code by default.
---

# Game Vertical Slice

Turn a proven first playable into one short, coherent experience that answers two questions: does the game deliver its promise at representative quality, and can the team build the rest by repeating this production path?

Target Godot 4.6.x, typed GDScript, the Compatibility renderer, and single-threaded Web delivery. Preserve a narrower project target when one is already documented.

Activation is explicit-only: ordinary build, fix, or implementation requests stay on Codex's native
path unless the user selects this workflow by name or through a skill book.

## Contract

- Build a complete slice, not a feature pile. The player must enter, understand, act, face pressure, succeed or fail, recover or finish, and leave with a reason to continue.
- Represent final intent in every included discipline. Content quantity may be tiny; interaction, readability, feedback, and production method may not be knowingly fake.
- Do not copy a disposable prototype into production automatically. Inspect it for learnings, record reusable decisions, then implement through the project's production scenes, data, architecture, and asset pipeline.
- Use real project and runtime evidence. A design document, unchecked box, or plausible description is not proof that the slice works.
- Keep deferred systems outside the slice unless the core promise depends on them.

Read [references/vertical-slice-brief.md](references/vertical-slice-brief.md) when defining or revising the slice. Read [references/vertical-slice-checklist.md](references/vertical-slice-checklist.md) before declaring it ready.

## 1. Establish the evidence baseline

Inspect the smallest relevant product design, current scenes, scripts, assets, tests, project settings, and recent runtime evidence. Identify:

- the game's player promise and two or three design pillars;
- the first playable behavior already proven;
- which prototype shortcuts exist and whether any code is genuinely production-ready;
- the target session length, input methods, viewport range, and Web delivery constraints;
- the riskiest unresolved experience and production assumptions.

Label absent evidence as unknown. Do not infer that a system works because files for it exist.

## 2. Define one bounded experience

Write a slice brief using the reference template. It must name:

- the opening state and how a new player learns the first meaningful action;
- the 30-second core loop and the decisions that make repetition interesting;
- one compact content arc with introduction, variation, escalation, climax, and resolution;
- explicit success, failure, restart, pause, and quit paths;
- what representative final quality means for this game;
- excluded dreams and the assumptions this slice will not test;
- measurable quality and playtest questions.

Prefer one polished loop of roughly 3–10 minutes over several incomplete systems. Adjust the duration when the game's natural loop is shorter or longer.

## 3. Build the representative spine

Implement in playable order:

1. **Entry and orientation:** launch, first readable screen, controls, immediate goal, and first action.
2. **Core loop:** input, simulation, challenge, consequence, reward, and repeat.
3. **Content arc:** at least one meaningful variation and escalation rather than repeated identical content.
4. **Outcome paths:** success, failure, retry or recovery, and a clear end state.
5. **Presentation:** representative art direction, animation, camera, VFX, audio, and game-feel feedback for every critical action.
6. **HUD and UX:** only information required for decisions; complete mouse, keyboard, and applicable gamepad paths; loading, empty, paused, error, and confirmation states where relevant.
7. **Continuity:** settings persistence and save/load only to the depth needed by the slice, including an understandable failure path when browser persistence is unavailable.
8. **Web resilience:** responsive layout, resize, focus loss and recovery, tab suspension, audio unlock, and restart behavior.

Use the installed domain skills for implementation details. Do not reproduce their code recipes here.

## 4. Hold a quality convergence pass

Walk through the slice as one experience rather than reviewing departments separately. Fix discontinuities such as:

- the goal is explained but not reinforced by feedback;
- mechanics work but success or failure is ambiguous;
- art is representative but HUD, menus, or audio remain placeholder quality;
- content escalates numerically without changing player decisions;
- settings or save state contradict the runtime behavior;
- a browser reload, resize, focus change, or muted start breaks the loop;
- accessibility options exist but cannot be reached or do not persist.

Every included surface must have an owner in the scene/data architecture and a falsifiable acceptance condition.

## 5. Verify in the real runtime

Use the project's existing tests and runtime checks for the evidence pass. At minimum, require:

- the project's automated tests and headless import/scene smoke commands with recorded exit codes;
- a fresh single-threaded Web build using the configured Godot runtime;
- the complete slice played from launch to both success and failure in a real browser;
- relevant input, resize, focus/tab, audio, settings, and save/reload checks;
- observed performance against explicit budgets on the target browser/hardware class;
- at least one no-guidance playtest by someone who did not implement the path, or an explicit `NOT RUN` gap.

Playtest notes must separate observation from interpretation. “Player stopped for 18 seconds at the upgrade choice” is evidence; “the menu is confusing” is a hypothesis to investigate.

## 6. Decide the gate

Use exactly one verdict:

- `READY`: all required checks ran and passed; the slice demonstrates the promise and a repeatable production path.
- `CONCERNS`: the slice is playable and evidenced, but named quality or scalability risks remain before full production.
- `BLOCKED`: a required path fails, representative quality is missing, or required evidence was not run.

Report the slice scope, exact evidence, observed player behavior, deviations from final intent, reusable production decisions, unresolved risks, and the next smallest action. Never convert `NOT RUN` into `READY`.
