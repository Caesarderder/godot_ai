# Integration Map

## Minimum runtime touchpoints

| Concern | Source |
|---|---|
| recipe, branch, rating, class, role | `game/scripts/domain/factory/factory_catalog.gd` |
| generated identity and localized name | `game/scripts/domain/recruitment/hero_generator.gd` |
| recruit pool and duplicate fragments | `game/scripts/domain/recruitment/signal_recruit_service.gd` |
| faction and star effects | `game/scripts/domain/content/faction_catalog.gd` |
| skill definition and player copy | `game/resources/definitions/skills/active/<skill>.tres` |
| skill catalog | `game/scripts/content/active_skill_catalog.gd` |
| battle behavior and known-skill gate | `game/scripts/domain/battle/battle_session.gd` |
| model scene and presentation | `game/scenes/actors/ally_models/`, `game/scripts/presentation_3d/` |
| tech-tree projection | `scripts/slg_main.gd`, `game/scripts/ui/blueprint_screen.gd` |
| stage demand, recommendation, unlock | `game/scripts/domain/content/stage_catalog.gd` |

Search for every existing archetype ID before editing. Hard-coded exhaustive arrays are intentional validation
surfaces; update them explicitly rather than weakening exact-count checks.

## Required focused tests

- `tools/run_active_skill_definition_tests.gd`
- `tools/run_balance_tests.gd`
- `tools/run_battle_tests.gd`
- `tools/run_blueprint_screen_tests.gd`
- `tools/run_campaign_tests.gd`
- `tools/run_legion_screen_tests.gd`
- `tools/run_post_30m_faction_tests.gd`
- `tools/run_stage_definition_tests.gd`

Add one character-specific suite that proves 1★ value, 2★/3★ events, fallback viability, deterministic replay,
and save roundtrip. Run the repository's full headless suite and Web gates before release.

## Content rollout

Prefer one vertical slice:

1. make the character obtainable in a controlled fixture;
2. render its complete tech-tree and legion information;
3. exercise its tactical verb in one authored encounter;
4. prove an existing fallback;
5. only then distribute it through the live recruit pool and later chapters.

Do not add it to probability pools before its runtime behavior, duplicate conversion, UI, and save paths exist.
