---
km_id: map.public-index
km_type: map
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-24
source_of_truth:
  - project-a/project.godot
  - project-a/export_presets.cfg
  - project-a/scripts/main.gd
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
---

# 项目知识地图

这是人和智能体共用的中文工作环境。当前开发根是 `project-a/` Godot 4.6.3 3D 工程，目标为 Web-first 并主要在手机浏览器运行。当前已具备 Compatibility App Shell、v2 Meta 领域内核、单线程 Web release 导出，以及营地→工厂→培育→六人编队→三阶段 3D 攻城→结算的可玩切片；PWA、浏览器生命周期、离线结算、装备、任务与 Android/iOS 真机证据仍按后续里程碑推进。`taptap/` 仅作为历史可玩原型和产品参考。

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

当前代码事实以 [CODE:project-config](../project-a/project.godot)、[CODE:web-export-preset](../project-a/export_presets.cfg)、[CODE:main-scene](../project-a/scenes/screens/main.tscn)、[CODE:app-shell](../project-a/scripts/main.gd)、[CODE:factory-catalog](../project-a/game/scripts/domain/factory/factory_catalog.gd)、[CODE:factory-service](../project-a/game/scripts/domain/factory/factory_service.gd)、[CODE:battle-session](../project-a/game/scripts/domain/battle/battle_session.gd)、[CODE:meta-tests](../project-a/tools/run_meta_tests.gd)、[CODE:battle-tests](../project-a/tools/run_battle_tests.gd) 和 [CODE:lifecycle-tests](../project-a/tools/run_lifecycle_tests.gd) 为准；它们与实际导出、浏览器证据共同证明 Godot 4.6.3 Compatibility App Shell、单线程 Web release 构建、工厂生产、3 合 1 培育、六人编队和三阶段 5Hz 3D 攻城已存在，但不证明 PWA、Android/iOS 真机或完整长期 GDD 已完成。目标架构见 [KM:reference.architecture-overview](references/architecture/architecture-overview.md)，未落地玩法继续以 [CODE:approved-prd](../.omx/plans/prd-fantasy-idle-expedition.md)、[CODE:test-spec](../.omx/plans/test-spec-fantasy-idle-expedition.md) 和 [KM:reference.skibidi-toilet-idle-siege-gdd](references/product-design/skibidi-toilet-idle-siege-gdd.md) 为主要证据。

策划案中的核心循环、内容、经济与验收指标继续有效；其中旧的 Godot 4.7.1、2D、Mobile renderer、Android-first 平台文字已由 [KM:decision.project-a-web-3d-root](decisions/ADR-0005-project-a-web-3d-root.md) 取代。遇到冲突时，平台和工程根读 ADR-0005，玩法与数值读 PRD/Test Spec。
