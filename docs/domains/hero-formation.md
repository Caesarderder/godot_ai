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
- 等级升级原子地更新等级、经验与基础属性，并产生可预览的正向 `ΔCP`；星级解锁机制节点；
- 角色不会永久删除；战斗结束后永久角色恢复为 100% 可出征；
- 编队允许 1–6 名永久角色，前后排各三格，不生成隐藏单位；
- 首次高墙反攻编队可以暂时聚焦三个前排槽，并按缺失职责推荐装甲、冲锋；推荐不得锁死其他
  候选，实际上阵仍必须经过 `assign_formation_slot` 命令。两名援军到位后可直接导航到 1-4，
  UI 不得通过打开军团页本身伪造编队进度；
- 战前快照包含由当前基础属性派生的生命、攻击、防御、等级、星级和技能偏好；
- 角色派驻与主线出战兼容，但同一角色只能强化一座设施；
- 当前旧英雄字段可作为迁移输入，库存单位实例不得继续拥有运行时权威。

## 不是本层职责

不持有钱包、设施产出、战斗实时 HP、存档写入或 UI 页面状态。

## 不变量

升级、升星、编队和派驻必须 exact-once；角色不可永久死亡；UI 必须使用 `CombatPower` 预览升级
前后差值和星级节点；兼容战备字段不得进入当前战力、建议或资源消耗。

## 验证

覆盖永久身份、升级后的属性与 `ΔCP`、三星节点、技能解锁、派驻唯一、六槽编队、无损结算、存档往返和迁移。
