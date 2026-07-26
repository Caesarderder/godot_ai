---
km_id: domain.battle-progression
km_type: domain
domain: battle-progression
status: active
owner: gameplay
last_verified: 2026-07-26
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/domain/content/stage_catalog.gd
validated_by:
  - user-confirmed-redesign-session-2026-07-26
  - python3 tools/docs_lint.py
tags:
  - domain:battle-progression
  - decision:p0-system
related:
  - domain.product
  - domain.hero-formation
  - domain.factory-cultivation
  - reference.implementation-status
  - reference.game-state-measurement-framework
---

# 战斗与城镇推进领域

## 目标

让永久军团主动攻占城镇，在短局三段式自动攻城中承受仅限本局的 HP 压力，并把金币、工业技术、突破资源和进度安全结算到长期状态。

## 职责

- 未侦察、可进攻、已占领三种城镇状态；
- 战前显示威胁、推荐战力、首通奖励、当前编队能力比与预计本局风险；
- 战斗保持确定性 5Hz tick、自动移动/索敌/普通攻击与可选技能自动化；
- 结果可输出本局伤害复盘；关键过坎可从真实出战、逐角色伤害和队伍承伤统计生成因果复盘，
  但不得由表现层猜测贡献，也不得写回永久战备损失或维修队列；
- 首章 Boss 失败恢复先检查有效二星成长，再使用真实巨炮命中/压制统计区分成长、机制时机与
  阵容战力问题；主要恢复行动必须匹配诊断，不得对所有失败固定返回同一页面；
- 首章 Boss 胜利使用真实巨炮处理统计证明所选成长路线，显示实际开放内容，并把主要出口指向
  下一章战前侦察；普通城镇胜利文案、未验证的解锁声明或继续培养按钮不得替代章节完成反馈；
- 胜利发完整战果，失败和撤退不发完整通关奖励；
- 奖励和关卡进度在一个命令中 exact-once 结算；
- 同时维护挑战线与推荐线；推荐战力由固定 seed 强度扫描与真人校准产生，
  不由敌方属性求和或账号总战力直接决定。

## 不是本层职责

不修改工厂资源、不决定角色升级和设施产速。

## 不变量

相同战前快照与 seed 得到相同战斗结果；表现层不反向改变胜负；角色不会永久删除；
重复结算不重复发奖；战斗内阵亡不改变角色的永久可用状态。

## 验证

覆盖胜利、失败、撤退、超时、三段推进、本局伤害复盘、无损结算、首通、重复结算、跨帧率结果和 3D 投影。

## 入口

[KM:reference.game-state-measurement-framework](../references/product-design/game-state-measurement-framework.md)。
