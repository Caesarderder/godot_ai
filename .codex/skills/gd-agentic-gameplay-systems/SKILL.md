---
name: gd-agentic-gameplay-systems
description: "Use for Godot 4.6 Web gameplay systems: abilities, combat, dialogue, economy, gameplay loops, inventory, quests, stats, save data, secrets, revival, state machines, and turns"
---

# GD-Agentic Gameplay Systems

Route gameplay implementation to the smallest relevant reference. Combine references only when the requested mechanic crosses clear ownership boundaries.

## Route

| Need | Read |
| --- | --- |
| Cooldowns, upgrades, combos, and skill trees | [ability system](references/gd-agentic-ability-system.md) |
| Hitboxes, damage, and invulnerability | [combat system](references/gd-agentic-combat-system.md) |
| Branching conversations and presentation | [dialogue system](references/gd-agentic-dialogue-system.md) |
| Currency, shops, prices, and loot | [economy system](references/gd-agentic-economy-system.md) |
| Collection objectives | [collection loop](references/gd-agentic-game-loop-collection.md) |
| Gathering and resource depletion | [harvest loop](references/gd-agentic-game-loop-harvest.md) |
| Checkpoints, clocks, and ghost data | [time-trial loop](references/gd-agentic-game-loop-time-trial.md) |
| Wave spawning and round scaling | [wave loop](references/gd-agentic-game-loop-waves.md) |
| Slots, stacking, and drag/drop | [inventory system](references/gd-agentic-inventory-system.md) |
| Mortality, corpse runs, and revival | [revival mechanic](references/gd-agentic-mechanic-revival.md) |
| Secret inputs and discovery state | [secrets mechanic](references/gd-agentic-mechanic-secrets.md) |
| Quest graphs and prerequisites | [quest system](references/gd-agentic-quest-system.md) |
| Attributes, modifiers, and formulas | [RPG stats](references/gd-agentic-rpg-stats.md) |
| Persistence and serialization | [save/load systems](references/gd-agentic-save-load-systems.md) |
| Hierarchical and pushdown states | [advanced state machines](references/gd-agentic-state-machine-advanced.md) |
| Turn order, ATB, and timelines | [turn system](references/gd-agentic-turn-system.md) |

## Script prototypes

After selecting a reference, inspect only its matching `scripts/<gd-agentic-capability>/` directory when a code prototype is useful. These upstream scripts are preserved for adaptation, not pre-approved for direct execution or bulk copying. Network-authority, multiplayer, native, or incompatible persistence examples remain reference-only in the default Builda Web target.

## Apply

1. Identify the authoritative gameplay state and the smallest requested loop.
2. Read only the references that own that state.
3. Keep persistence, Resources, project files, and architecture governed by canonical Builda owners.
4. Reject multiplayer/server authority assumptions in the default Web target.
5. Verify deterministic rules, visible feedback, persistence boundaries when relevant, and the real Web runtime.
