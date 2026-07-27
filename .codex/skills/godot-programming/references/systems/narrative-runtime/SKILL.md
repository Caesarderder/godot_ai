---
name: narrative-runtime
description: Use when implementing Godot 4.6 GDScript dialogue playback, branching choices, narrative flags, conditions, typewriter text, speaker presentation, and localization-ready conversation runtime
---

# Narrative Runtime for Godot 4.6 Web

Own execution of accepted narrative content. Reuse **game-narrative-design** for authored beats and consequences, **localization** for string identity and translation, **save-load** for persisted flags, **resource-pattern** for content definitions, and **godot-ui** for layout.

## Data contract

Represent dialogue as stable node IDs with localized text keys, speaker IDs, optional conditions, effects, choices, and an explicit next node. Runtime state contains the current graph/node, revealed text state, and bounded local variables. Persist only durable flags and stable IDs.

Conditions must be side-effect free. Effects run once at a named commit point after a line or choice is accepted. Unknown nodes, missing translations, invalid conditions, and stale save IDs need deterministic fallbacks and diagnostic context.

## Playback lifecycle

`load graph -> enter node -> resolve availability -> present -> accept/choose -> commit effects -> advance/end`

- Separate content lookup from scene presentation.
- Do not branch on translated text.
- Do not concatenate localization fragments to manufacture sentences.
- A typewriter effect changes presentation only; skipping it must not skip the node's commit rules.
- Gate input so one confirm cannot both reveal and advance unexpectedly.
- Choice availability and consequences must match the authored narrative contract.

## Integration boundary

Expose structured events for speaker, line, choices, completion, and error. Consumers may animate portraits or play audio, but they cannot mutate graph truth. Narrative runtime does not create quests, save formats, inventory authority, or canonical story.

## Verification

Test deterministic branches, unavailable choices, effect idempotence, rapid confirm, skip/reveal, graph cycles, missing IDs, localization fallbacks, resumed saves, and scene teardown. Then run representative conversations at target viewport sizes and with long localized strings.
