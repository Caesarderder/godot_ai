---
km_id: reference.file-ownership
km_type: reference
domain: code
status: draft
owner: architecture
last_verified: 2026-07-20
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
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
  - map.domains
---

# 文件归属索引

> `taptap/` 是当前 Maker 实现根；`project-a/` 保留为 Godot 历史 M0。下表继续区分已验证入口与未来落点。

## 目标

给实现者提供单一 planned ownership，避免领域、UI、测试和持久化互相越界。

## 事实

| 路径 | Owner | 用途 | 当前证据 |
|---|---|---|---|
| `taptap/scripts/main.lua` | platform | Maker 生命周期、Update 主循环 | present / remote build |
| `taptap/scripts/config/GameConfig.lua` | content | 当前角色、关卡、经济与素材配置 | present / remote build |
| `taptap/scripts/game/GameState.lua` | domain-kernel | 当前战斗、成长、存档和离线结算 | present / remote build |
| `taptap/scripts/game/BattleView2D.lua` | presentation | 纯 2D 战斗表现与动画 | present / remote build |
| `taptap/scripts/ui/GameUI.lua` | presentation | 手机 HUD、培养和锻造 UI | present / remote build |
| `taptap/assets/**` | content | 字体、角色、敌人、背景、视频素材 | present / Maker-managed assets |
| `taptap/scripts/domain/recruitment/**` | hero-formation | 随机英雄生成 | absent / PRD §10 |
| `taptap/scripts/domain/formation/**` | hero-formation | 四槽编队 | absent / PRD §10 |
| `taptap/scripts/domain/equipment/**` | equipment-economy | 装备实例、词条和强化 | absent / PRD §10 |
| `taptap/scripts/domain/quests/**`、`camp/**` | camp-quests | 任务软引导和三设施薄营地 | absent / PRD §10 |
| `taptap/tests/**`、`tools/**` | independent-verifier | 内容、seed、经济和长期模拟 | absent / Test Spec §3 |
| `project-a/project.godot`、`game/**`、`tests/**` | historical-baseline | Godot 4.7 M0、Safe Area、Autoload、GUT | present / historical M0 verifier |
| `project-a/addons/godot_ai/**` | tooling | 既存智能体 EditorPlugin、runtime helper | present / protected |

## 入口或路径

实现前使用 [KM:workflow.code-locating](../../workflows/code-locating.md)，不得凭本表声称路径存在。

## 验证

每个 milestone 用 `rg --files taptap/scripts taptap/assets` 和 Maker MCP 状态/构建确认；领域路径存在后将相关条目从 `absent` 改为实际入口。Godot 历史回归仍使用 `project-a/tools/verify_m0.sh`。

## 相关节点

[KM:reference.implementation-status](../constraints/implementation-status.md)。
