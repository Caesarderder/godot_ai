---
km_id: reference.first-30m-contract
km_type: reference
domain: product
status: active
owner: product-design
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
  - .omx/plans/test-spec-fantasy-idle-expedition.md
validated_by:
  - ralplan-consensus
tags:
  - reference:first-30m-contract
  - quality:acceptance-gate
related:
  - domain.product
  - domain.hero-formation
  - domain.equipment-economy
  - reference.verification-matrix
---

# 首个 30 分钟验收合同

## 目标

固定首个可玩切片的内容、经济与体验证据，避免“系统都做了但没有成长爽感”。

## 事实

### 玩家旅程

- 0-3 分钟：4 个初始英雄，查看职业/资质/特质。
- 3-7 分钟：两次招募，第一次主动换人/换位。
- 7-12 分钟：达到 8 人；1-3 首败后训练/调队并通过。
- 12-18 分钟：获得保底稀有装备，理解词条并强化。
- 18-23 分钟：1-4 第二次主动编队调整。
- 23-28 分钟：看到三设施并升级一次，理解营地只是效率辅助。
- 28-30 分钟：1-5 Boss 首败后组合培养/装备/编队获胜。

### 资源总量

30 分钟规划总来源：金币 1930、券 4、书 11、石 9；推荐消耗金币 960-1080、券 4、书 6-9、石 3-6。具体 fixture 是规划路径，尚未创建。

### 战斗分布

同一预注册 1000-seed manifest：1-1 95-100%；1-2 80-95%；1-3 before 15-30% 且单一编队干预 +30pp；1-4 before 35-50%/after 75-90%；1-5 before 10-25% 且单一稀有装备干预 +30pp。

### 真人门槛

P01-P05 五人预注册；10 个 checkpoint 中关键项各至少 4/5，总计至少 45/50。测试后不得换 seed 粉饰结果。

## 入口或路径

[CODE:approved-prd](../../../.omx/plans/prd-fantasy-idle-expedition.md)、[CODE:test-spec](../../../.omx/plans/test-spec-fantasy-idle-expedition.md)。

## 验证

最终证据必须绑定同一 build/content/fixture/manifest hash。

## 相关节点

[KM:reference.verification-matrix](../indexes/verification-matrix.md)。
