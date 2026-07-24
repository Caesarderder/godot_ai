> ← Back to [SKILL.md](../SKILL.md)

# Thin composition roots

## Contract

A composition root knows which collaborators exist and how they are connected. It does not absorb
their internal policy.

`main.gd` may:

- create or reference top-level feature scenes and application-lifetime services;
- inject required dependencies and connect top-level typed signals;
- select or replace the current top-level scene;
- preload fixed top-level `PackedScene` dependencies used only for application routing;
- coordinate startup, pause/resume, shutdown, and cross-scene transitions.

`main.gd` must not implement:

- gameplay rules, scoring, combat, spawning, progression, or AI;
- input polling, action interpretation, character motion, collision, or other physics;
- HUD/widget state, screen layout, animation details, or navigation internals;
- save serialization, storage schema, audio playback/routing details, arbitrary path handling,
  directory scanning, import configuration, or reusable resource-loading policy.

## Extraction signals

Move a responsibility to its owner when any of these is true:

- it has state or a lifecycle distinct from the composition root;
- it changes for a different product reason;
- another scene could reuse it;
- it can be tested or previewed independently;
- it handles per-frame input, physics, animation, or rendering;
- it translates between data formats or owns persistence/loading policy.

These are responsibility signals, not numeric limits. Do not use a line count, node count, or method
count as an architectural gate.

## Example flow

```text
Main (composition root)
  -> creates RunSession and HudScreen
  -> injects RunRules into RunSession
  -> connects RunSession.finished to Main._on_run_finished
  -> replaces RunSession with ResultsScreen

RunSession
  -> owns player, encounters, scoring, and level lifecycle

HudScreen
  -> owns widget state and presentation
```

`Main._on_run_finished()` may choose the results screen. Score calculation belongs to `RunSession`
or a session-owned rules object; rendering it belongs to `HudScreen` or `ResultsScreen`.

## Review questions

1. Is this method wiring collaborators or implementing one collaborator's behavior?
2. Does the root know private child details instead of a narrow typed contract?
3. Would changing combat, input, UI, save, audio, or asset policy require editing `main.gd`?
4. Can the owned feature be replaced or tested without reconstructing unrelated application state?
5. Are global services truly application-lived, or only convenient access points?

## Upstream basis

This contract applies Godot 4.6's
[scene organization](https://docs.godotengine.org/en/4.6/tutorials/best_practices/scene_organization.html),
[scenes versus scripts](https://docs.godotengine.org/en/4.6/tutorials/best_practices/scenes_versus_scripts.html),
and [Autoload scope](https://docs.godotengine.org/en/4.6/tutorials/best_practices/autoloads_versus_regular_nodes.html)
guidance. “Thin” is a responsibility boundary, not an official or local line-count limit.
