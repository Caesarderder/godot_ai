# Provenance and admission decisions

Audit date: 2026-07-24.

The included micro-recipes are original Builda examples. No upstream source file, artwork, font,
shader, or plugin code is copied into this skill. They are governed by the Builda repository's own
policy and carry no separate third-party license. External projects were used only to identify useful
boundaries and verification expectations.

| Source | Revision | License observed | Disposition |
| --- | --- | --- | --- |
| [Godot official demos](https://github.com/godotengine/godot-demo-projects) | `cae8dc567a56d3e7936f171bcb85f0ccb9634ad0` (master audit only) | MIT | `REUSE` as API and node-composition evidence; no source copied; latest master is not target-version proof |
| [GDQuest design patterns](https://github.com/gdquest-demos/godot-design-patterns) | `d783a51bb7150e924754dc6078faee9aa3787f88` | MIT code; CC BY-NC-SA art | `REUSE` design reasoning only; exclude art and copied implementation |
| [GodotPrompter](https://github.com/jame581/GodotPrompter) | `7b3b5281738c66fc9191768d504cfe5ff9cce608` (`v1.12.0`) | MIT | `REUSE` existing Builda owners; `EXCLUDE` legacy platform router and duplicate prose |
| [GD-Agentic Skills](https://github.com/thedivergentai/gd-agentic-skills) | `42eea91671adb27b2822be94aa46345517803ffb` | LGPL-3.0 | `REUSE` already-managed category references; `BLOCKED` for any additional direct or derivative copy without a distribution decision |
| [ThemeGen](https://github.com/Inspiaaa/ThemeGen) | `30b94203277cdf8ce76e5deff8cf2bd0979a9e4d` (`v1.4.0`) | MIT | `REUSE` semantic-token idea; no editor plugin dependency or code copied |
| [Godot State Charts](https://github.com/derkork/godot-statecharts) | `76d226a3efac66a72aea825382b320c94808f409` (`v0.22.5`) | MIT | `EXCLUDE` as a default dependency; route complex cases to optional project evaluation |
| [GLoot](https://github.com/peter-kish/gloot) | `ce88b7adc7b952b4df8ebe4836339de334d0d0cc` (`v3.0.2`) | MIT | `REUSE` separation of data, constraints, and UI; no plugin code copied |
| [gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) | `1579130d73f15f628fd0cfdbf7d60bdc39144a26` (`v6.1.3`) | MIT | `REUSE` through `$godot-testing`; no bundled test plugin or release-candidate code |
| [Maaack game template](https://github.com/Maaack/Godot-Game-Template) | `93e66a02b979872b870ccb5ac1452f8d6a31c737` | MIT | `REUSE` product-shell boundaries only; `EXCLUDE` whole-project inheritance |

## GodotPrompter source-file accounting

The Builda transfer audit inspected the complete selected source skill directories. Every source file
is accounted for below.

| Source path | Capability | Core? | Duplicate owner | Disposition | Target | Transformation |
| --- | --- | --- | --- | --- | --- | --- |
| `component-system/SKILL.md` | component composition | yes | `$godot-architecture`, `$combat-system` | `REUSE` | existing owners | no copy |
| `event-bus/SKILL.md` | event boundaries | yes | `$godot-architecture` | `REUSE` | existing owner | no copy |
| `event-bus/references/testing.md` | event testing | no | `$godot-testing` | `REUSE` | existing owner | no copy |
| `scene-organization/SKILL.md` | project and scene structure | yes | `$godot-project-setup`, `$godot-architecture` | `REUSE` | protected owners | no copy |
| `state-machine/SKILL.md` | state lifecycle | no | `$state-machine` | `REUSE` | existing owner | package a new original demo only |
| `state-machine/references/hierarchical-and-parallel.md` | complex states | no | `$state-machine` | `REUSE` | existing owner | no copy |
| `godot-ui/SKILL.md` | Control and Theme guidance | no | `$godot-ui` | `REUSE` | existing owner | package original UI artifacts |
| `godot-ui/references/focus-and-navigation.md` | focus navigation | no | `$godot-ui` | `REUSE` | existing owner | no copy |
| `godot-ui/references/signals.md` | UI signals | no | `$godot-ui` | `REUSE` | existing owner | no copy |
| `godot-ui/references/theme-system.md` | Theme resources | no | `$godot-ui` | `REUSE` | existing owner | package original token fixture |
| `godot-ui/references/ui-patterns.md` | menu patterns | no | `$godot-ui` | `REUSE` | existing owner | no copy |
| `responsive-ui/SKILL.md` | responsive UI | no | `$responsive-ui` | `REUSE` | existing owner | package original shell fixture |
| `responsive-ui/references/adaptive-layouts.md` | adaptive containers | no | `$responsive-ui` | `REUSE` | existing owner | no copy |
| `responsive-ui/references/dpi-scaling.md` | DPI behavior | no | `$responsive-ui` | `REUSE` | existing owner | no copy |
| `responsive-ui/references/mobile.md` | native mobile behavior | no | unsupported default target | `EXCLUDE` | none | native-specific |
| `responsive-ui/references/pixel-art-setup.md` | pixel-art scaling | no | `$responsive-ui` | `REUSE` | existing owner | no copy |
| `godot-testing/SKILL.md` | test workflow | no | `$godot-testing` | `REUSE` | existing owner | no copy |
| `godot-testing/gdunit4-reference.md` | gdUnit4 integration | no | `$godot-testing` | `REUSE` | existing owner | no plugin bundle |
| `godot-testing/gut-reference.md` | GUT integration | no | exact catalog duplicate | `REUSE` | existing owner | no copy |
| `godot-testing/references/running-tests.md` | test commands | no | `$godot-testing` | `REUSE` | existing owner | no copy |
| `godot-testing/references/tdd-workflow.md` | TDD workflow | no | `$godot-testing` | `REUSE` | existing owner | no copy |
| `godot-testing/references/testing-patterns.md` | test patterns | no | `$godot-testing` | `REUSE` | existing owner | no copy |
| `inventory-system/SKILL.md` | inventory boundaries | no | `$inventory-system` | `REUSE` | existing owner | no copy |
| `inventory-system/references/equipment.md` | equipment | no | `$inventory-system` | `REUSE` | existing owner | no copy |
| `inventory-system/references/serialization.md` | inventory persistence | yes | `$inventory-system`, `$save-load` | `REUSE` | existing owners | no copy |
| `inventory-system/references/ui-binding.md` | inventory UI | no | `$inventory-system`, `$godot-ui` | `REUSE` | existing owners | no copy |
| `using-godot-prompter/SKILL.md` | legacy meta-router | no | Builda native skill discovery | `EXCLUDE` | none | platform-specific orchestration removed |
| `using-godot-prompter/references/antigravity-tools.md` | Antigravity mapping | no | unsupported platform | `EXCLUDE` | none | no copy |
| `using-godot-prompter/references/codex-tools.md` | generic Codex mapping | no | native runtime | `EXCLUDE` | none | redundant |
| `using-godot-prompter/references/copilot-tools.md` | Copilot mapping | no | unsupported platform | `EXCLUDE` | none | no copy |
| `using-godot-prompter/references/cursor-tools.md` | Cursor mapping | no | unsupported platform | `EXCLUDE` | none | no copy |
| `using-godot-prompter/references/gemini-tools.md` | Gemini mapping | no | unsupported platform | `EXCLUDE` | none | no copy |

## Created capability

`CREATE godot-template-catalog`: a progressive-disclosure owner for packaging and validating
micro-recipe artifacts. It does not replace any existing technical owner and does not modify protected
core.
