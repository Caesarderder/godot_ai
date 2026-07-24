---
km_id: workflow.code-writing-review
km_type: workflow
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-23
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
validated_by:
  - ralplan-consensus
tags:
  - workflow:code-writing-review
  - quality:independent-verification
related:
  - workflow.impact-map
  - reference.verification-matrix
  - invariant.project-boundaries
---

# 代码编写与审查工作流

## 目标

<<<<<<< HEAD
按 vertical slice 落地 Godot Web-first 3D 游戏，并让写入者、审查者和验证者职责分离。
=======
按 vertical slice 在 `project-a/` 落地 Godot 4.7.1 手机 2D 游戏，并让写入者、审查者和验证者职责分离。
>>>>>>> origin/codex/toilet-man-3d-idle

## 输入

批准的 milestone、impact map、相关领域节点和测试规格。

## 步骤

1. 开工前完成 [KM:workflow.impact-map](impact-map.md)。
<<<<<<< HEAD
2. 只修改批准 owner 的 `project-a/**` 与后续验证目录；`taptap/**` 历史原型除专门迁移任务外只读。
3. 静态配置、运行状态、UI 投影和 command executor 保持分层。
4. 先写或冻结行为测试，再实现最小 vertical slice。
5. 实施者先运行 Godot headless tests、Compatibility import 和 Web release export，但不得自批。
6. 独立审查者检查不变量、状态所有权、随机确定性、3D 投影边界和 Web 生命周期。
=======
2. 只修改批准 owner 的 `project-a/game/**`、`project-a/tests/**`、`project-a/tools/**` 与必要工程配置；默认不得修改 `project-a/addons/godot_ai/**`、第三方 addon 或 `taptap/**` 参考原型。
3. 静态配置、运行状态、UI 投影和 command executor 保持分层。
4. 先写或冻结行为测试，再实现最小 vertical slice。
5. 实施者先运行 GDScript 检查、GUT 与相关 headless 验证；提交前保留原始输出，但不得自批。
6. 独立审查者检查不变量、状态所有权、随机确定性和移动生命周期。
>>>>>>> origin/codex/toilet-man-3d-idle
7. 独立验证者按 [KM:reference.verification-matrix](../references/indexes/verification-matrix.md) 留原始证据。
8. 实际路径稳定后执行 `caesar-docs:update`，将相应 `draft` 节点转为 `active`。

## 停止条件

当前 milestone 的产品、自动测试、设备和 scope evidence 全部达到退出门槛；失败时 milestone 保持 active。

## 验证

[CMD:game-verification](../runbooks/game-verification.md#game-verification)；文档同步后运行 [CMD:docs-lint](../runbooks/docs-lint.md#docs-lint)。

## 相关节点

[KM:decision.durable-domain-kernel](../decisions/ADR-0002-durable-domain-kernel.md)。
