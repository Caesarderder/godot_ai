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

让玩家只管理四种可消费核心资源，并让每种资源对应一个清晰决策域：战斗供养角色成长，工厂供养
设施扩张，里程碑提供信号招募机会。

## 职责

- 金币：来自主动战斗与任务，用于角色等级和技能研究；
- 军团数据：来自战果、里程碑和重复图纸，用于升星和技能研究；
- 工业材料：由三类工业产线汇入同一库存，只用于设施建造和升级；
- 招募券：来自周常、成就和里程碑，一券一抽，只用于信号招募；
- 金币用于角色等级与技能研究，经验绑定实际出战角色；角色等级必须同时满足经验阈值；
- 军团数据统一替代专属数据、通用碎片和技能芯片，避免同一角色成长出现三套余额；
- 重复战斗不直接掉落工业材料；初始库存和一次性后勤箱仅是启动例外；
- 基础维修不用金币，防止战败经济死锁；
- 所有价值变化使用整数、稳定 reason code、request ID、business key 和 receipt；
- `recruit_ticket` 是游戏内获得的一券一抽凭证；信号招募只产 B/A/S 设计图纸，重复图纸转军团数据，
  不直接产永久英雄、工业材料或消耗兵；研究所完成图纸研发后才创建唯一永久角色；
- 指挥官经验不可消费，战功只推进当前免费战令，二者都不进入工厂与维修交易；
- 旧马桶钻、研究所抽卡与量产循环退出新经济；真实付费仍不在确认范围。
- 使用单一工业材料分钟、TFA、资源压力与成本/`ΔCP` 比较升级；金币、军团数据、工业材料和招募券
  之间不建立常驻兑换；
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
