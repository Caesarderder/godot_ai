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
  - rg --files project-a/game project-a/tests project-a/tools
  - GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
tags:
  - reference:file-ownership
  - risk:planned-not-implemented
related:
  - reference.architecture-overview
  - reference.implementation-status
  - decision.project-a-game-root
  - map.domains
---

# 文件归属索引

> `project-a/` 工程根、M0 shell/test/tool 和 godot_ai addon 已存在；下表继续区分已验证入口与 M1-M5 未来落点。

## 目标

给实现者提供单一 planned ownership，避免领域、UI、测试和持久化互相越界。

## 事实

| 规划路径 | Owner | 用途 | 当前证据 |
|---|---|---|---|
| `project-a/project.godot` | platform | Godot 4.7 Mobile、portrait、主场景、plugin/autoload | present / M0 verifier |
| `project-a/export_presets.cfg` | platform | Android 导出配置 | absent / PRD §10 |
| `project-a/addons/godot_ai/**` | tooling | 既存智能体 EditorPlugin、runtime helper | present / protected |
| `project-a/addons/gut/**` | verification | GUT v9.7.1 完整 vendor 与 MIT LICENSE | present / 259 files / manifest locked |
| `project-a/game/resources/definitions/**` | content | 只读职业/技能/装备/任务/设施定义 | absent / PRD §10 |
| `project-a/game/scenes/app/main.tscn` | presentation | M0 portrait shell 与 Safe Area 容器 | present / headless load |
| `project-a/game/scenes/**`（其余） | presentation | Camp、Roster、Formation、Battle、Results | absent / PRD §10 |
| `project-a/game/scripts/autoloads/**` | platform | SystemClock/SaveManager/ContentCatalog/EventBus/Game/AppLifecycle 薄契约 | present / integration test |
| `project-a/game/scripts/app/**` | platform | M0 PlatformMetrics/SafeAreaContainer；ScreenRouter 待实现 | partial / unit test |
| `project-a/game/scripts/ports/**` | platform | Clock、AppLifecycle ports | absent / PRD §10 |
| `project-a/game/scripts/commands/**`、`state/**` | domain-kernel | command、receipt、GameState | absent / PRD §10 |
| `project-a/game/scripts/domain/recruitment/**` | hero-formation | 随机英雄生成 | absent / PRD §10 |
| `project-a/game/scripts/domain/formation/**` | hero-formation | 四槽编队 | absent / PRD §10 |
| `project-a/game/scripts/domain/battle/**` | battle-progression | 5Hz 战斗与结算 | absent / PRD §10 |
| `project-a/game/scripts/domain/loot/**`、`progression/**` | equipment-economy | 掉落、装备、强化、成长 | absent / PRD §10 |
| `project-a/game/scripts/domain/quests/**` | camp-quests | DomainEvent/QuestReducer | absent / PRD §10 |
| `project-a/game/scripts/domain/idle/**`、`persistence/**` | platform-persistence | 离线与存档 | absent / PRD §10 |
| `project-a/game/scripts/ui/**` | presentation | controller/presenter；只投影状态 | absent / PRD §10 |
| `project-a/tests/unit/platform/**`、`integration/**` | independent-verifier | M0 Safe Area 与 bootstrap contract | present / GUT 10/10 |
| `project-a/tests/fixtures/**` | independent-verifier | M1-M5 fixtures | absent / Test Spec §3 |
| `project-a/tools/capture_worktree_baseline.sh` | verification | NUL-safe dirty worktree/addon baseline | present / executed |
| `project-a/tools/verify_m0.sh` | verification | editor/game/compatibility/GUT gate | present / executed |
| `project-a/tools/**`（其余） | verification | 内容、经济与长期模拟工具 | absent / PRD §10 |
| `project-a/build/**` | generated | APK、PCK、logs；不作事实源 | absent / generated |

## 入口或路径

实现前使用 [KM:workflow.code-locating](../../workflows/code-locating.md)，不得凭本表声称路径存在。

## 验证

每个 milestone 用 `rg --files project-a/game project-a/tests project-a/tools`、`project-a/project.godot`、配置和测试确认；存在后将相关条目从 `absent` 改为实际入口，并更新 `last_verified/validated_by`。

## 相关节点

[KM:reference.implementation-status](../constraints/implementation-status.md)。
