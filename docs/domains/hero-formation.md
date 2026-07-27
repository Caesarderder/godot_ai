---
km_id: domain.hero-formation
km_type: domain
domain: hero-formation
status: active
owner: gameplay
last_verified: 2026-07-26
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
validated_by:
  - user-confirmed-redesign-session-2026-07-26
tags:
  - domain:hero-formation
  - decision:p0-system
related:
  - domain.factory-cultivation
  - domain.product
  - domain.battle-progression
  - reference.first-30m-contract
---

# 永久角色与编队领域

## 目标

让玩家永久收集和培养具有明确战斗职责与工厂专长的马桶人，并使用最多六人的 `2×3` 编队攻城。

## 职责

- 每名角色拥有稳定 `hero_id`、等级、经验、星级、技能、被动和工厂专长；
- 军团图鉴覆盖 Gman 与八种可研发马桶人，统一显示 B/A/S 评级及未获图纸、待研发、已入列状态；
- 信号招募只授予设计图纸；重复图纸转军团数据，研究所完成对应图纸后才创建该原型的唯一永久角色；
- 等级升级原子地更新等级、经验与基础属性，并产生可预览的正向 `ΔCP`；星级解锁机制节点；
- 角色不会永久删除；战斗结束后永久角色恢复为 100% 可出征；
- 编队允许 1–6 名永久角色，前后排各三格，不生成隐藏单位；
- 首次高墙反攻编队可以暂时聚焦三个前排槽，并按缺失职责推荐装甲、冲锋；推荐不得锁死其他
  候选，实际上阵仍必须经过 `assign_formation_slot` 命令。两名援军到位后可直接导航到 1-4，
  UI 不得通过打开军团页本身伪造编队进度；
- 首次 Boss 前成长使用冲锋/装甲二选一专注态；两者必须同时显示战术差异、真实
  `CombatPower` 前后值和同源成本，并通过 `upgrade_hero_star` 提交，不能用页面私有战力公式
  或视觉推荐替玩家完成选择；
- 军团成员培养必须在操作附近投影相关资源的“当前 / 需要 → 操作后剩余”或明确缺口：等级升级
  显示该角色战斗经验阈值与金币，升星只显示军团数据，技能研究显示金币、军团数据与研究所等级门槛；
  三条角色成长都不得消耗工业材料；
- 首次有效升星后立即给出所选路线、统一战力对比、巨炮技能时机与 1-5 验证入口；不得恢复到
  无焦点的完整成员列表，使玩家失去“选择 → 验证”的因果链；
- 角色战斗数值的唯一权威字段为生命 `hp`、攻击 `attack`、防御 `defense`、速度
  `speed_milli`、暴击 `crit_bp`；战前快照只投影这五项、等级、星级和技能偏好，不再保留体魄、
  力量、敏捷、智力或物理/术能双攻击；
- 角色派驻与主线出战兼容，但同一角色只能强化一座设施；
- 当前旧英雄字段可作为迁移输入，库存单位实例不得继续拥有运行时权威。

## 不是本层职责

不持有钱包、设施产出、战斗实时 HP、存档写入或 UI 页面状态。

## 不变量

升级、升星、编队和派驻必须 exact-once；schema v9 及更旧存档只允许一次性把旧四维换算为未乘
星级的五项属性，重载 v10 不得再次换算。角色不可永久死亡；UI 必须使用 `CombatPower` 预览升级
前后差值和星级节点，使用领域 quote/cost 投影资源需要与缺口；普通升星、福利免军团数据升星和执行
结果必须共享 `star_upgrade_quote`，不得在页面层重算成本。兼容战备字段不得
进入当前战力、建议或资源消耗。

## 验证

覆盖永久身份、升级后的属性与 `ΔCP`、三星节点、技能解锁、派驻唯一、六槽编队、无损结算、存档往返和迁移。
