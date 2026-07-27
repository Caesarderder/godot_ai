---
name: toilet-character-production
description: Design, review, balance, and production-plan new or existing toilet characters against this repository's current Godot combat, progression, recruitment, technology-tree, narrative, and stage facts. Use when adding a character, expanding a faction or tech branch, reviewing character power or star transformations, planning stages that teach or spotlight a roster role, or converting a character idea into implementation-ready data, content, tests, and rollout gates.
---

# Toilet Character Production

Create a character as a player-facing strategy and a reusable content hook, not as a stat bundle.

## Required route

1. Read `docs/index.md`, `docs/game-contract.md`, and the current code before trusting design prose.
2. Run:

   ```bash
   python3 .codex/skills/toilet-character-production/scripts/character_design.py snapshot \
     --project-root project-a
   ```

3. Read [references/design-contract.md](references/design-contract.md).
4. When planning stages, read [references/content-ladder.md](references/content-ladder.md).
5. For implementation, also read [references/integration-map.md](references/integration-map.md).
6. Copy [assets/character-spec.template.json](assets/character-spec.template.json), complete every field, then run:

   ```bash
   python3 .codex/skills/toilet-character-production/scripts/character_design.py validate \
     --project-root project-a --spec <character-spec.json>
   ```

Do not design from remembered values. Re-run the snapshot after balance, roster, stage, or recruitment changes.

## Workflow

### 1. Find the opportunity

Map the current roster by:

- tactical verb and target type;
- B/A/S rating, class, faction, branch, and acquisition point;
- 1★ complete value, 2★ role expansion, and 3★ qualitative payoff;
- stages where the role is recommended, optional, unavailable, or redundant.

State one roster or encounter gap. Reject ideas whose only gap is “another damage dealer” or a missing CP tier.

### 2. Write the player promise

Use one observable sentence:

> When `<battle signal>` happens, the player uses `<character verb>` to create `<visible reversal>`.

Specify why a player would choose this character over the nearest two alternatives. Include execution difficulty,
reliability, opportunity cost, and feedback—not only damage.

### 3. Budget power

Use the repository `CombatPower` formula and current rarity rules. Treat displayed CP as a base-stat comparison,
not skill value.

- B/A 1★ must be useful immediately and normally sit within the current peer envelope.
- S 1★ must own its complete active skill and be competitive with a B/A 2★ peer.
- 2★ must change target count, timing, safety, positioning, or synergy.
- 3★ must create a memorable payoff, not merely repeat the 2★ effect with a larger number.
- Active-skill level scales execution output separately from star identity.

Label claims `implemented`, `derived`, `target`, `playtest hypothesis`, or `unknown`. Never call a role “perfect”
or “balanced” without representative player evidence.

### 4. Bind the character to content

Define four encounter placements:

1. safe introduction;
2. constrained combination test;
3. optional spotlight where the role is the cleanest answer;
4. Boss soft-counter where at least one existing fallback remains viable.

For each, name entry state, demand, player action, visible response, success signal, failure lesson, fallback, reward,
and next use. Never require a random pull for critical-path completion.

Use the sustainable cadence:

`foreshadow demand → expose weakness → offer/preview role → safe practice → combined test → spotlight → Boss remix`

### 5. Connect fiction and progression

Explain the silhouette, battle sound, enemy reaction, factory/research origin, faction relationship, and why the
Alliance creates the associated countermeasure. Make narrative explain mechanics.

Choose acquisition and duplicate value under the current rules:

- signals grant a design blueprint;
- research creates the permanent character;
- duplicates become that archetype's fragments;
- B/A/S star costs and pity remain canonical;
- industrial material never upgrades character stars.

### 6. Produce an implementation contract

Return:

- concept and player promise;
- nearest-peer comparison;
- complete JSON spec and validator result;
- base stats, CP table, active skill, 2★/3★ changes, skill-level scaling;
- faction, branch, acquisition, fragments, research, and UI copy;
- four-encounter content plan and fallback paths;
- narrative and audiovisual brief;
- exact source files to change;
- deterministic tests, seed scans, Web/UI checks, and player-observation questions;
- risks, rollback thresholds, and unknowns.

If the request is review-only, stop before editing. If implementation is requested, change authoritative data and
runtime paths, not only documentation.

## Gates

Reject or revise a character when:

- the tactical verb duplicates an existing role without a new decision;
- 1★ is intentionally incomplete to force duplicates;
- 2★/3★ are only percentage increases;
- CP hides skill dominance or uselessness;
- the role is mandatory for a critical stage;
- the unlock occurs after its required teaching encounter;
- the stage recommendation names an unavailable blueprint;
- no existing fallback can solve the Boss;
- UI cannot explain role, timing, star change, and source at 844×390;
- deterministic evidence is presented as proof of fun.

Finish with the strongest evidence reached and the smallest unanswered player question.
