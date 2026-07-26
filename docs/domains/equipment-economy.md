---
km_id: domain.equipment-economy
km_type: domain
domain: equipment-economy
status: active
owner: gameplay
last_verified: 2026-07-26
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/references/constraints/product-boundaries.md
validated_by:
  - user-confirmed-redesign-session-2026-07-26
  - manual-economy-contract-review
tags:
  - domain:equipment-economy
  - decision:p0-system
related:
  - domain.product
  - domain.hero-formation
  - domain.factory-cultivation
  - reference.first-30m-contract
  - reference.game-state-measurement-framework
  - reference.meta-progression-system
---

# 工业与成长经济领域

## 目标

让工厂资源、战争战果和突破资源形成双向但不自我增殖的经济：工厂供养军团，军团战果扩建工厂。

## 职责

- 工业资源：陶瓷、机械零件、污水能源，用于角色升级、维修、技能研究和设施扩建；
- 战争资源：金币、角色经验、工业技术、技能芯片/联盟残骸，来自城镇和任务；
- 突破资源：角色碎片、Boss 核心、章节许可证，来自首通、Boss 和里程碑；
- 金币用于角色等级和设施升级，经验绑定实际出战角色；
- 工业技术控制设施行为和等级上限；
- 基础维修不用金币，防止战败经济死锁；
- 所有价值变化使用整数、稳定 reason code、request ID、business key 和 receipt；
- `recruit_ticket` 是游戏内获得的一券一抽凭证；概率招募只产永久英雄或英雄数据，不产材料和消耗兵；
- 指挥官经验不可消费，战功只推进当前免费战令，二者都不进入工厂与维修交易；
- 旧马桶钻与图纸研发退出新经济；真实付费仍不在确认范围。
- 使用 FM、TFA、FL、资源压力向量与局部影子价格比较资源，不维护会掩盖门禁的全局固定汇率；
- 工厂直接金币产速恒为零，金币能力按工厂可支持出征数、胜率和战役周期间接估算；
- 商业商品按节省后勤时间、提前成长事件和推进影响拆解，不能只比较原始资源数量。

## 不是本层职责

不定义关卡敌人、战斗伤害、设施 UI 或最终商业策略。

## 不变量

同一种资源不能在同一循环中稳定投入少、产出多；工厂最低产能永久可用；重复请求不得重复扣款、
发放或维修；首轮数值必须标记为待平衡。

## 验证

覆盖资源来源/消耗对账、余额不足、离线产出、经验归属、升级与维修事务、失败死锁恢复和存档中断。

## 入口

[KM:reference.game-state-measurement-framework](../references/product-design/game-state-measurement-framework.md)。
[KM:reference.meta-progression-system](../references/product-design/meta-progression-system.md)。
