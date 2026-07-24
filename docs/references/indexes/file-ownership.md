---
km_id: reference.file-ownership
km_type: reference
domain: code
status: draft
owner: architecture
last_verified: 2026-07-24
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/scenes/screens/main.tscn
  - project-a/game/scripts/state/game_state.gd
  - project-a/game/scripts/commands/command_executor.gd
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/presentation_3d/battle_world.gd
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_battle_tests.gd
validated_by:
  - rg --files project-a
  - godot-4.6.3-headless-smoke
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_battle_tests.gd
tags:
  - reference:file-ownership
  - risk:planned-not-implemented
related:
  - reference.architecture-overview
  - reference.implementation-status
  - decision.project-a-web-3d-root
  - map.domains
---

# 文件归属索引

> `project-a/` 是当前 Godot Web-first 3D 实现根。v2 Meta、工厂、培育、六人编队和三阶段战斗内核已落到 `game/scripts/**`，其余不存在路径仍是 planned ownership。

## 目标

给实现者提供单一 planned ownership，避免领域、UI、测试和持久化互相越界。

## 事实

| 路径 | Owner | 用途 | 当前证据 |
|---|---|---|---|
| `project-a/project.godot` | platform | 引擎、启动场景、renderer、viewport | present / Compatibility |
| `project-a/scenes/screens/main.tscn` | presentation | App Shell 组合根：WorldHost + CanvasLayer | present / headless smoke |
| `project-a/scripts/main.gd` | application-shell | 标题、营地、工厂、培育、六人编队、出征、战斗 HUD、结算生命周期 | present / 1920×1080 + 844×390 capture |
| `project-a/export_presets.cfg` | release | 单线程 Web release 导出配置；PWA 尚未配置 | implemented / M0 baseline |
| `project-a/game/resources/definitions/**` | content | 只读职业、技能、装备、关卡等 `.tres` | absent / PRD §10 |
| `project-a/game/scripts/state/**` | domain-kernel | 可序列化 GameState、英雄、六槽编队、经济与工厂状态 | present / Meta headless tests |
| `project-a/game/scripts/commands/**` | application | CommandExecutor、fingerprint、幂等、revision 与事务编排 | present / Meta headless tests |
| `project-a/game/scripts/domain/recruitment/**` | domain-kernel | 固定 seed 英雄生成 | present / Meta headless tests |
| `project-a/game/scripts/domain/progression/**` | domain-kernel | L1-L5 培养与派生属性 | present / Meta headless tests |
| `project-a/game/scripts/domain/factory/**` | domain-kernel | 三材料八配方、生产队列、领取生成英雄、同原型同星 3 合 1 | present / Meta headless tests |
| `project-a/game/scripts/domain/formation/**` | domain-kernel | 固定六槽 2×3 编队校验 | present / Meta headless tests |
| `project-a/game/scripts/domain/battle/**` | domain-kernel | 5Hz 三阶段攻城、六人推进、技能、核心巨炮与胜负 | present / battle headless tests |
| `project-a/game/scripts/domain/{equipment,quests,idle}/**` | domain-kernel | 装备、任务、离线规则 | absent / M3-M4 |
| `project-a/game/scripts/persistence/**` | persistence | 严格 JSON schema、candidate writer、主档/备份恢复 | present / Meta headless tests |
| `project-a/game/scripts/autoloads/{game,save_manager}.gd` | application | 启动加载、新档持久化与公开执行入口 | present / bootstrap tests |
| `project-a/game/scripts/platform/web/**` | platform | visibility、持久性探测、音频解锁、Web bridge | absent / M0-M1 |
| `project-a/game/scripts/presentation_3d/**` | presentation | 程序化马桶人、结构目标和战斗 snapshot/event 的 3D 投影 | present / runtime smoke + capture |
| `project-a/game/scripts/ui/**` | presentation | 可复用独立 UI 场景/组件 | absent；当前 v2 UI 在 App Shell |
| `project-a/game/scenes/**` | presentation | app、battle_3d、screens、dialogs、ui | absent / M0-M4 |
| `project-a/tools/run_meta_tests.gd` | independent-verifier | Meta、命令、存档和 bootstrap headless tests | present / passing |
| `project-a/tools/run_battle_tests.gd` | independent-verifier | 六人三阶段攻城、技能、核心炮、结构事件、确定性、超时与 result-once | present / passing |
| `project-a/tools/capture_*.gd` | visual-verifier | 标题与战斗画面的确定性截图入口 | present / desktop GL Compatibility |
| `project-a/tests/**`、其余 `project-a/tools/**` | independent-verifier | GUT、内容校验、seed、经济、Web smoke | absent / Test Spec §3 |
| `taptap/**` | historical-reference | 旧 UrhoX Lua 2D 可玩原型 | present / 非当前交付 |

## 入口或路径

实现前使用 [KM:workflow.code-locating](../../workflows/code-locating.md)，不得凭本表声称路径存在。

## 验证

每个 milestone 用 `rg --files project-a`、Godot headless tests、Web release export 和浏览器 smoke 确认；路径存在并经实际验证后，才把 `absent` 改为真实入口。

## 相关节点

[KM:reference.implementation-status](../constraints/implementation-status.md)。
