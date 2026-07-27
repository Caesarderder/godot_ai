# Character Design Contract

## Evidence hierarchy

1. Runtime code, Resources, current tests, and exported behavior.
2. `docs/game-contract.md` accepted rules.
3. Current design references.
4. Proposed targets and hypotheses.

## Current canonical formulas

Read the files rather than copying their values into a new system:

- CP: `game/scripts/domain/progression/combat_power.gd`
- base stats, classes, rarity generation: `game/scripts/domain/recruitment/hero_generator.gd`
- star and level derivation: `game/scripts/domain/progression/hero_progression.gd`
- roles and recipes: `game/scripts/domain/factory/factory_catalog.gd`
- star identities and factions: `game/scripts/domain/content/faction_catalog.gd`
- active skill runtime: `game/scripts/domain/battle/battle_session.gd`
- skill copy: `game/resources/definitions/skills/active/`
- acquisition and duplicates: `game/scripts/domain/recruitment/signal_recruit_service.gd`
- stage demands and recommendations: `game/scripts/domain/content/stage_catalog.gd`

Displayed power:

```text
CP = hp×3 + attack×20 + defense×10 + speed_milli/500 + crit_bp/10
```

Displayed CP excludes control, healing, summoning, target coverage, execution difficulty, and active-skill level.
Compare those using representative battle windows and role-specific events.

## Character spec requirements

| Surface | Required decision |
|---|---|
| Identity | stable ID, name, branch, class, B/A/S rating, faction |
| Player promise | battle signal, tactical verb, visible reversal |
| Base value | complete 1★ active skill and honest weakness |
| Growth | distinct 2★ expansion and 3★ payoff |
| Economy | acquisition point, research time, duplicate fragment rule |
| Content | safe intro, combination, spotlight, Boss soft-counter |
| Alternatives | at least one currently obtainable fallback |
| Fiction | origin, silhouette, sound, enemy response |
| Evidence | CP derivation, deterministic scenarios, player questions |

## Peer comparison

Compare against the two closest roles across:

| Dimension | Meaning |
|---|---|
| Availability | when and how it enters the account |
| Base CP | canonical 1★/2★/3★ displayed power |
| Effective output | damage, healing, control, summons, coverage |
| Reliability | valid targets, timing, variance, failure modes |
| Safety | range, self-cost, protection, recovery |
| Opportunity | formation slot and skill-energy competition |
| Feedback | whether the player can see why it worked |
| Follow-up | faction and encounter choices it enables |

No option may be no worse in every material dimension and better in another.

## Stage contract

Each authored placement must state:

| Field | Required content |
|---|---|
| Promise | what the player does and feels |
| Entry | owned roles, stars, resources, prior knowledge |
| Demand | enemy, structure, timing, lane, or attrition pattern |
| Decision | meaningful action, not a navigation click |
| Response | visible world and combat feedback |
| Exit | knowledge, reward, unlock, or next goal |
| Recovery | deterministic non-paid route after failure |
| Fallback | existing character/formation that remains viable |

New role content must teach through:

`safe introduction → constrained practice → combined challenge → independent use → recovery`.

## Release evidence

- Catalog and Resource validation.
- Canonical CP and snapshot parity.
- 1★ immediate-value scenario.
- 2★ and 3★ event-level qualitative assertions.
- Nearest-peer and fallback seed scans.
- Stage unlock-before-recommendation check.
- Save roundtrip for blueprint, fragments, hero, and formation.
- 844×390 UI readability and focus.
- Web smoke for the first real acquisition/use path.
- Uncoached player observation before claiming desirability or fun.
