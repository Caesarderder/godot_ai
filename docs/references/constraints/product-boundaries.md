---
km_id: reference.product-boundaries
km_type: reference
domain: product
status: active
owner: product-design
last_verified: 2026-07-26
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
validated_by:
  - user-confirmed-redesign-session-2026-07-26
  - manual-design-integrity-review
tags:
  - reference:product-boundaries
  - risk:scope-drift
related:
  - domain.product
  - invariant.project-boundaries
  - reference.first-30m-contract
---

# 产品范围与确认边界

## 已确认的当前产品

- Godot 4.6.3、3D、Compatibility、Web-first、手机横屏、单机可玩。
- 玩家永久拥有并培养核心马桶人；等级提供数值成长，星级解锁技能、被动、技能质变和工厂专长。
- 工厂只生产和加工陶瓷、机械零件、污水能源等后勤资源，不生产量产马桶人，不自动首次推图。
- 永久军团主动攻打城镇，获得金币、经验、工业技术和受控突破资源；战果用于升级角色与工厂。
- 战斗内 HP、阵亡与撤退只决定本局结果；结算后永久角色恢复为 100% 可出征，不产生维修订单、
  等待时间或跨局战备损失。
- 主线不使用体力、扫荡券或每日次数。已占领城镇可以提供少量被动税收，但不代替玩家主动攻坚。
- 编队保持最多六人的前后 `2×3`，战斗保持自动移动、索敌与普通攻击，技能自动化由玩家选择。
- 当前新档只拥有 Gman；其他永久角色通过战役 Boss 与后续招募进度解锁。P0 需要证明三星、
  六座设施、三工业资源、四城镇和一个 Boss 的 20–30 分钟闭环。
- 下一阶段已确认加入行动任务、指挥官等级、免费战令、永久成就和游戏内招募券驱动的永久英雄招募。
- Gman 与通关必需职责保持主线确定性获得；招募用于扩展阵容与升星，不替代攻城。

## 可在边界内细化

- 首轮角色数值、设施产速、容量、升级成本和战利品数量；
- 角色技能、星级节点、工厂专长和敌方机制；
- 城镇主题、三段攻城节奏、3D 表现、HUD 和触控布局；
- schema、typed GDScript 数据结构、命令、事件和存档迁移；
- 任务、成就、指挥官等级、免费战令和招募数值，只要不硬锁或替代核心循环。

## 必须再次确认

- 重新加入量产马桶人、自动扫荡、永久角色死亡或仅能抽取的通关必需角色；
- 改成自由建造、复杂物流、多队大地图或传统重度 SLG；
- 增加体力、每日次数、强制广告、PvP、公会或排行榜；
- 恢复马桶钻图纸材料混池、付费战令、真实充值或任何付费战力入口；
- 改变 Web-first 手机横屏、3D 攻城或永久角色养成支柱。

## 当前 P0 不包含

- 生产或消耗库存单位；
- 自动推图、自动扫荡和离线战斗模拟；
- 图纸研发材料混池和双货币商业经济；
- 自由建筑摆放、道路、工人、人口和复杂物流；
- 随机装备词条、套装、转职和多层天赋；
- PvP、公会、联盟战、排行榜和云端社交；
- 真实支付和商业发布。

## 验证

每次里程碑回看：[工厂资源是否支持永久成长]、[城镇战果是否扩建工厂]、
[失败后是否无损且下一行动清楚]、[玩家是否愿意调整成长或编队后再战]。
不能加强这四项的系统应移出 P0。

## 相关节点

[KM:reference.skibidi-toilet-idle-siege-gdd](../product-design/skibidi-toilet-idle-siege-gdd.md)、
[KM:reference.first-30m-contract](first-30m-contract.md)。
