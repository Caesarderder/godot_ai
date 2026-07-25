---
km_id: workflow.skill-routing
km_type: workflow
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-25
source_of_truth:
  - .codex/skills
  - docs/map/skills.md
validated_by:
  - manual-skill-catalog-review
  - command:enumerate-project-skills
tags:
  - workflow:skill-routing
  - quality:task-routing
related:
  - map.skills
  - map.workflows
  - workflow.knowledge-query
  - workflow.impact-map
  - invariant.project-boundaries
---

# Skill 路由工作流

## 目标

从当前项目 Skill 目录中选择最小、兼容、可验证的能力组合，并避免 Skill 默认假设覆盖仓库事实。

## 输入

用户目标、涉及的领域/文件、当前实现证据，以及 `.codex/skills/*/SKILL.md`。

## 步骤

1. 非平凡仓库任务先执行 `docs-hunter`，读取公共入口、控制入口、不变量和任务相关最小节点。
2. 在 [KM:map.skills](../map/skills.md) 按任务信号确定一个主 Skill；具体系统 Skill 优先于聚合 Skill。
3. 检查主 Skill 的触发条件。若其要求用户显式调用、依赖未安装插件、不同语言/引擎/渲染器或被项目边界禁止，则不得自动采用。
4. 完整读取主 Skill 的 `SKILL.md` 及其明确要求的最小引用。只有跨域依赖真实存在时才添加辅助 Skill。
5. 用 [KM:workflow.impact-map](impact-map.md) 把 Skill 建议映射到实际读文件、改文件、风险、不变量和验证；Skill 名称本身不是实现证据。
6. 实施前再次核对当前配置、代码、测试和文件归属。冲突时按知识地图事实优先级处理并显式报告。
7. Skill 目录发生变化时更新 [KM:map.skills](../map/skills.md)，再运行知识地图 lint。

## 停止条件

已确定一个兼容的主 Skill、必要的最少辅助 Skill、对应仓库事实链和验证入口；继续读取其他 Skill 不再改变任务边界。

## 验证

- 所选 Skill 的目录和 `SKILL.md` 实际存在。
- 任务输出符合 Skill 的触发/排除条件与项目不变量。
- 涉及地图变更时执行 [CMD:docs-lint](../runbooks/docs-lint.md#docs-lint)。

## 相关节点

[KM:map.skills](../map/skills.md)、[KM:workflow.knowledge-query](knowledge-query.md)、[KM:workflow.knowledge-map-maintenance](knowledge-map-maintenance.md)。

