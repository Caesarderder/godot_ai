---
km_id: domain.equipment-economy
km_type: domain
domain: equipment-economy
status: active
owner: gameplay
last_verified: 2026-07-17
source_of_truth:
  - .omx/specs/deep-interview-fantasy-idle-expedition.md
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - ralplan-consensus
tags:
  - domain:equipment-economy
  - decision:p1-system
related:
  - domain.product
  - domain.hero-formation
  - reference.first-30m-contract
---

# 装备与经济领域

## 目标

用可理解的装备跃迁放大英雄构筑，并让 30 分钟资源收支支持两次有意义的成长决策。

## 什么时候读

设计掉落、装备实例、词条、品质、强化、背包、资源 source/sink 或 pity 时。

## 职责

- 静态装备模板与运行实例分离；实例保存品质、随机词条、强化等级和稳定 ID。
- 武器/防具/饰品，白/绿/蓝/紫，+0..+5；强化无失败、无降级。
- 首局保证至少一次玩家能理解的蓝色以上跃迁。
- 金币、招募券、经验书、锻造石是首版全部经济资源，无付费货币。
- 第 8 个合格掉落前无蓝色以上时触发 pity；1-3 首胜也提供职业可用蓝色候选，二者取较早。

## 不是本层职责

不定义关卡 unlock、任务条件或英雄成长公式。

## 不变量

装备不能取代英雄差异；强化不能因失败损失；掉落与强化结果必须可持久重放且不重复。

## 入口

[KM:reference.first-30m-contract](../references/constraints/first-30m-contract.md)。

## 验证

first-30m ledger、pity golden、强化 source/sink、重复结算/杀进程矩阵。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。
