---
km_id: reference.file-ownership
km_type: reference
domain: code
status: draft
owner: architecture
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - plan-review-only
tags:
  - reference:file-ownership
  - risk:planned-not-implemented
related:
  - reference.architecture-overview
  - reference.implementation-status
  - map.domains
---

# 文件归属索引

> 下表是批准的未来落点，`game/` 尚不存在。每一项都必须在实现后用真实路径和测试回填。

## 目标

给实现者提供单一 planned ownership，避免领域、UI、测试和持久化互相越界。

## 事实

| 规划路径 | Owner | 用途 | 当前证据 |
|---|---|---|---|
| `game/project.godot`、`game/export_presets.cfg` | platform | Godot/Android 配置 | absent / PRD §10 |
| `game/resources/definitions/**` | content | 只读职业/技能/装备/任务/设施定义 | absent / PRD §10 |
| `game/scenes/**` | presentation | Main、Camp、Roster、Formation、Battle、Results | absent / PRD §10 |
| `game/scripts/autoloads/**` | platform | Game/EventBus/SaveManager/ContentCatalog | absent / PRD §10 |
| `game/scripts/ports/**`、`game/scripts/app/**` | platform | Clock、AppLifecycle、ScreenRouter | absent / PRD §10 |
| `game/scripts/commands/**`、`state/**` | domain-kernel | command、receipt、GameState | absent / PRD §10 |
| `game/scripts/domain/recruitment/**` | hero-formation | 随机英雄生成 | absent / PRD §10 |
| `game/scripts/domain/formation/**` | hero-formation | 四槽编队 | absent / PRD §10 |
| `game/scripts/domain/battle/**` | battle-progression | 5Hz 战斗与结算 | absent / PRD §10 |
| `game/scripts/domain/loot/**`、`progression/**` | equipment-economy | 掉落、装备、强化、成长 | absent / PRD §10 |
| `game/scripts/domain/quests/**` | camp-quests | DomainEvent/QuestReducer | absent / PRD §10 |
| `game/scripts/domain/idle/**`、`persistence/**` | platform-persistence | 离线与存档 | absent / PRD §10 |
| `game/scripts/ui/**` | presentation | controller/presenter；只投影状态 | absent / PRD §10 |
| `game/tests/**` | independent-verifier | unit/integration/fixtures | absent / Test Spec §3 |
| `game/tools/**` | verification | 内容、经济、headless 和 baseline 工具 | absent / PRD §10 |
| `project-a/**` | user-owned unrelated | 既存 Godot AI 插件 | present / protected |

## 入口或路径

实现前使用 [KM:workflow.code-locating](../../workflows/code-locating.md)，不得凭本表声称路径存在。

## 验证

每个 milestone 用 `rg --files game`、配置和测试确认；存在后将相关条目从 `absent` 改为实际入口，并更新 `last_verified/validated_by`。

## 相关节点

[KM:reference.implementation-status](../constraints/implementation-status.md)。
