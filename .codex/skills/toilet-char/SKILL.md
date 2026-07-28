---
name: toilet-char
description: Create, optimize, review, balance, or implement toilet-game characters and faction rosters against this repository's current Godot architecture, combat code, technology tree, progression, recruitment, stages, and production status. Use for player-faction heroes, technology-tree additions, Alliance or defending enemy units, character tables, star upgrades, skills, stats, acquisition, narrative, audiovisual briefs, stage placement, implementation plans, or character-related code and data changes.
---

# Toilet Char

Treat every character as a roster decision, a content-teaching hook, and an implementation contract. Never design
from remembered roster, stage, or balance values.

## Establish current facts

1. Read `docs/index.md`, `docs/game-contract.md`, and `.codex/skills/toilet-character-production/SKILL.md`
   completely.
2. Follow the canonical producer's required route. Run its snapshot before proposing values:

   ```bash
   python3 .codex/skills/toilet-character-production/scripts/character_design.py snapshot \
     --project-root project-a
   ```

3. Inspect the authoritative code and data named by the snapshot and integration map. Distinguish `implemented`,
   `derived`, `target`, `playtest hypothesis`, and `unknown`.
4. Inspect the current production and stage status. Do not treat a plan, lore document, or old test as implemented
   fact.

## Maintain character knowledge

Treat the character roster as a knowledge-map surface, not a disposable answer.

1. Keep the roster index at `docs/references/characters/index.md`.
2. Keep exactly one Markdown profile per stable player or Alliance character archetype under:
   - `docs/references/characters/player/`
   - `docs/references/characters/alliance/`
3. Index every profile from the roster index and route that index from `docs/index.md`.
4. When creating, optimizing, balancing, implementing, renaming, or removing a character, update its profile and
   roster-index row in the same change. Create the profile before calling the character production-ready.
5. Use the knowledge-map frontmatter schema. Name the implementation sources, evidence state, stage placement,
   counters or peer alternatives, audiovisual/readability contract, integration points, tests, risks, and unknowns.
6. Use one profile per stable archetype, not per spawned instance, lane copy, star level, skin, or temporary summon.
   Document structures and stage-wide modules separately from characters.
7. Mark implemented behavior, target design, and lore inspiration separately. If catalog identity is lost or merged
   at runtime, record that mismatch rather than attributing behavior to the wrong unit.
8. Run `python3 tools/docs_lint.py` after every profile or index change.

## Choose the operation

- **Create player character**: find one real roster or encounter gap, place the character in an existing or
  justified new technology-tree branch, and define acquisition before the first teaching encounter.
- **Create Alliance/defender**: identify the player behavior it tests, its readable tell and counter-window, the
  existing roster answers, stage introduction, later combinations, and Boss remix. Do not use the player-character
  star template when the runtime models this unit as an enemy archetype.
- **Optimize existing character**: diagnose the exact problem—unclear verb, overlap, weak 1★, compulsory role,
  star-upgrade quality, protocol interaction, stage timing, feedback, or implementation mismatch—then make the
  smallest coherent change.
- **Review/audit**: return evidence, gaps, contradictions, and a prioritized revision table. Stop before editing.
- **Implement**: after the design contract is accepted or already explicit, modify authoritative data and runtime
  paths, update projections and docs, and run deterministic and Web-facing validation.

If the user's faction choice is open, compare player-side and Alliance-side opportunities against current gaps and
recommend one. Do not silently design both full characters.

## Design a player-faction character

Use the canonical template:
`.codex/skills/toilet-character-production/assets/character-spec.template.json`.

Define:

- one observable player promise in the form “when signal X appears, use verb Y to create reversal Z”;
- nearest two roster alternatives and a meaningful tradeoff;
- faction, technology-tree branch, rating, stable ID, role, target rules, formation interaction, and protocol
  interaction;
- complete 1★ value, a 2★ qualitative expansion, and a memorable 3★ payoff;
- base stats, repository-formula CP, active-skill scaling, limits, immunity rules, and failure cases;
- deterministic acquisition, blueprint/fragments/research costs, duplicate value, UI copy, and unlock timing;
- four placements: safe introduction, combination test, optional spotlight, and Boss soft-counter with an existing
  fallback;
- silhouette, animation/VFX/SFX cues, fiction, enemy reaction, and factory/research origin.

Validate the completed JSON:

```bash
python3 .codex/skills/toilet-character-production/scripts/character_design.py validate \
  --project-root project-a --spec <character-spec.json>
```

Never require a random pull for critical-path completion. Do not make 1★ intentionally incomplete or make 2★/3★
only percentage increases.

## Design an Alliance or defending enemy

Produce an enemy unit sheet containing:

- combat question and the player habit being challenged;
- faction/family, stable ID, rank, stage band, spawn budget, target priority, movement, range, cadence, durability,
  damage/control, immunities, and deterministic behavior;
- anticipation tell, action, impact, recovery window, interrupt/counter rules, and audiovisual readability;
- primary counters, at least one accessible fallback, bad matchup, formation pressure, and prohibited combinations;
- introduction, isolated practice, mixed-wave test, elite remix, and Boss interaction;
- reward or progression relationship without adding an unjustified currency;
- exact domain, catalog, battle-session, presentation, localization, test, and documentation touchpoints.

An enemy must add a new decision or timing/space problem. Reject a unit that differs only by health, damage, speed,
or model scale.

## Return a production-ready character table

Lead with the recommendation and evidence level, then provide:

1. current roster/stage/architecture gap;
2. role choice and player-facing promise;
3. full character or enemy production table;
4. technology-tree/faction/progression placement;
5. skill or behavior timeline and star transformations where applicable;
6. peer/counter comparison and CP or encounter budget;
7. stage teaching ladder and fallback paths;
8. narrative and audiovisual brief;
9. exact files and systems to change;
10. deterministic tests, seed scans, 844×390 Web/UI checks, and playtest questions;
11. risks, rollback thresholds, unknowns, and the smallest next decision.

For optimization, add a before/after table and migration impact. For implementation, report changed files and actual
validation results. Never claim “balanced,” “fun,” or “perfect fit” beyond the evidence obtained.
