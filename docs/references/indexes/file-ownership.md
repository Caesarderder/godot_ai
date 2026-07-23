---
km_id: reference.file-ownership
km_type: reference
domain: code
status: draft
owner: architecture
last_verified: 2026-07-21
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/game
  - project-a/tests
validated_by:
  - rg --files project-a/game project-a/tests project-a/tools
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
tags:
  - reference:file-ownership
  - risk:planned-not-implemented
related:
  - reference.architecture-overview
  - reference.implementation-status
  - decision.project-a-game-root
  - decision.taptap-maker-game-root
  - decision.godot-game-root-restored
  - map.domains
---

# 文件归属索引

> `project-a/` 是当前 Godot 实现根；`taptap/` 是暂停原型。下表区分已存在路径、规划落点和受保护边界。

## 目标

给实现者提供单一 planned ownership，避免领域、UI、测试和持久化互相越界。

## 事实

| 路径 | Owner | 用途 | 当前证据 |
|---|---|---|---|
| `project-a/project.godot` | platform | Godot 工程配置、插件、Autoload、主场景 | present / current root |
| `project-a/game/scripts/autoloads/**` | platform | 组合根、生命周期、存档与全局服务 | present/planned；按 M1 证据确认 |
| `project-a/game/scripts/state/**`、`commands/**`、`persistence/**` | domain-kernel | GameState、命令边界、receipt 与持久化 | present/planned；按 M1 证据确认 |
| `project-a/game/scripts/domain/heroes/**`、`formation/**` | hero-formation | 随机英雄、成长与四槽编队 | present/planned；按 M2 证据确认 |
| `project-a/game/scripts/domain/battle/**` | battle-progression | 稳定 seed、BattleSession 与确定性模拟 | present/planned；按 M3 证据确认 |
| `project-a/game/scripts/domain/loot/**`、`progression/**` | equipment-economy | 装备实例、词条、强化与经济 | planned / PRD §10 |
| `project-a/game/scripts/domain/quests/**`、`camp/**` | camp-quests | QuestReducer、软任务与三设施营地 | planned / PRD §10 |
| `project-a/game/resources/**`、`scenes/**`、`scripts/ui/**`、`scripts/presentation/**` | content/presentation | 只读内容、场景、UI 投影与表现 | present/planned；按 milestone 确认 |
| `project-a/tests/**`、`project-a/tools/**` | independent-verifier | GUT、golden、内容校验、模拟和里程碑验证器 | present / evolving |
| `taptap/**` | paused-prototype | Maker 路线占位与历史参考 | paused / non-gating；当前不得假定具体源码存在 |
| `project-a/addons/godot_ai/**` | tooling | 既存智能体 EditorPlugin、runtime helper | present / protected |

## 入口或路径

实现前使用 [KM:workflow.code-locating](../../workflows/code-locating.md)，不得凭本表声称路径存在。

## 验证

每个 milestone 用 `rg --files project-a/game project-a/tests project-a/tools`、Godot headless/GUT 和对应 verifier 确认；路径存在不等于退出门禁已通过。M0 回归使用 `project-a/tools/verify_m0.sh`，TapTap Maker 结果不用于关闭 Godot milestone。

## 相关节点

[KM:reference.implementation-status](../constraints/implementation-status.md)。
