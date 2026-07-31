---
km_id: reference.caesar-loop-run-ui-ux-gauntlet-20260731
km_type: reference
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-31
source_of_truth:
  - docs/workbench/loop-data/ui_ux_gauntlet_20260731
validated_by:
  - command:python3 .codex/skills/caesar-awesome/scripts/validate_loop_protocol.py --run-dir docs/workbench/loop-data/ui_ux_gauntlet_20260731
  - command:python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py loop-sync --run-dir docs/workbench/loop-data/ui_ux_gauntlet_20260731
tags:
  - workflow:agent-loop
  - quality:evidence-gate
related:
  - map.caesar-loop-runs
  - workflow.caesar-loop
  - workflow.workbench-hq
---

# Caesar Loop Run：ui_ux_gauntlet_20260731

本节点由 `loop-sync` 从运行 JSON 与 ledger 生成，记录当前 `integrating` 状态。原始
`RunSpec`、`Progress`、`EvidenceRecord`、`Finding` 与 `IterationResult` 是事实源；
不要手工修改本页来关闭质量门。评审应先进入子任务绑定的 Test Scenario，再检查当前
revision 的证据。全部运行见 [KM:map.caesar-loop-runs](index.md)。

```loop #ui_ux_gauntlet_20260731
title: Continuously improve the real mobile UI/UX from user feedback, beginning with war-zone exploration desire while preserving the accepted title and factory-world direction.
state: integrating
phase: integrating
iteration: 16/8
revision: caa9def
active_unit: —
run_dir: docs/workbench/loop-data/ui_ux_gauntlet_20260731
run_spec: docs/workbench/loop-data/ui_ux_gauntlet_20260731/run-spec.json
progress: docs/workbench/loop-data/ui_ux_gauntlet_20260731/progress.json
knowledge_node: docs/workbench/loops/ui-ux-gauntlet-20260731.md
updated_at: 2026-07-31T15:54:40Z
terminal: no
## Player Outcome
- target: first-time mobile landscape light-SLG player familiar with anime city-war imagery
- platform: Godot 4.6.3 Web, 844x390 and 568x320 landscape
- outcome: understands territorial progression and wants to reveal the next occupied location without searching through UI panels
## Test Scenarios
- [ready] scenario_war_zone_exploration :: Does the map communicate territorial progress, current opportunity and an intriguing hostile frontier before its detail panel? :: fast=godot --path project-a -s tools/capture_war_zone_exploration.gd :: strict=godot --headless --path project-a -s tools/run_war_zone_screen_tests.gd
- [ready] scenario_ui_path_integration :: Does the accepted map remain coherent with the simplified title and world-first factory without breaking navigation? :: fast=godot --path project-a -s tools/capture_ui_review.gd :: strict=godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
- [ready] scenario_factory_world_hud :: Does the factory world remain dominant while action, facility and construction controls appear only when needed? :: fast=godot --path project-a -s tools/capture_factory_hud_scenario.gd :: strict=godot --headless --path project-a -s tools/run_factory_screen_tests.gd && godot --path project-a -s tools/capture_factory_hud_scenario.gd
- [ready] scenario_legion_formation_identity :: Can the player identify deployed toilet characters, the recommended open position and the next formation action without reading a table? :: fast=godot --path project-a -s tools/capture_legion_formation_scenario.gd :: strict=godot --headless --path project-a -s tools/run_legion_screen_tests.gd && godot --path project-a -s tools/capture_legion_formation_scenario.gd
- [ready] scenario_codex_gallery_identity :: Can the player distinguish collected, blueprint-ready and unknown toilet characters and choose one to inspect without reading a card table? :: fast=godot --path project-a -s tools/capture_codex_gallery_scenario.gd :: strict=godot --headless --path project-a -s tools/run_legion_screen_tests.gd && godot --path project-a -s tools/capture_codex_gallery_scenario.gd
- [ready] scenario_faction_core_choice_identity :: Can the player compare two real toilet-character candidates by playstyle and deliberately choose a long-term faction core? :: fast=godot --path project-a -s tools/capture_faction_core_choice_scenario.gd :: strict=godot --headless --path project-a -s tools/run_legion_screen_tests.gd && godot --path project-a -s tools/capture_faction_core_choice_scenario.gd
- [ready] scenario_blueprint_character_forge :: Can the player see which permanent toilet character a blueprint creates, understand its current research state, and take the one correct next action? :: fast=godot --path project-a -s tools/capture_blueprint_forge_scenario.gd :: strict=godot --headless --path project-a -s tools/run_blueprint_screen_tests.gd && godot --path project-a -s tools/capture_blueprint_forge_scenario.gd
- [ready] scenario_mobile_objective_action_compass :: Can the player identify the one action that advances the campaign now, its obstacle, and the immediate reward without reading a dashboard? :: fast=godot --path project-a -s tools/capture_action_compass_scenario.gd :: strict=godot --headless --path project-a -s tools/run_goals_screen_tests.gd && godot --path project-a -s tools/capture_action_compass_scenario.gd
- [ready] scenario_mobile_achievement_medal_cabinet :: Can the player see which permanent honors are earned, which can be claimed now, and inspect progress without reading a card dashboard? :: fast=godot --path project-a -s tools/capture_achievement_medal_cabinet_scenario.gd :: strict=godot --headless --path project-a -s tools/run_goals_screen_tests.gd && godot --path project-a -s tools/capture_achievement_medal_cabinet_scenario.gd
- [ready] scenario_mobile_first_growth_duel :: Can the player compare two character-led combat identities, understand availability, and commit one route without reading dense stat cards? :: fast=godot --path project-a -s tools/capture_first_growth_duel_scenario.gd :: strict=godot --headless --path project-a -s tools/run_first_growth_flow_tests.gd && godot --path project-a -s tools/capture_first_growth_duel_scenario.gd
- [ready] scenario_mobile_faction_doctrine_command_deck :: Can the player compare army-wide coordination against faction specialization as two visual command doctrines and understand the permanent consequence without reading dense cards? :: fast=godot --path project-a -s tools/capture_faction_doctrine_deck_scenario.gd :: strict=godot --headless --path project-a -s tools/run_blueprint_screen_tests.gd && godot --path project-a -s tools/capture_faction_doctrine_deck_scenario.gd
- [ready] scenario_mobile_breakthrough_hero_reveal :: Does the ten-pull breakthrough feel like two permanent toilet heroes joining the resistance, with materials reading as secondary loot instead of ten equal text boxes? :: fast=godot --path project-a -s tools/capture_breakthrough_hero_reveal_scenario.gd :: strict=godot --headless --path project-a -s tools/run_blueprint_screen_tests.gd && godot --path project-a -s tools/capture_breakthrough_hero_reveal_scenario.gd
- [ready] scenario_mobile_battle_pass_supply_runway :: Can the player drag along one supply line, instantly distinguish claimed, claimable and future tiers, and collect the current rewards without reading a four-column inventory grid? :: fast=godot --path project-a -s tools/capture_battle_pass_runway_scenario.gd :: strict=godot --headless --path project-a -s tools/run_goals_screen_tests.gd && godot --path project-a -s tools/capture_battle_pass_runway_scenario.gd
- [ready] scenario_mobile_chapter_victory_tableau :: Does clearing the chapter feel like the resistance heroes broke the wall, with rewards and the sole next action understood at a glance? :: fast=godot --path project-a -s tools/capture_chapter_victory_tableau_scenario.gd :: strict=godot --headless --path project-a -s tools/run_chapter_one_completion_tests.gd && godot --path project-a -s tools/capture_chapter_victory_tableau_scenario.gd
- [ready] scenario_mobile_boss_siege_briefing :: Can the player feel the final fortress ahead, understand readiness and choose prepare or attack without the briefing covering the route? :: fast=godot --path project-a -s tools/capture_boss_siege_briefing_scenario.gd :: strict=godot --headless --path project-a -s tools/run_war_zone_screen_tests.gd && godot --path project-a -s tools/capture_boss_siege_briefing_scenario.gd
- [ready] scenario_high_dpi_web_clarity :: Does the factory world and HUD remain crisp on a Retina/high-DPI browser while touch coordinates and mobile layout stay correct? :: fast=GODOT_WEB_HIDPI_ONLY=1 GODOT_WEB_DEVICE_SCALE_FACTOR=2 node tools/run_web_browser_smoke.mjs :: strict=godot --headless --path project-a -s tools/run_ui_smoke_tests.gd && GODOT_WEB_HIDPI_ONLY=1 GODOT_WEB_DEVICE_SCALE_FACTOR=2 node project-a/tools/run_web_browser_smoke.mjs
## Quality Gates
- [pass] gate_ui_visual :: visual :: The world-first UI has strong character identity, spatial depth and an exploration-led hierarchy at both target viewports. :: evidence=2
- [pass] gate_ui_runtime :: correctness :: Title, factory and war-zone actions use shipping state and navigation without regressions. :: evidence=1
- [pass] gate_ui_responsive :: correctness :: All decisive map targets and primary actions fit and remain operable at 844x390 and 568x320. :: evidence=1
- [pass] gate_factory_visual :: visual :: The factory reads as a 3D underground war base first, with compact contextual HUD states instead of a persistent dashboard. :: evidence=2
- [pass] gate_factory_runtime :: correctness :: Factory HUD controls preserve shipping panel and semantic action signals across mission, facility, build and placement states. :: evidence=1
- [pass] gate_factory_responsive :: correctness :: Factory world targets and contextual controls remain visible and touch-sized at 844x390 and 568x320. :: evidence=1
- [stale] gate_player_learning :: player_learning :: A fresh target player understands territorial progression and wants to inspect the next hostile landmark without coaching. :: evidence=0
- [pass] gate_legion_visual :: visual :: The formation screen reads as a six-character toilet resistance squad rather than a generic roster table. :: evidence=2
- [pass] gate_legion_runtime :: correctness :: Formation selection and deployment preserve shipping tab and action signals across empty, selected and full squad states. :: evidence=1
- [pass] gate_legion_responsive :: correctness :: Formation portraits, six slots and the primary action remain visible and touch-sized at 844x390 and 568x320. :: evidence=1
- [pass] gate_codex_visual :: visual :: The codex reads as a collectible toilet-character gallery rather than a generic card table. :: evidence=2
- [pass] gate_codex_runtime :: correctness :: Codex selection and research routing preserve stable archetype and recipe identities. :: evidence=1
- [pass] gate_codex_responsive :: correctness :: Focused portrait, gallery choices and the primary action remain visible and touch-sized at 844x390 and 568x320. :: evidence=1
- [pass] gate_faction_choice_visual :: visual :: The faction-core choice reads as a consequential duel between two distinct toilet characters rather than two generic signal cards. :: evidence=4
- [pass] gate_faction_choice_runtime :: correctness :: Faction choice and selected-core research handoff preserve stable archetype identities and durable commands. :: evidence=1
- [pass] gate_faction_choice_responsive :: correctness :: Both candidate portraits and choice actions remain visible and touch-sized at 844x390 and 568x320. :: evidence=1
- [pass] gate_blueprint_forge_visual :: visual :: Blueprint research reads as forging a permanent toilet character rather than browsing a generic icon tech tree. :: evidence=2
- [pass] gate_blueprint_forge_runtime :: correctness :: Blueprint selection, start research and claim handoff preserve stable recipe identities and durable commands. :: evidence=1
- [pass] gate_blueprint_forge_responsive :: correctness :: Character art, research state and the sole primary action remain visible and touch-sized at 844x390 and 568x320. :: evidence=1
- [pass] gate_action_compass_visual :: visual :: The action screen reads as a mobile campaign compass rather than a generic task dashboard. :: evidence=2
- [pass] gate_action_compass_runtime :: correctness :: Current action, reward claim and mission lock preserve durable target and reward command identities. :: evidence=1
- [pass] gate_action_compass_responsive :: correctness :: Current target, reward preview and sole primary action remain visible and touch-sized at 844x390 and 568x320. :: evidence=1
- [pass] gate_achievement_cabinet_visual :: visual :: Achievements read as a permanent medal cabinet rather than a scrolling card-management dashboard. :: evidence=2
- [pass] gate_achievement_cabinet_runtime :: correctness :: Batch and individual achievement claims preserve durable achievement identities while locked and settled states expose no fake action. :: evidence=1
- [pass] gate_achievement_cabinet_responsive :: correctness :: Medal identity, state and the sole primary action remain visible and touch-sized at 844x390 and 568x320. :: evidence=1
- [pass] gate_growth_duel_visual :: visual :: The first growth choice reads as a dramatic duel between two character combat identities rather than a stat-card form. :: evidence=2
- [pass] gate_growth_duel_runtime :: correctness :: Growth and boss actions preserve exact hero and stage identities while blocked routes expose no executable star action. :: evidence=1
- [pass] gate_growth_duel_responsive :: correctness :: Both growth identities and their decisive actions remain visible and touch-sized at 844x390 and 568x320. :: evidence=1
- [pass] gate_doctrine_deck_visual :: visual :: Tier-2 doctrine selection reads as a visual command-deck choice rather than a dense settings form. :: evidence=2
- [pass] gate_doctrine_deck_runtime :: correctness :: Doctrine actions preserve exact coordination and specialization identities while activated state exposes no replacement action. :: evidence=1
- [pass] gate_doctrine_deck_responsive :: correctness :: Both doctrine choices and the activated command card remain visible and touch-sized at 844x390 and 568x320. :: evidence=1
- [pass] gate_breakthrough_reveal_visual :: visual :: Research breakthrough reads as two permanent toilet heroes joining the resistance rather than a ten-cell reward spreadsheet. :: evidence=2
- [pass] gate_breakthrough_reveal_runtime :: correctness :: Breakthrough result preserves all reward identities and emits the exact open_legion handoff without exposing a repeat claim. :: evidence=1
- [pass] gate_breakthrough_reveal_responsive :: correctness :: Both permanent heroes, secondary loot and the legion handoff remain visible and touch-sized at 844x390 and 568x320. :: evidence=1
- [pass] gate_pass_runway_visual :: visual :: Battle pass reads as a touch-draggable supply runway with a clear current frontier rather than a four-column inventory dashboard. :: evidence=2
- [pass] gate_pass_runway_runtime :: correctness :: All thirty tier identities and exact individual/batch claim actions remain intact while settled tiers expose no executable claim. :: evidence=1
- [pass] gate_pass_runway_responsive :: correctness :: Current tier, next rewards and sole batch action remain visible and touch-operable at 844x390 and 568x320. :: evidence=1
- [pass] gate_chapter_victory_visual :: visual :: Chapter victory reads as an awesome two-hero resistance climax rather than a generic result dashboard. :: evidence=2
- [pass] gate_chapter_victory_runtime :: correctness :: Fresh and replayed chapter victories preserve exact reward visibility and forward action payloads without reopening spent rewards. :: evidence=1
- [pass] gate_chapter_victory_responsive :: correctness :: Hero tableau, reward icons and sole primary action fit and remain touch-operable at 844x390 and 568x320. :: evidence=1
- [pass] gate_boss_briefing_visual :: visual :: Chapter-boss briefing reads as a fortress siege on an explorable route rather than overlapping map widgets. :: evidence=2
- [pass] gate_boss_briefing_runtime :: correctness :: Underpowered, ready and cleared boss states emit exact preparation, attack and replay actions for stage_1_5. :: evidence=1
- [pass] gate_boss_briefing_responsive :: correctness :: Boss node, readiness HUD and required touch actions fit without overlap at 844x390 and 568x320. :: evidence=1
- [pass] gate_high_dpi_runtime :: correctness :: The shipping Web canvas allocates physical backing pixels for browser devicePixelRatio instead of upscaling an 844x390 bitmap. :: evidence=1
- [pass] gate_high_dpi_responsive :: correctness :: High-DPI rendering preserves the logical mobile layout and exact touch mapping. :: evidence=1
- [pass] gate_high_dpi_visual :: visual :: The factory world, Chinese HUD text and raster icons look materially crisper at DPR 2 without changing the accepted composition. :: evidence=2
## Open Findings
- [clear] 无未关闭 finding
## Evidence
- [pass] ev_ui_codex_integration_responsive_e1da84a :: runtime_state :: gate=gate_ui_responsive :: freshness=stale :: dual-size main-scene capture plus UI smoke geometry assertions
- [pass] ev_ui_codex_integration_runtime_e1da84a :: runtime_state :: gate=gate_ui_runtime :: freshness=stale :: run_ui_smoke_tests.gd and capture_ui_review.gd
- [pass] ev_ui_drag_integration_responsive_874a992 :: test :: gate=gate_ui_responsive :: freshness=stale :: GODOT_WEB_TOUCH_DRAG_ONLY=1 node tools/run_web_browser_smoke.mjs plus dual-size focused captures
- [pass] ev_ui_drag_integration_runtime_874a992 :: test :: gate=gate_ui_runtime :: freshness=stale :: godot --headless --path project-a -s tools/run_ui_smoke_tests.gd; focused goals and mobile-scroll suites
- [pass] ev_ui_faction_integration_responsive_01bc769 :: capture :: gate=gate_ui_responsive :: freshness=stale :: App Shell dual viewport captures plus compact layout and focus assertions
- [pass] ev_ui_faction_integration_runtime_01bc769 :: test :: gate=gate_ui_runtime :: freshness=stale :: run_ui_smoke_tests.gd, run_ui_focus_tests.gd, focused LegionScreen tests and App Shell capture
- [human_required] ev_ui_gauntlet_human_required_16b05bb :: player_observation :: gate=gate_player_learning :: freshness=stale :: Workbench feedback session required
- [pass] ev_ui_gauntlet_responsive_baseline_16b05bb :: capture :: gate=gate_ui_responsive :: freshness=stale :: godot --path project-a -s tools/capture_war_zone_exploration.gd
- [pass] ev_ui_gauntlet_runtime_baseline_16b05bb :: test :: gate=gate_ui_runtime :: freshness=stale :: godot --headless --path project-a -s tools/run_war_zone_screen_tests.gd
- [fail] ev_ui_gauntlet_visual_baseline_16b05bb :: capture :: gate=gate_ui_visual :: freshness=stale :: project-a/artifacts/scenario-war-zone-exploration
- [pass] ev_ui_growth_integration_responsive_7626daf :: capture :: gate=gate_ui_responsive :: freshness=stale :: cd project-a && godot --path . -s tools/capture_first_growth_duel_scenario.gd
- [pass] ev_ui_growth_integration_runtime_7626daf :: test :: gate=gate_ui_runtime :: freshness=stale :: cd project-a && godot --headless --path . -s tools/run_legion_screen_tests.gd && godot --headless --path . -s tools/run_first_growth_flow_tests.gd && godot --headless --path . -s tools/run_ui_smoke_tests.gd && godot --headless --path . -s tools/run_ui_focus_tests.gd
- [pass] ev_ui_hidpi_integration_responsive_caa9def :: test :: gate=gate_ui_responsive :: freshness=current :: GODOT_WEB_TOUCH_DRAG_ONLY=1 node tools/run_web_browser_smoke.mjs; GODOT_WEB_HIDPI_ONLY=1 GODOT_WEB_DEVICE_SCALE_FACTOR=2 node tools/run_web_browser_smoke.mjs
- [pass] ev_ui_hidpi_integration_runtime_caa9def :: test :: gate=gate_ui_runtime :: freshness=current :: godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
- [pass] ev_ui_integration_responsive_eacfb8b :: runtime_state :: gate=gate_ui_responsive :: freshness=stale :: canonical dual-size capture plus UI smoke geometry assertions
- [pass] ev_ui_integration_runtime_eacfb8b :: runtime_state :: gate=gate_ui_runtime :: freshness=stale :: run_ui_smoke_tests.gd and capture_ui_review.gd
- [pass] ev_ui_pass_integration_responsive_b562758 :: test :: gate=gate_ui_responsive :: freshness=stale :: GODOT_WEB_TOUCH_DRAG_ONLY=1 node tools/run_web_browser_smoke.mjs plus dual-size focused captures
- [pass] ev_ui_pass_integration_runtime_b562758 :: test :: gate=gate_ui_runtime :: freshness=stale :: godot --headless --path project-a -s tools/run_ui_smoke_tests.gd; goals and mobile-scroll focused suites
- [pass] ev_ui_touch_integration_responsive_c48c224 :: capture :: gate=gate_ui_responsive :: freshness=stale :: godot --path project-a --script res://tools/capture_faction_doctrine_deck_scenario.gd && godot --headless --path project-a --script res://tools/run_mobile_scroll_input_tests.gd
- [pass] ev_ui_touch_integration_runtime_c48c224 :: test :: gate=gate_ui_runtime :: freshness=stale :: godot --headless --path project-a --script res://tools/run_ui_smoke_tests.gd && godot --headless --path project-a --script res://tools/run_mobile_scroll_input_tests.gd && GODOT_WEB_TOUCH_DRAG_ONLY=1 node project-a/tools/run_web_browser_smoke.mjs
## Host Capabilities
- [supported] fresh_agent_context :: The host exposes isolated child-agent critic threads when required by an active Caesar Loop.
- [unsupported] parallel_agents :: No parallel maker execution is authorized for this work unit.
- [unsupported] isolated_workspaces :: All work uses one dirty shared worktree.
- [supported] runtime_control :: Godot 4.6.3 headless tests and Compatibility renderer executions succeed locally.
- [supported] capture :: Non-headless Godot capture scripts emit repository-local PNG evidence.
- [unknown] profiling :: No target-device profiler has been observed.
- [supported] persistent_run_state :: Managed Caesar JSON ledgers and Workbench projection are writable.
- [unsupported] target_player_access :: No uncoached target player is available to the host.
## Decisions
- 2026-07-31T15:49:53Z :: High-DPI browser scenario now verifies 2x physical backing pixels, stable CSS layout, high-DPI touch mapping and a real overflowing settings drag surface. Affected gates=['gate_high_dpi_responsive', 'gate_high_dpi_runtime', 'gate_high_dpi_visual', 'gate_player_learning', 'gate_ui_responsive', 'gate_ui_runtime']; carried gates=['gate_achievement_cabinet_responsive', 'gate_achievement_cabinet_runtime', 'gate_achievement_cabinet_visual', 'gate_action_compass_responsive', 'gate_action_compass_runtime', 'gate_action_compass_visual', 'gate_blueprint_forge_responsive', 'gate_blueprint_forge_runtime', 'gate_blueprint_forge_visual', 'gate_boss_briefing_responsive', 'gate_boss_briefing_runtime', 'gate_boss_briefing_visual', 'gate_breakthrough_reveal_responsive', 'gate_breakthrough_reveal_runtime', 'gate_breakthrough_reveal_visual', 'gate_chapter_victory_responsive', 'gate_chapter_victory_runtime', 'gate_chapter_victory_visual', 'gate_codex_responsive', 'gate_codex_runtime', 'gate_codex_visual', 'gate_doctrine_deck_responsive', 'gate_doctrine_deck_runtime', 'gate_doctrine_deck_visual', 'gate_faction_choice_responsive', 'gate_faction_choice_runtime', 'gate_faction_choice_visual', 'gate_factory_responsive', 'gate_factory_runtime', 'gate_factory_visual', 'gate_growth_duel_responsive', 'gate_growth_duel_runtime', 'gate_growth_duel_visual', 'gate_legion_responsive', 'gate_legion_runtime', 'gate_legion_visual', 'gate_pass_runway_responsive', 'gate_pass_runway_runtime', 'gate_pass_runway_visual', 'gate_ui_visual'].
- 2026-07-31T15:53:41Z :: Chromium reports an exact 1688x780 backing buffer for an 844x390 CSS canvas at DPR 2.
- 2026-07-31T15:53:41Z :: High-DPI construction touch and real overflowing settings drag both succeed with CSS coordinates.
- 2026-07-31T15:53:42Z :: Runtime capture and independent review confirm materially sharper text, 3D silhouettes and icons at 8.8/10 overall.
- 2026-07-31T15:53:42Z :: High-DPI Web clarity passes physical backing, touch mapping and independent mixed visual gates.
- 2026-07-31T15:53:52Z :: High-DPI clarity unit is closed; refresh shared UI gates with current headless and real-browser interaction evidence.
- 2026-07-31T15:54:31Z :: Shared UI smoke passes after the high-DPI browser scenario update.
- 2026-07-31T15:54:31Z :: Real touch drag and DPR 2 coordinate mapping both pass in the shipping Web route.
summary: scenarios=16 gates=46 evidence=105 current=62 findings=0 iterations=16
```
