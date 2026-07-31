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
iteration: 4/8
revision: e1da84a
active_unit: —
run_dir: docs/workbench/loop-data/ui_ux_gauntlet_20260731
run_spec: docs/workbench/loop-data/ui_ux_gauntlet_20260731/run-spec.json
progress: docs/workbench/loop-data/ui_ux_gauntlet_20260731/progress.json
knowledge_node: docs/workbench/loops/ui-ux-gauntlet-20260731.md
updated_at: 2026-07-31T12:26:30Z
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
- [pending] gate_faction_choice_visual :: visual :: The faction-core choice reads as a consequential duel between two distinct toilet characters rather than two generic signal cards. :: evidence=0
- [pending] gate_faction_choice_runtime :: correctness :: Faction choice and selected-core research handoff preserve stable archetype identities and durable commands. :: evidence=0
- [pending] gate_faction_choice_responsive :: correctness :: Both candidate portraits and choice actions remain visible and touch-sized at 844x390 and 568x320. :: evidence=0
## Open Findings
- [clear] 无未关闭 finding
## Evidence
- [pass] ev_factory_runtime_2e23dd4 :: runtime_state :: gate=gate_factory_runtime :: freshness=current :: run_factory_screen_tests.gd; run_ui_smoke_tests.gd; capture_ui_review.gd
- [pass] ev_factory_visual_critic_2e23dd4 :: model_critique :: gate=gate_factory_visual :: freshness=current :: blind A/B real-screen review by /root/factory_toilet_final_critic
- [pass] ev_factory_visual_runtime_2e23dd4 :: visual_diff :: gate=gate_factory_visual :: freshness=current :: deterministic focused bundle plus canonical real-world captures
- [fail] ev_factory_world_critic_fail_09516dd :: model_critique :: gate=gate_factory_visual :: freshness=stale :: blind review by /root/factory_hud_repair_critic
- [fail] ev_legion_baseline_responsive_2e23dd4 :: runtime_state :: gate=gate_legion_responsive :: freshness=stale :: dual viewport LegionScreen focused bundle
- [pass] ev_legion_baseline_runtime_2e23dd4 :: runtime_state :: gate=gate_legion_runtime :: freshness=stale :: run_legion_screen_tests.gd plus capture_legion_formation_scenario.gd twice
- [fail] ev_legion_baseline_visual_2e23dd4 :: capture :: gate=gate_legion_visual :: freshness=stale :: project-a/artifacts/scenario-legion-formation/baseline bundle
- [pass] ev_legion_responsive_eacfb8b :: runtime_state :: gate=gate_legion_responsive :: freshness=current :: dual viewport focused bundle plus canonical App Shell capture
- [pass] ev_legion_runtime_eacfb8b :: runtime_state :: gate=gate_legion_runtime :: freshness=current :: run_legion_screen_tests.gd and capture_legion_formation_scenario.gd twice
- [pass] ev_legion_visual_critic_eacfb8b :: model_critique :: gate=gate_legion_visual :: freshness=current :: randomized blind A/B review by /root/legion_formation_critic
- [pass] ev_legion_visual_runtime_eacfb8b :: visual_diff :: gate=gate_legion_visual :: freshness=current :: baseline and candidate deterministic dual-size three-state bundles
- [human_required] ev_player_learning_human_required_b13a0a1 :: player_observation :: gate=gate_player_learning :: freshness=stale :: No eligible fresh target-player session was available in this execution environment.
- [pass] ev_ui_codex_integration_responsive_e1da84a :: runtime_state :: gate=gate_ui_responsive :: freshness=current :: dual-size main-scene capture plus UI smoke geometry assertions
- [pass] ev_ui_codex_integration_runtime_e1da84a :: runtime_state :: gate=gate_ui_runtime :: freshness=current :: run_ui_smoke_tests.gd and capture_ui_review.gd
- [human_required] ev_ui_gauntlet_human_required_16b05bb :: player_observation :: gate=gate_player_learning :: freshness=stale :: Workbench feedback session required
- [pass] ev_ui_gauntlet_responsive_baseline_16b05bb :: capture :: gate=gate_ui_responsive :: freshness=stale :: godot --path project-a -s tools/capture_war_zone_exploration.gd
- [pass] ev_ui_gauntlet_runtime_baseline_16b05bb :: test :: gate=gate_ui_runtime :: freshness=stale :: godot --headless --path project-a -s tools/run_war_zone_screen_tests.gd
- [fail] ev_ui_gauntlet_visual_baseline_16b05bb :: capture :: gate=gate_ui_visual :: freshness=stale :: project-a/artifacts/scenario-war-zone-exploration
- [pass] ev_ui_integration_responsive_eacfb8b :: runtime_state :: gate=gate_ui_responsive :: freshness=stale :: canonical dual-size capture plus UI smoke geometry assertions
- [pass] ev_ui_integration_runtime_eacfb8b :: runtime_state :: gate=gate_ui_runtime :: freshness=stale :: run_ui_smoke_tests.gd and capture_ui_review.gd
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
- 2026-07-31T12:19:17Z :: Focused runtime suite and deterministic capture preserve stable codex IDs and actions.
- 2026-07-31T12:19:17Z :: Dual-size focused and integrated captures preserve touch targets and gallery context.
- 2026-07-31T12:21:01Z :: Deterministic comparison and independent blind critic pass the character-gallery claim.
- 2026-07-31T12:21:01Z :: Canonical UI smoke and capture pass after codex shell integration.
- 2026-07-31T12:21:02Z :: Canonical dual-size captures preserve codex and existing navigation geometry.
- 2026-07-31T12:22:08Z :: Focused codex gates and declared integration checkpoint pass with independent visual evidence.
- 2026-07-31T12:22:08Z :: Codex gallery work unit is accepted and integrated.
- 2026-07-31T12:25:03Z :: Add the bounded faction-core character-choice work unit.
summary: scenarios=6 gates=16 evidence=35 current=16 findings=0 iterations=4
```
