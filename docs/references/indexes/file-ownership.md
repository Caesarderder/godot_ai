---
km_id: reference.file-ownership
km_type: reference
domain: code
status: draft
owner: architecture
<<<<<<< HEAD
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
=======
last_verified: 2026-07-23
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/tools/verify_m0.sh
  - taptap/README.md
  - taptap/scripts/main.lua
>>>>>>> origin/codex/toilet-man-3d-idle
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
<<<<<<< HEAD
  - decision.project-a-web-3d-root
=======
  - decision.project-a-game-root
  - decision.taptap-maker-game-root
  - decision.return-to-project-a
>>>>>>> origin/codex/toilet-man-3d-idle
  - map.domains
---

# 文件归属索引

<<<<<<< HEAD
> `project-a/` 是当前 Godot Web-first 3D 实现根。v2 Meta、工厂、培育、六人编队和三阶段战斗内核已落到 `game/scripts/**`，其余不存在路径仍是 planned ownership。
=======
> `project-a/` 是当前 Godot 实现根；`taptap/` 保留为 Maker 参考原型。下表区分 Godot 已验证入口、Godot 未来落点与参考原型。
>>>>>>> origin/codex/toilet-man-3d-idle

## 目标

给实现者提供单一 planned ownership，避免领域、UI、测试和持久化互相越界。

## 事实

| 路径 | Owner | 用途 | 当前证据 |
|---|---|---|---|
<<<<<<< HEAD
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
=======
| `project-a/project.godot` | platform | Godot 4.7.1 Mobile 工程、主场景、Autoload、插件 | present / M0 verifier |
| `project-a/game/scenes/app/main.tscn` | presentation | 当前 Godot M0 主场景与移动 shell | present / M0 verifier |
| `project-a/game/scripts/autoloads/**` | platform | 时钟、存档、内容、事件、游戏启动与移动生命周期 | present / M0 verifier |
| `project-a/game/domain/recruitment/**` | hero-formation | 随机英雄生成 | absent / PRD §10 |
| `project-a/game/domain/formation/**` | hero-formation | 四槽编队 | absent / PRD §10 |
| `project-a/game/domain/equipment/**` | equipment-economy | 装备实例、词条和强化 | absent / PRD §10 |
| `project-a/game/domain/quests/**`、`camp/**` | camp-quests | 任务软引导和三设施薄营地 | absent / PRD §10 |
| `project-a/tests/**`、`project-a/tools/**` | independent-verifier | GUT、内容、seed、经济和长期模拟 | M0 present / M1-M5 planned |
| `project-a/addons/godot_ai/**` | tooling | 既存智能体 EditorPlugin、runtime helper | present / protected |
| `taptap/scripts/**`、`taptap/assets/**` | reference-prototype | 已验证玩法、数值、手机 UI 与 2D 表现参考 | present / remote build / not default |
>>>>>>> origin/codex/toilet-man-3d-idle

## 入口或路径

实现前使用 [KM:workflow.code-locating](../../workflows/code-locating.md)，不得凭本表声称路径存在。

## 验证

<<<<<<< HEAD
每个 milestone 用 `rg --files project-a`、Godot headless tests、Web release export 和浏览器 smoke 确认；路径存在并经实际验证后，才把 `absent` 改为真实入口。
=======
每个 milestone 用 `rg --files project-a/game project-a/tests project-a/tools`、GUT 和 Godot headless/设备验证确认；领域路径存在后将相关条目从 `absent` 改为实际入口。M0 回归使用 `project-a/tools/verify_m0.sh`。只有维护参考原型时才读取 Maker MCP 状态/构建。
>>>>>>> origin/codex/toilet-man-3d-idle

## 相关节点

[KM:reference.implementation-status](../constraints/implementation-status.md)。
