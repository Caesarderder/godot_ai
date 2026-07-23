---
km_id: invariant.project-boundaries
km_type: invariant
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-21
source_of_truth:
  - .omx/specs/deep-interview-fantasy-idle-expedition.md
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - ralplan-consensus
  - manual-plan-review
tags:
  - risk:product-drift
  - risk:state-consistency
related:
  - reference.product-boundaries
  - reference.state-command-lifecycle
---

# 项目不变量

## 产品不变量

- 手机端、单机、休闲放置；玩家通过随机英雄培养和编队跨过卡点。
- P0 是英雄培养与编队，P1 是装备，P2 是薄营地。
- 大小任务只引导与奖励，不作为关卡硬锁。
- 英雄是随机运行实例，不回退为固定角色抽卡。
- 未经用户确认，不改变核心循环、系统主次、随机英雄模型、美术主题、商业化、目标平台或单机边界。

## 技术不变量

- `project-a/` 是当前 Godot 4.7.1 Mobile 2D 实现根；代码与资源进入 `project-a/game/**`，测试进入 `project-a/tests/**`，工具进入 `project-a/tools/**`。
- `project-a/addons/godot_ai/**`、现有 EditorPlugin 和 `_mcp_game_helper` Autoload 属于受保护工具层，默认不得修改、移动、格式化或清理。
- GDScript、Godot Resource/Node/Control、Mobile renderer 和 GUT 是当前技术基线；Compatibility renderer 保留兼容冒烟，触控目标遵守 48dp 与安全区契约。
- 静态定义与运行实例分离；运行状态只保存稳定 ID 和实例字段。
- executor 是 GameState 唯一写入口；价值命令先持久化再报告成功。
- 离线收益只认 `offline_anchor_unix`；战斗只认稳定 seed 和 5Hz tick。
- UI 是状态投影，不直接修改领域状态。
- `taptap/` Maker 原型暂时搁置；不得把其代码、构建或 Maker MCP 结果计入当前 Godot milestone exit。
- 实现事实必须由代码、测试和命令重新验证；计划路径不等于已存在路径。
