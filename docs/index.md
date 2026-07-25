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
  - map.skills
---

# 项目知识地图

这是人和智能体共用的中文工作环境。当前开发根是 `project-a/` Godot 4.6.3 3D 工程，目标为 Web-first 并主要在手机浏览器运行。当前已具备 Compatibility App Shell、v4 Meta 领域内核、第一幕五章 25 关、任务/成就目标中心、设置/失焦暂停、程序化战争表现、单线程 Web/PWA 导出和本地产物审计；离线战斗、装备、生产 HTTPS 与 Android/iOS 真机证据仍按后续里程碑推进。`taptap/` 仅作为历史可玩原型和产品参考。

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

当前代码事实以 [CODE:project-config](../project-a/project.godot)、[CODE:web-export-preset](../project-a/export_presets.cfg)、[CODE:app-shell](../project-a/scripts/main.gd)、[CODE:stage-catalog](../project-a/game/scripts/domain/content/stage_catalog.gd)、[CODE:battle-session](../project-a/game/scripts/domain/battle/battle_session.gd)、[CODE:battle-world](../project-a/game/scripts/presentation_3d/battle_world.gd)、[CODE:settings-store](../project-a/game/scripts/platform/settings_store.gd)、[CODE:web-runtime](../project-a/game/scripts/platform/web_runtime.gd)、[CODE:achievement-catalog](../project-a/game/scripts/domain/achievement/achievement_catalog.gd) 和 [KM:reference.verification-matrix](references/indexes/verification-matrix.md) 为准；它们与实际导出、审计和浏览器证据共同证明第一幕本地发行候选存在，但不证明生产部署、Android/iOS 真机、IP 授权或完整长期 GDD 已完成。

策划案中的核心循环、内容、经济与验收指标继续有效；其中旧的 Godot 4.7.1、2D、Mobile renderer、Android-first 平台文字已由 [KM:decision.project-a-web-3d-root](decisions/ADR-0005-project-a-web-3d-root.md) 取代。遇到冲突时，平台和工程根读 ADR-0005，玩法与数值读 PRD/Test Spec。
