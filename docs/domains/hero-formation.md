---
km_id: domain.hero-formation
km_type: domain
domain: hero-formation
status: active
owner: gameplay
last_verified: 2026-07-17
source_of_truth:
  - .omx/specs/deep-interview-fantasy-idle-expedition.md
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - ralplan-consensus
tags:
  - domain:hero-formation
  - decision:p0-system
related:
  - domain.product
  - domain.battle-progression
  - reference.first-30m-contract
---

# 英雄与编队领域

## 目标

让玩家看懂随机英雄差异，通过培养、换人和换位形成自己的队伍故事。

## 什么时候读

设计英雄实例、职业/资质/特质、成长、筛选、队伍槽位或战斗派生时。

## 职责

- 英雄是唯一运行实例；静态职业模板只定义基础属性、定位、技能池和成长。
- 实例至少含稳定 ID、姓名、职业、等级、经验、资质、特质/性格、技能和装备引用。
- 首版四项属性 VIG/STR/AGI/INT，等级 L1-L5，累计 XP 在 320 clamp。
- 四槽固定为 2 前排 + 2 后排；位置必须影响受击、目标或技能修正。
- 前 30 分钟至少促成两次无强制提示的主动换人/换位。

## 不是本层职责

不持有任务奖励、全局经济、存档写入或 UI 页面状态。

## 不变量

默认 UI/排序/AI/掉落/任务/胜负不得依赖 `debug_power`；英雄差异不能压缩成单一综合评分。

## 入口

当前实现落点仍是 [KM:reference.file-ownership](../references/indexes/file-ownership.md) 中的 `draft` 规划。

## 验证

成长 golden、8 英雄固定 seed、无效编队引用处理、真人可读性观察。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。
