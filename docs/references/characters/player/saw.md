---
km_id: reference.character-player-saw
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/content/faction_catalog.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:python3 .codex/skills/toilet-character-production/scripts/character_design.py snapshot --project-root project-a
  - python3 tools/docs_lint.py
tags:
  - reference:character-profile
  - domain:hero-formation
related:
  - reference.character-roster-index
---

# 飞行双圆锯马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `saw` / `heavy.saw` |
| 评级/职业/阵营 | S / `fighter` / 快攻破城 |
| 1★/2★/3★ CP | 2294 / 2893 / 3502 |
| 主动技能 | `saw_rush` 双锯突袭 |
| 工厂成本 | 瓷片26、零件34、污泥14；14秒 |

## 等级与战力（derived，职业基准）

| Lv | 基础HP | 基础攻 | 基础防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 150 | 36 | 28 | 92000 | 9.00% | 2294 | 2893 | 3502 |
| 2 | 163 | 43 | 30 | 96160 | 9.52% | 2591 | 3275 | 3972 |
| 3 | 176 | 50 | 33 | 100320 | 10.04% | 2898 | 3680 | 4452 |
| 4 | 189 | 57 | 35 | 104480 | 10.56% | 3175 | 4032 | 4902 |
| 5 | 202 | 64 | 38 | 108640 | 11.08% | 3483 | 4438 | 5393 |

S稀有度使派生属性高于基础值：Lv1 1★为`210/50/39`，Lv5 1★为`282/89/53`；Lv5 3★达到
`452/143/85`。射程34；移动9→10/tick；攻击周期6→5 tick；技能循环约30→25 tick。

## 培养成本（implemented）

| 项目 | 当前成本 |
|---|---|
| 主获取：图纸研究 | 固定5秒、无材料；领取时创建唯一永久角色 |
| 兼容生产队列 | 瓷片26、零件34、污泥14，14秒；材料价值275金币 |
| Lv1→5主路线 | 320战斗XP + 420马桶币 |
| 兼容经验书路线 | 16经验书 + 900旧金币 |
| 1★→3★ | 40 + 80 = 120个`saw`专属碎片 |
| 技能Lv1→3 | 12军团数据 + 240马桶币 |
| 主路线完整培养 | 660马桶币 + 12军团数据 + 120碎片；不强制加配方材料 |

完整公式见 [角色数值与培养规则](../numeric-rules.md)。

**战斗合同（implemented）：** 优先选择当前精英，否则攻击当前目标；1★3倍攻击；2★先4倍再
追加2倍连斩；3★若击杀则返还55能量。

**定位：** 对高价值精英建立连续斩杀节奏。相比冲锋更昂贵、更单点且优先精英；相比火箭不擅长
范围拆塔。S级1★基础CP已高于同职业B/A 2★基准。

**表现/验证：** 双锯锁定、两段命中和击杀回能必须清楚。测试精英优先、无精英回退、连斩次数、
死亡判定与开局能量协议。

## 优化分析

- **当前效率：** Lv1→5增加1189/1545/1891 CP，远高于B/A；这是S稀有度与130%成长叠加结果。
- **同类对比：** Lv1 1★已比Lv1冲锋2★高155 CP；Lv5 1★比冲锋3★低134 CP，符合流派核心定位。
- **目标预算：** 单精英斩杀最优，普通多目标清线必须输给冲锋/火箭；返能只在真实击杀发生。
- **过强/过弱信号：** 1★在相同等级无视目标类型全面领先所有角色为过强；S级1★无法显著压低
  精英存活时间为过弱。
- **首选杠杆：** 先调技能3倍/6倍总倍率和返能55，不动S基础倍率；相对同星冲锋的精英击杀时间
  缩短20%–35%作为目标，普通波总伤领先超过15%触发回滚。

**风险：** 当前没有fallback推荐，高强度不能变成关键关隐性抽卡门槛。
