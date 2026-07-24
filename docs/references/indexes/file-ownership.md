---
km_id: reference.file-ownership
km_type: reference
domain: code
status: draft
owner: architecture
last_verified: 2026-07-23
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/tools/verify_m0.sh
  - taptap/README.md
  - taptap/scripts/main.lua
validated_by:
  - rg --files project-a/game project-a/tests project-a/tools
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
  - maker_build_current_directory
tags:
  - reference:file-ownership
  - risk:planned-not-implemented
related:
  - reference.architecture-overview
  - reference.implementation-status
  - decision.project-a-game-root
  - decision.taptap-maker-game-root
  - decision.return-to-project-a
  - map.domains
---

# 文件归属索引

> `project-a/` 是当前 Godot 实现根；`taptap/` 保留为 Maker 参考原型。下表区分 Godot 已验证入口、Godot 未来落点与参考原型。

## 目标

给实现者提供单一 planned ownership，避免领域、UI、测试和持久化互相越界。

## 事实

| 路径 | Owner | 用途 | 当前证据 |
|---|---|---|---|
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

## 入口或路径

实现前使用 [KM:workflow.code-locating](../../workflows/code-locating.md)，不得凭本表声称路径存在。

## 验证

每个 milestone 用 `rg --files project-a/game project-a/tests project-a/tools`、GUT 和 Godot headless/设备验证确认；领域路径存在后将相关条目从 `absent` 改为实际入口。M0 回归使用 `project-a/tools/verify_m0.sh`。只有维护参考原型时才读取 Maker MCP 状态/构建。

## 相关节点

[KM:reference.implementation-status](../constraints/implementation-status.md)。
