---
name: game-technical-design
description: Turn an approved game concept or feature scope into an evidence-based technical design for a Godot 4.6 GDScript Web game. Use only when the user explicitly invokes $game-technical-design or selects a skill book containing it; do not infer it from an ordinary implementation request. Do not use for a small isolated fix whose implementation boundary is already clear.
---

# Game Technical Design

Convert player-facing intent into the smallest buildable plan that can be disproved by code, runtime, and playtest evidence. Inspect the project before designing; a polished document is not progress if it does not reduce implementation risk.

Activation is explicit-only: ordinary build, fix, or implementation requests stay on Codex's native
path unless the user selects this workflow by name or through a skill book.

## Operating contract

- Target Godot 4.6.x, typed GDScript, single-threaded Web, and Compatibility rendering.
- Treat current scripts, scenes, resources, project settings, tests, and export configuration as stronger evidence than an old design document.
- Preserve a coherent existing architecture. Do not redesign a project merely to match a preferred pattern.
- Separate confirmed facts, accepted decisions, inferences, and open hypotheses.
- Design one player-visible vertical slice at a time. Every milestone must end in something runnable or observable.
- Ask the developer only when a choice changes the game identity, commits substantial scope, creates external cost, or is difficult to reverse. Choose and record safe defaults for ordinary reversible decisions.
- Produce diagrams and tables only when they clarify ownership, state, sequence, or failure behavior. Do not manufacture artifacts to simulate progress.
- Stop at technical design unless implementation was also requested. Hand a First Playable milestone
  to `game-prototype`; otherwise hand the bounded design back to the user's implementation task.

Read [references/technical-design-template.md](references/technical-design-template.md) when writing the deliverable. Read [references/decision-lenses.md](references/decision-lenses.md) when a cross-domain trade-off or design review is required.

## 1. Establish project truth

Inspect the smallest relevant surface before proposing architecture:

1. Read repository instructions and the nearest product, architecture, and workflow indexes.
2. Inspect `project.godot`, the main scene, relevant `.tscn` and `.gd` files, Autoloads, input actions, addons, tests, export presets, and build scripts.
3. Trace the current player path and the direct callers/consumers affected by the proposed work.
4. Record the engine, renderer, language, Web/threading target, existing test framework, and runnable validation commands.
5. Check the worktree so the plan preserves unrelated user changes.

If the project is empty, say so and use `godot-project-setup` for the minimum foundation. If evidence conflicts with the product design, expose the conflict instead of quietly treating the desired architecture as current behavior.

## 2. Translate intent into contracts

Extract only requirements that change implementation:

- player verbs, visible feedback, success, failure, recovery, and restart;
- session boundary, scene transition, pause, retry, and persistence behavior;
- authoritative state, derived state, configuration, and save data;
- input methods, responsive UI, accessibility, localization, asset, and audio needs;
- expected scale and the cases that could make work unbounded;
- explicit non-goals and deferred content.

Rewrite vague statements as observable outcomes. For example, replace “combat feels responsive” with a playable sequence and the evidence that will be inspected. Keep unverified fun claims as hypotheses; do not turn them into fake binary technical facts.

## 3. Define ownership and data flow

For each participating system, identify:

| Concern | Required answer |
| --- | --- |
| Owner | Which scene or service creates, wires, and tears it down? |
| Lifetime | Node, scene, session, or application? |
| State | Who may mutate it, and what is derived? |
| Commands | Who calls which typed method? |
| Events | Which factual typed signal crosses which boundary? |
| Data | Which typed `Resource`, value object, or save record carries it? |
| Failure | What happens when a dependency, asset, or saved value is invalid? |

Prefer the nearest owner, direct typed calls for commands, local signals for facts, and explicit injection for known collaborators. Use an Autoload only for a demonstrated application-lifetime responsibility. Route detailed architecture questions to `godot-architecture`; do not duplicate its recipes in the technical design.

Include a compact ownership/data-flow diagram when three or more systems interact. Label save, UI, audio, and scene-transition boundaries rather than hiding them behind a generic manager.

## 4. Make only consequential decisions

Create an ADR candidate only when the choice is cross-cutting, expensive to reverse, or establishes a durable constraint. Examples include save format, application-lifetime ownership, scene transition model, third-party dependency, or a protocol shared by multiple systems.

For each candidate, capture context, decision, rejected alternatives, positive and negative consequences, migration/rollback, and validation. Keep local class layout and routine scene wiring in the technical design, not separate ADRs.

Use current repository ADR conventions when they exist. Do not create an ADR or add a dependency merely because the template has a section for it.

## 5. Convert uncertainty into bounded spikes

Use a spike only for a material unknown that cannot be resolved cheaply from current code or authoritative documentation. Define:

- one falsifiable question;
- the minimum disposable experiment;
- a time or scope bound;
- required evidence;
- proceed, adapt, and abandon criteria;
- a fallback that still protects the first playable.

Typical Web risks include unsupported rendering behavior, browser input/focus, audio startup, storage lifecycle, export size, scene-load stalls, and performance at actual content scale. Do not propose threads, native extensions, another language binding, or a different renderer as the default answer.

## 6. Plan vertical milestones

Order milestones by risk and player value, not by department or file type:

1. prove the riskiest interaction or platform assumption;
2. close the smallest playable loop: input -> response -> feedback -> outcome -> retry;
3. integrate persistence, UI, audio, and content required by that loop;
4. expand content only after the loop is playable and reviewed;
5. close Web and release evidence for the stated target.

Each milestone must name its player-visible outcome, in-scope files/systems, dependencies, acceptance observations, automated/headless checks, Web or gameplay evidence, and explicit non-goals. Avoid “implement subsystem” milestones that cannot be played or independently verified.

## 7. Run the second architecture pass when earned

When a gameplay spine already works, run a bounded second architecture pass before expanding
production scope. Read
`godot-architecture/references/architecture-hardening-pass.md` and audit actual cross-scene lifetime,
persistence, settings, audio, routing, signal, and performance pressure. Select only the necessary
`resource-pattern`, `save-load`, `audio-system`, or `godot-optimization` owner; do not propose all
systems by default.

The second-pass handoff must include the current and target service maps, Autoload promotion/rejection
reasons, an acyclic initialization graph, typed commands/signals/snapshots, failure semantics, a
one-boundary-at-a-time migration sequence, and regression evidence. Do not describe a list of manager
class names as architecture.

## 8. Review the design before handoff

Apply the relevant lenses from `decision-lenses.md`, then check:

- Ownership and data mutation have one accountable boundary.
- Scene replacement, pause, retry, save/load, and invalid-data paths are explicit where relevant.
- The plan uses current project patterns or justifies a migration.
- Every important risk is closed by evidence or converted to a bounded spike.
- Milestones produce working increments and do not depend on speculative infrastructure.
- Headless evidence is not presented as proof of browser behavior or fun.
- A First Playable milestone can be handed to `game-prototype`, or a later production milestone to
  the user's implementation task, without inventing missing product decisions.

## Output

Update an existing project technical design when it is authoritative. Otherwise propose a conventional location such as `docs/technical-design/<game-or-milestone>.md`, adapting to repository conventions. Use the template selectively; omit irrelevant sections.

Finish the handoff with:

```text
Ready milestone: <one player-visible increment>
Confirmed inputs: <project/design evidence>
Open decisions: <only genuine product or irreversible choices>
First validation: <narrow command or runtime observation>
Residual risk: <what remains unproved>
```
