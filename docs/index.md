---
km_id: map.public-index
km_type: map
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-26
source_of_truth:
  - project-a/project.godot
  - project-a/export_presets.cfg
  - project-a/scripts/slg_main.gd
  - project-a/game/scripts/state/game_state.gd
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_battle_tests.gd
  - project-a/tools/run_lifecycle_tests.gd
validated_by:
  - python3 tools/docs_lint.py
tags:
  - workflow:knowledge-query
  - quality:docs-routing
related:
  - map.control-index
  - map.schema
  - map.workflows
  - map.skills
---

# 项目知识地图

这是人和智能体共用的中文工作环境。当前开发根是 `project-a/` Godot 4.6.3 3D 工程，目标为 Web-first 并主要在手机浏览器运行。产品合同与玩家入口已经切换为“永久角色 + 工厂后勤资源 + 城镇主动攻坚 + 战后完全无损”；兼容 schema 中仍保留战备、维修和旧训练字段，但它们不是当前玩家循环的数值依据，已实现范围以 implementation-status 为准。

项目级接受状态与跨岗位交接以 [项目契约](game-contract.md) 为唯一入口；本轮重构的程序边界见 [KM:reference.toilet-factory-technical-design](references/architecture/toilet-factory-technical-design.md)，执行顺序见 [KM:reference.toilet-factory-refactor-plan](references/plans/toilet-factory-refactor-plan.md)。
Godot 场景、脚本、Resource、Autoload 与资产治理的增量重构路线见
[KM:reference.godot-runtime-refactor-blueprint](references/architecture/godot-runtime-refactor-blueprint.md)。

涉及战力、资源价值、可推进关卡、工厂产能、永久成长效率、数值膨胀或商业化价值比较时，先读
[KM:reference.game-state-measurement-framework](references/product-design/game-state-measurement-framework.md)。
涉及任务、指挥官等级、战令、招募、成就及奖励预算时，读
[KM:reference.meta-progression-system](references/product-design/meta-progression-system.md)。
涉及首章完成后的免费十连、专属角色碎片、星级质变、阵营形成与第二章 30–60 分钟旅程时，读
[KM:reference.post-30m-faction-progression](references/product-design/post-30m-faction-progression.md)，
实现边界见
[KM:reference.post-30m-faction-technical-design](references/architecture/post-30m-faction-technical-design.md)。
涉及大中小目标、大小卡点、失败恢复和跨坎奖励时，读
[KM:reference.objective-hurdle-reward-ladder](references/product-design/objective-hurdle-reward-ladder.md)。
涉及同类产品、首局结构、渐进披露、产品承诺一致性或上线体验基准时，读
[KM:reference.competitor-first-session-benchmark](references/product-design/competitor-first-session-benchmark.md)。

## 先读顺序

1. [KM:map.control-index](map/index.md)：控制入口与阅读路线。
2. [KM:map.schema](map/schema.md)：节点结构、状态和事实优先级。
3. [KM:map.workflows](map/workflows.md)：按任务选择工作流。
4. [KM:map.skills](map/skills.md)：为任务选择一个主 Skill 和最少辅助 Skill。
5. [KM:invariant.project-boundaries](map/invariants.md)：不可静默改变的产品与技术边界。
6. 再按任务进入领域、架构或实现索引。

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

产品目标以 [KM:reference.skibidi-toilet-idle-siege-gdd](references/product-design/skibidi-toilet-idle-siege-gdd.md) 和 [KM:reference.product-boundaries](references/constraints/product-boundaries.md) 为准。当前代码事实以 [KM:reference.implementation-status](references/constraints/implementation-status.md)、代码、配置与测试为准；旧测试通过不证明新玩法已经实现。

平台和工程根读 ADR-0005；玩法、经济与验收读新 GDD、产品边界和首 30 分钟合同。旧 PRD/Test Spec 只保留实现追溯价值。
