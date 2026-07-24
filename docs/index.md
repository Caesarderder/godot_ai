---
km_id: map.public-index
km_type: map
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-23
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
validated_by:
  - python3 tools/docs_lint.py
tags:
  - workflow:knowledge-query
  - quality:docs-routing
related:
  - map.control-index
  - map.schema
  - map.workflows
---

# 项目知识地图

这是人和智能体共用的中文工作环境。当前开发目标与实现核心是 `project-a/` Godot 4.7.1 工程；该工程已有通过验证的 M0 shell，随机英雄、四槽编队、随机装备与任务营地继续按后续里程碑在此落地。`taptap/` 的 Maker 2D 原型完整保留，作为已验证的玩法、数值和表现参考，不再是默认开发根。

## 先读顺序

1. [KM:map.control-index](map/index.md)：控制入口与阅读路线。
2. [KM:map.schema](map/schema.md)：节点结构、状态和事实优先级。
3. [KM:map.workflows](map/workflows.md)：按任务选择工作流。
4. [KM:invariant.project-boundaries](map/invariants.md)：不可静默改变的产品与技术边界。
5. 再按任务进入领域、架构或实现索引。

## 目录分区

| 目录 | 职责 |
|---|---|
| `docs/map/` | 控制入口、schema、领域、工作流、不变量、术语 |
| `docs/domains/` | 产品和系统职责边界 |
| `docs/workflows/` | 查询、定位、开发审查、影响分析、地图维护 |
| `docs/references/` | 架构、约束、文件归属、验证矩阵 |
| `docs/decisions/` | 长期决策与 ADR |
| `docs/runbooks/` | 可重复执行的命令和失败处理 |
| `docs/quality/` | lint 与过期事实清单 |
| `docs/memory/` | 已验证、可复用的反馈；不存聊天记录 |

## 事实优先级

1. 当前代码、配置、测试和脚本。
2. 文件归属、区域地图和实现索引。
3. 架构参考与约束。
4. 工作流、runbook 和质量规则。
5. ADR 与 memory。
6. 叙述性说明和规划草稿。

当前 Godot 工程事实以 [CODE:godot-project](../project-a/project.godot)、`project-a/game/**`、`project-a/tests/**` 和 [CODE:m0-verifier](../project-a/tools/verify_m0.sh) 为准。TapTap 参考原型仍以 [CODE:taptap-entry](../taptap/scripts/main.lua)、[CODE:taptap-state](../taptap/scripts/game/GameState.lua) 和 [CODE:taptap-ui](../taptap/scripts/ui/GameUI.lua) 为事实源；未落地的 Godot 玩法继续以 [CODE:approved-prd](../.omx/plans/prd-fantasy-idle-expedition.md) 和 [CODE:test-spec](../.omx/plans/test-spec-fantasy-idle-expedition.md) 为主要证据。
