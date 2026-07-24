---
name: game-narrative-design
description: Design or review gameplay-bound narrative for a Builda game. Use only when the user explicitly invokes $game-narrative-design or selects a skill book containing it; do not infer it from an ordinary implementation request. Cover story beats, characters, world rules, dialogue states, choices, quests, barks, and localization-ready content while preserving canon and implementation limits.
---

# Game Narrative Design

Make story content operate through player action, game state, space, and consequence. Own narrative intent and content contracts. Route mechanics to `$game-design`, space and encounter flow to `$game-level-design`, numeric progression to `$game-balance`, and state architecture to `$game-technical-design`.

This is an explicit-only design workflow. Ordinary build, fix, or implementation requests stay on Codex's native path.

Read [references/narrative-contract.md](references/narrative-contract.md) before creating or revising narrative content.

## Evidence and canon contract

- Inspect the accepted product design, existing narrative files, scenes, scripts, data, localization, saves, and current playable path before writing.
- Classify facts as `established canon`, `accepted proposal`, `provisional`, `hidden truth`, or `unknown`.
- Never resolve an unknown by silently inventing canon. Ask one focused question only when the choice materially changes the player experience.
- Existing text is evidence of authored content, not evidence that a player can trigger, understand, or complete it.
- Design against the project's current state and content architecture; do not assume a dialogue framework.

## Design workflow

### 1. State the narrative purpose

Define what the player should understand, feel, anticipate, or reconsider, and which gameplay moment makes that possible. Remove lore that does not support player motivation, choice, atmosphere, or a future payoff within scope.

### 2. Bind every beat to play

Express each material beat as:

`entry state -> player action or choice -> narrative response -> consequence -> next playable state`

Name the state owner, trigger, persistence, reset behavior, and fallback. A cutscene or dialogue line with no relationship to player state is presentation, not a complete narrative contract.

### 3. Give characters playable functions

For each relevant character, record their observable goal, pressure on the player, available actions, relationship change, gameplay function, and contradiction or boundary that keeps them specific. Reveal motive through decisions, behavior, environment, or mechanics before relying on exposition.

### 4. Bound the world

Define only the world rules needed for current play and its immediate consequences. Record who knows each fact and how the player can learn it. Protect mysteries as hidden truths rather than accidental contradictions; leave distant history and unused factions deferred.

### 5. Design branches and consequences

For each choice, specify availability condition, communicated stakes, immediate response, persisted state, downstream consequence, convergence point if any, and unavailable-state fallback. Avoid cosmetic choices presented as consequential. Keep branch count within implementation and QA capacity.

### 6. Use level and environment

Map narrative beats to locations, traversal, encounters, props, sound, repeated motifs, and state changes. Critical information requires a reliable delivery path; optional environmental details may deepen context but cannot be the only source of a required objective or rule.

### 7. Prepare content for localization

Use stable string identities, speaker and scene context, placeholders with named meaning, plural/gender notes where applicable, and explicit length or timing constraints. Keep gameplay logic out of translated text. Route file format and runtime integration to `$localization`.

## Review

Check for canon contradictions, actions without responses, choices without consequences, flags without ownership/reset/save behavior, critical clues hidden on optional paths, impossible chronology, repeated exposition, localization-hostile concatenation, and branch scope that cannot be implemented or tested.

Then define deterministic state checks separately from player evidence. Automated tests may prove trigger and persistence rules; only play can show whether motivation, stakes, pacing, or meaning landed.

## Output contract

Return narrative purpose and canon boundary, beat/state table, character and world rules only as needed, choices and consequences, environmental delivery, localization constraints, acceptance scenarios, implementation boundary, evidence, and open questions.

Prefer updating the current narrative source. If a new artifact is justified, use `docs/game/narrative/<slug>.md`. Keep it proportionate to the playable content; do not create a screenplay, lore bible, quest database, and dialogue tree unless the project actually needs and will implement them.

Finish with what is authored, what is integrated, which paths were exercised, what a player actually observed, and the next smallest narrative experiment.

## Attribution

This skill adapts selected methods from the MIT-licensed Donchitos/Claude-Code-Game-Studios `team-narrative` workflow at reviewed commit `984023ddac0d5e27624f2baacde6105e45de375f`. It removes Claude-specific runtime and approval assumptions. See [references/upstream-license.txt](references/upstream-license.txt).
