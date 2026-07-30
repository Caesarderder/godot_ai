---
name: caesar-loop
description: Turn a game request into a short, executable Gauntlet Loop prompt, then use that prompt to build or substantially improve the game through independent maker–critic loops, reproducible evidence, integration passes, and target-player playtests. Use for browser, engine, or native game projects when the request calls for AAA-quality visuals, better game feel, procedural assets, an agentic game-production workflow, or iterative game polish.
---

# Caesar Loop

First compile the user's request into a strong, short Gauntlet Loop prompt. Publish that prompt in the ordinary assistant response, then use it as the execution contract. Do not promise AAA quality; demonstrate progress against an inspectable bar and player outcomes.

## Non-negotiables

- Inspect the current game, docs, runtime, and existing validation before changing it.
- Define a playable outcome and an inspectable quality bar before delegating builders.
- Make critics fresh and independent. Give them the build and bar, not the builder's rationale.
- Let critics inspect running gameplay, captures, measurements, and player feedback—not summaries.
- Treat visual quality, frame pacing, correctness, accessibility, and fun as separate gates.
- Never use protected reference art, models, textures, audio, or screenshots as shipped assets. Use them only as comparison material when authorized.

## Operating boundary

Caesar Loop is an execution **contract**, not a claim that the repository contains
an LLM runtime or an automatic evaluator. Before delegating, establish what the
actual host can do (agent spawning, isolated worktrees, browser/runtime control,
structured results, and persistence). Keep the orchestration state in a visible
progress artifact; do not imply that an external runner's retries, memory, model
selection, or reviewer independence are implemented by the game repository.

Every delegated unit needs an explicit ownership/interface boundary. Prefer
directory or module ownership plus stable runtime APIs and event contracts over
cross-editing imports. A change that needs a shared contract must be escalated to
the lead/integrator rather than silently edited by several builders.

## Phase 0 — Compile the Gauntlet prompt

Treat the user's message as raw design intent, not as an implementation plan. Inspect the project and extract: target player/platform, the 20–60 second player outcome, constraints, and any supplied references. If no usable reference is supplied, propose one concrete, inspectable comparison or measurement and state its limit before writing the prompt.

**Your first deliverable must be exactly this visible block:**

```markdown
Quality bar: [one sentence explaining the concrete comparison or measurement]

Gauntlet Loop prompt:
> [a short runnable prompt]

Execution contract: [one sentence naming the initial vertical slice and the first evidence to collect]
```

The generated prompt must be 80–180 words, written in the user's language, and contain all of the following:

1. The outcome—not a prescribed architecture.
2. The concrete quality bar and the rule that critics inspect real output against it.
3. A lead agent that decomposes work by independently judgeable units and change coupling.
4. Separate builders and fresh harsh critics; blind A/B where practical.
5. The repeat condition: return the largest evidence-backed gap to a builder until the bar is met or the user stops the run.
6. A live progress artifact and whole-game integration pass.
7. A prohibition on shipping copied reference assets, plus performance and player-validation evidence appropriate to the project.

Keep the prompt short. Do not insert a detailed architecture, a fixed agent count, a fixed round count, or a speculative task list. Use [references/prompt-compilation.md](references/prompt-compilation.md) before generating it. Once published, proceed directly with the execution contract unless the user asks to revise the prompt.

## Phase 1 — Frame the target

Write a compact **player outcome contract** before implementation:

1. Target player and platform.
2. One 20–60 second playable fantasy, including control, threat, choice, feedback, and an outcome.
3. The one or two reference experiences or measurable bars. Name the exact camera/view, platform, and situation being compared.
4. Non-negotiable constraints: engine, asset licensing, performance target, accessibility, time/compute budget.
5. Evidence required to call the slice successful: runtime capture, automated checks, performance run, and target-player observation.

Do not use “AAA,” “beautiful,” or “fun” as acceptance criteria. A proposed bar must state what it can and cannot measure.

Before broad implementation, establish a project **ownership map** using
[references/project-structure.md](references/project-structure.md). It must name:

- the thin composition root and shared runtime/kernel surface;
- feature or subsystem directories with one accountable owner each;
- the public contracts that connect features (events, interfaces, schemas, or
  adapters), rather than cross-feature internal imports;
- development-only scenario/debug surfaces, separate from shipped features; and
- the build, runtime, capture/diff, profile, functional-test, and player-evidence
  routes.

Adapt the names and depth to the engine and project size. Do not create empty
layers, managers, or services merely to resemble the template.

## Phase 2 — Establish the evidence rig

Read the project's architecture and validation routes. Then create or verify:

- A deterministic seed/clock where feasible.
- Named repeatable scenarios: static composition, close material/detail, action/impact, UI readability, and a gameplay stress scene.
- A fast review path for critics and a strict regression path for gates. The latter must use the same resolution, camera, state, settle-frame budget, and temporal reset every time; isolate scenarios in fresh sessions/pages when particles, decals, exposure, animation, or other temporal state can leak.
- A visual diff gate for changes claimed to be pixel-neutral.
- A real-play performance path that measures frame-time percentiles, worst hitches, memory/resource growth, and relevant load conditions—not only average FPS.
- Functional checks for the interaction that makes the slice playable.

Record the baseline before polishing. Ensure the capture driver, not wall-clock/RPC timing, controls the shutter frame; snapshot or avoid mutation of simulation time, RNG, and persistent gameplay state during warm-up. If the rig is not deterministic, label visual comparisons as directional and fix the rig before making pixel-perfect claims.

## Phase 3 — Build a credible vertical slice

Deliver one end-to-end playable loop before broad content expansion. It must include:

- Readable space and objective.
- Input, movement, camera, and a core action.
- An opposing force, consequence, and recoverable feedback loop.
- Distinct audiovisual feedback for important actions.
- A clear beginning, escalating moment, and resolution/retry.

Prefer the smallest slice that exposes the intended quality bar. A polished gun preview, character model, or screenshot is not a game slice unless a player can make meaningful choices with it.

## Phase 4 — Decompose by change coupling

Split work into the smallest units that can be built and judged independently, but group tightly coupled concerns under one owner. Typical independent units: a weapon silhouette, one material family, locomotion feel, combat readability, enemy silhouette, one VFX, HUD hierarchy, or audio transient.

Classify each concern before assignment:

- **Independent:** one owner can change and judge it through a stable interface and named scenario. These may run in bounded parallelism.
- **Coupled:** its output depends on shared lighting/exposure/tonemapping, camera/input feel, simulation clock/RNG, render contracts, or cross-cutting performance. Give it one owner and process it sequentially, then re-integrate; directory boundaries alone do not make it independent.

Keep coupled concerns sequential unless the project has a tested integration protocol. For every unit, write:

`owner → artifact → exact scenario → bar → measurable acceptance → allowed files/interfaces → rollback condition`

Use bounded parallelism only where ownership and interfaces are explicit. Record the wave plan in the progress artifact, including what is parallel, what is serialized, the canonical baseline, and handoffs to the integrator. Integrate after each wave, then run a fresh whole-game smoothing pass.

## Phase 5 — Run the maker–critic loop

For each unit:

1. Give a builder the contract, scenario, ownership boundary, current evidence, and one priority gap.
2. Have the builder change the running artifact and produce evidence.
3. Spawn a fresh critic. Do not include the builder's narrative or desired conclusion.
4. Make the critic compare the actual output against the bar, preferably blind A/B. It must select a winner, identify the single largest meaningful gap, name the exact scenario/artifact and evidence, and reject unverifiable claims. A critic assessment prioritizes work; it is not release or fun proof.
5. Send only that prioritized gap back to a builder. Repeat until the unit meets its threshold, improvements are immaterial, or the budget is reached.

Use the templates in [references/loop-templates.md](references/loop-templates.md). Use [references/quality-scorecard.md](references/quality-scorecard.md) for consistent structured critique.

## Phase 6 — Integrate and validate

After a wave, assign a fresh integrator to inspect the whole running game. It resolves style drift, broken interfaces, competing lighting/camera assumptions, regressions, and player-flow discontinuities. Do not let it redesign all completed work without evidence.

Run the applicable gates:

| Claim | Required evidence |
|---|---|
| It builds/runs | project build plus boot/runtime check |
| A regression is absent | focused automated check or reproducible scenario |
| Visuals are unchanged | repeated deterministic captures from isolated state and visual diff |
| Visuals improved | before/after captures and independent comparative critique |
| Performance improved | repeated real-play percentile/hitch profile at target hardware/settings, including relevant compilation/resource attribution |
| Controls/combat feel good | target-player observation and short interview; automation is insufficient |
| It is ready | all declared acceptance criteria, known defects, and remaining risks recorded |

Never accept a critic assessment alone as proof of fun. Observe at least three target players for a new core loop when practical; anonymize feedback and report the player, task, observed behavior, and evidence separately from inference.

## Completion and reporting

Stop only when the user stops the loop, the declared threshold is met, or the next gap is no longer material for the stated player outcome. Report:

- The player outcome and the selected bar.
- Baseline versus final evidence.
- What independent critics and players observed.
- Pass/fail status for each gate.
- Remaining gaps, uncertainty, and the next highest-value loop.

For each conclusion, label the evidence separately from the inference. Preserve
failed gates, rejected changes, and unavailable evidence in the progress artifact:
they prevent a later agent from repeating a disproven path.

Do not claim that a game is AAA, fun, or production-ready without evidence appropriate to that claim.
