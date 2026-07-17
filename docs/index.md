---
km_id: map.public-index
km_type: map
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-17
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

这是人和智能体共用的中文工作环境。当前项目处于“规划已批准、M0 工程基座已落地、M1-M5 玩法待实现”阶段；产品约束、工程根、手机竖屏 shell 与测试门禁是已确认事实，未来玩法实现位置仍标记为 `draft`。

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

M0 的配置、Autoload、主场景、安全区和测试以 [CODE:project-config](../project-a/project.godot)、[CODE:main-scene](../project-a/game/scenes/app/main.tscn) 与 [CODE:m0-verifier](../project-a/tools/verify_m0.sh) 为事实源；M1-M5 规划仍以 [CODE:approved-prd](../.omx/plans/prd-fantasy-idle-expedition.md) 和 [CODE:test-spec](../.omx/plans/test-spec-fantasy-idle-expedition.md) 为主要证据。
