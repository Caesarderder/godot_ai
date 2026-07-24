---
name: gd-agentic-genre-blueprints
description: "Use when designing or implementing a Godot 4.6 Web game from a genre blueprint, including action, strategy, exploration, narrative, puzzle, simulation, social, racing, rhythm, sports, stealth, and survival games"
---

# GD-Agentic Genre Blueprints

Select one primary genre reference from the user's intended player loop. Add a second genre only for an explicit hybrid; genre references guide priorities and do not override canonical architecture or system owners.

## Action and combat

- [Action RPG](references/gd-agentic-genre-action-rpg.md)
- [Fighting](references/gd-agentic-genre-fighting.md)
- [Platformer](references/gd-agentic-genre-platformer.md)
- [Shooter](references/gd-agentic-genre-shooter.md)
- [First-person shooter](references/gd-agentic-genre-shooter-fps.md)

## Strategy and tactics

- [MOBA](references/gd-agentic-genre-moba.md)
- [RTS](references/gd-agentic-genre-rts.md)
- [Tower defense](references/gd-agentic-genre-tower-defense.md)

## Exploration and adventure

- [Metroidvania](references/gd-agentic-genre-metroidvania.md)
- [Open world](references/gd-agentic-genre-open-world.md)
- [Roguelike](references/gd-agentic-genre-roguelike.md)
- [Survival](references/gd-agentic-genre-survival.md)

## Narrative and puzzle

- [Card game](references/gd-agentic-genre-card-game.md)
- [Educational](references/gd-agentic-genre-educational.md)
- [Horror](references/gd-agentic-genre-horror.md)
- [Puzzle](references/gd-agentic-genre-puzzle.md)
- [Visual novel](references/gd-agentic-genre-visual-novel.md)
- [Romance](references/gd-agentic-genre-romance.md)

## Simulation and social

- [Battle royale](references/gd-agentic-genre-battle-royale.md)
- [Idle clicker](references/gd-agentic-genre-idle-clicker.md)
- [Party](references/gd-agentic-genre-party.md)
- [Racing](references/gd-agentic-genre-racing.md)
- [Rhythm](references/gd-agentic-genre-rhythm.md)
- [Sandbox](references/gd-agentic-genre-sandbox.md)
- [Simulation](references/gd-agentic-genre-simulation.md)
- [Sports](references/gd-agentic-genre-sports.md)
- [Stealth](references/gd-agentic-genre-stealth.md)

## Script prototypes

After selecting a primary genre, inspect only its matching `scripts/<gd-agentic-capability>/` directory when a code prototype is useful. These upstream scripts are preserved for adaptation, not pre-approved for direct execution or bulk copying. Multiplayer authority, native-platform integration, unsupported rendering, and unbounded workloads remain reference-only in the default Builda Web target.

## Apply

1. Identify the primary player verb, session loop, failure state, and progression loop.
2. Read one primary genre reference; read at most one secondary reference for a deliberate hybrid.
3. Route concrete mechanics to canonical gameplay, UI, audiovisual, data, and Web runtime owners.
4. Remove native, multiplayer-authority, or unsupported assumptions from the default Builda Web implementation.
5. Validate the actual loop in a playable Web preview rather than treating the blueprint as a complete design.
