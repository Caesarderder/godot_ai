# UI deliverable contract

Use this checklist for concept images, UX specifications, and implementation handoffs.

## Evidence summary

- Product sources:
- Screen/domain sources:
- Runtime scene and script:
- View data and commands:
- Tests or captures:
- Screenshot role:
- Design/runtime conflicts:

## Screen contract

- Player question:
- Two-second answer:
- Dominant world/content region:
- Primary action:
- Maximum two secondary actions:
- Persistent context:
- Contextual detail:
- Success feedback:
- Failure or blocked feedback:

## State matrix

Describe only states that materially change hierarchy or action:

| State | World emphasis | Context panel | Primary action | Blocking feedback |
|---|---|---|---|---|
| Default | | | | |

## Layout specification

For each region record purpose, priority, approximate viewport share, content, interaction, responsive behavior, and engine owner. Do not specify decoration before purpose.

## Visual specification

- Game-derived visual thesis:
- Shape language:
- Semantic palette:
- Typography hierarchy:
- Icon families:
- World/UI integration:
- Motion and feedback:
- Prohibited generic patterns:

## Image-generation prompt requirements

- Use case must be `ui-mockup`.
- Declare the actual target platform, aspect ratio, and native validation resolution.
- Treat screenshots as content and defect evidence, not composition references.
- Explicitly allow complete layout reconstruction.
- Include only verified labels, resources, actions, facilities, and destinations.
- Describe one representative progression state.
- Keep the playable world and interaction targets readable.
- Require practical engine-reproducible panels, controls, and spacing.
- Avoid invented systems, cinematic scenery that hides gameplay, arbitrary English, fake microtext, and generic SaaS cards.

## Implementation handoff

Map each visible element to:

- scene/node owner;
- view-model field;
- emitted signal or command;
- enabled/disabled rule;
- visual states;
- target size and anchoring;
- verification route.

Do not let the UI write domain state directly.
