---
km_id: quality.stale-docs
km_type: quality
domain: quality
status: active
owner: maintainers
last_verified: 2026-07-27
source_of_truth:
  - docs/references/constraints/implementation-status.md
validated_by:
  - manual-repository-scan-2026-07-26
tags:
  - quality:stale-docs
  - risk:planned-not-implemented
related:
  - reference.implementation-status
  - workflow.knowledge-map-maintenance
---

# 过期与待回填文档

## 当前清单

2026-07-27 永久军团合同统一后，以下内容属于迁移期旧事实：

- `project-a/` schema v6 的型号科技、库存单位、永久死亡、图纸研发、双货币、一键补位与无尽前线；
- [KM:reference.architecture-overview](../references/architecture/architecture-overview.md) 和
  [KM:reference.state-command-lifecycle](../references/architecture/state-command-lifecycle.md) 中的 v6 业务字段；
- [KM:reference.earth-skibidi-act1-campaign](../references/product-design/earth-skibidi-act1-campaign.md)
  的单位制造、掉落和经济段落；五章、敌人和 Boss 骨架可复用；
- [KM:reference.earth-war-character-roster](../references/product-design/earth-war-character-roster.md)
  的型号/库存语义；角色职责和美术名册可复用；
- 已删除或停止执行的消耗单位、持久伤损、抽图与废料恢复断言；旧 schema 迁移仍保留自动验证。

## 新合同待实现或待外部验证

- 主 GDD、`GC-001/003/006`、产品边界和首 30 分钟合同已经统一为永久援军路线；量产兵、图纸抽取、
  三前排库存兵不再是待实现项；
- 完整 25 关从新档按真实奖励与成本推进的经济可达性；
- 当前 5×5 有界设施选址已经进入合同；道路、工人、人口和复杂物流仍在范围外；
- 首 30 分钟真人理解、Android Chrome、iOS Safari 和生产来源持久化证据。

## 回填节奏

按照 [KM:reference.toilet-factory-refactor-plan](../references/plans/toilet-factory-refactor-plan.md)
阶段 0–6 更新。只有真实代码与对应测试存在时，才能从清单移除。

## 验证

每次运行 [CMD:docs-lint](../runbooks/docs-lint.md#docs-lint)，并对照
[KM:reference.verification-matrix](../references/indexes/verification-matrix.md) 审计实现证据。
