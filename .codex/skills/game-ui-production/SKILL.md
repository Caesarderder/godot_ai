---
name: game-ui-production
description: Produce or redesign implementation-ready game UI and UX from repository evidence. Use when creating a game screen, replacing placeholder UI, redesigning a screenshot, generating a UI concept image, defining HUD or menu layouts, or preparing a Godot UI refactor. Requires reading the current game design, inspecting screenshots as evidence rather than templates, auditing related scenes/scripts/state/actions, deriving information architecture and interaction states, and validating the result against the target viewport before visual generation or implementation.
---

# Game UI Production

Build the UI from the game's actual player loop and runtime contract. Treat existing screenshots as evidence of current problems and available content, never as a layout that must be preserved.

## Required workflow

Do not generate a concept image or edit UI code until stages 1–5 are complete.

### 1. Establish the product truth

Use the repository knowledge map first when present. Read the smallest authoritative set covering:

- player promise, core loop, and current milestone;
- the screen's gameplay domain;
- onboarding or progression state relevant to the screen;
- platform, viewport, input, accessibility, and runtime constraints;
- current implementation status when design and code may differ.

Record accepted facts separately from legacy or stale behavior. Stop and report conflicts that would materially change the screen.

### 2. Audit the current screen

Inspect every supplied screenshot at full resolution. Classify observations as:

- content that must remain available;
- layout or hierarchy problems;
- misleading, duplicated, stale, or developer-facing information;
- missing gameplay feedback;
- controls whose state or consequence is unclear.

Do not infer that the screenshot's panel positions, dimensions, tabs, navigation, color palette, or visual style are requirements.

### 3. Audit implementation reality

Read the owning scene, UI script, view-model/data projection, domain state, command handlers, and relevant tests or screenshot tools. Identify:

- data the runtime can actually display;
- actions the player can actually trigger;
- normal, selected, focused, disabled, locked, ready, full, warning, success, and in-progress states;
- screen transitions and durable command boundaries;
- reusable world-space and screen-space elements;
- responsive constraints and minimum touch targets.

Do not invent a button, resource, progression system, building, or navigation destination unless the design explicitly marks it as a future concept.

### 4. Derive the screen contract

Write a compact contract before styling:

- **Player question:** what question brought the player here?
- **Two-second answer:** what must be understood immediately?
- **Primary action:** exactly one dominant action for the current state.
- **Secondary actions:** at most two adjacent suggestions.
- **World interaction:** what the player selects or manipulates directly.
- **Persistent context:** only information required across this screen.
- **On-demand detail:** content moved into contextual panels, tooltips, or deeper screens.
- **Feedback:** visible response for every action and state change.

Build a state matrix for materially different progression states. A single static layout must not pretend every state has the same primary action.

### 5. Reconstruct information architecture and layout

Start from player attention, thumb reach, world visibility, and action frequency. Freely move, merge, collapse, or remove existing regions.

Prioritize in this order:

1. current world situation and directly interactive game content;
2. current objective or selected object;
3. one primary action and its consequence;
4. bottleneck, readiness, risk, or production feedback;
5. secondary navigation and detailed economy.

Use the smallest number of persistent panels. Prefer contextual panels that change with selection over simultaneous dashboards. Keep the playable world dominant when the screen is world-driven.

Read [references/deliverable-contract.md](references/deliverable-contract.md) before producing a layout, image prompt, or implementation handoff.

### 6. Choose visual language from the game

Derive visual language from the game's genre, camera, characters, environment, narrative, and existing production assets. Define:

- shape language and panel construction;
- semantic colors that never act as the only state signal;
- typography levels;
- icon categories;
- motion and feedback intensity;
- how 2D UI relates to the 3D or 2D game world.

Avoid generic dashboards, arbitrary genre reskins, or decoration that cannot be reproduced by the target engine and asset pipeline.

### 7. Produce the artifact

For a concept image, use the image-generation capability only after writing the evidence summary and screen contract. Prompt it as a new `ui-mockup`; label the screenshot as a content/problem reference, explicitly permit layout reconstruction, and list only verified content and states.

For implementation, map every region to concrete engine nodes, data fields, signals, commands, and responsive behavior. Preserve domain authority: UI emits intent and never mutates game state directly.

### 8. Validate

Validate against the actual target resolution, not a desktop-only enlargement.

- Check the two-second answer and single primary action.
- Confirm world targets, labels, and controls do not overlap.
- Confirm touch targets, safe areas, text expansion, focus, and color-independent states.
- Compare every visible number and action with runtime data.
- Use existing screenshot capture, smoke tests, and domain tests when available.
- Mark generated text in concept images as illustrative if exact rendering is imperfect.

If the artifact fails a gameplay or implementation constraint, revise the layout before polishing the art.

## Required output before image generation

State these items concisely:

1. evidence read;
2. screen purpose and current progression state;
3. current UI failures;
4. verified content/actions;
5. proposed information architecture;
6. primary action and state variants;
7. target viewport and implementation constraints.

This gate prevents attractive but unusable mockups.
