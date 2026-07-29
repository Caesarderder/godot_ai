---
km_id: reference.character-player-armored
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

# 激光火箭筒马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `armored` / `heavy.armored` |
| 评级/职业/阵营 | A / `guardian` / 钢铁防线 |
| 1★/2★/3★ CP | 1638 / 2049 / 2460 |
| 主动技能 | `siege_shield` 攻城护盾 |
| 工厂成本 | 瓷片30、零件28、污泥12；12秒 |

## 等级与战力（derived，职业基准）

| Lv | 基础HP | 基础攻 | 基础防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 190 | 21 | 40 | 84000 | 8.00% | 1638 | 2049 | 2460 |
| 2 | 213 | 23 | 44 | 85840 | 8.23% | 1792 | 2231 | 2693 |
| 3 | 236 | 26 | 49 | 87680 | 8.46% | 1977 | 2467 | 2990 |
| 4 | 259 | 29 | 53 | 89520 | 8.69% | 2152 | 2693 | 3267 |
| 5 | 282 | 32 | 58 | 91360 | 8.92% | 2337 | 2939 | 3564 |

Lv5派生属性：1★`282/32/58`，2★`366/41/75`，3★`451/51/92`。射程34；移动8→9/tick；
攻击周期6→6 tick；基础技能循环约30 tick，受击回能通常会提前。

## 培养成本（implemented）

| 项目 | 当前成本 |
|---|---|
| 主获取：图纸研究 | 固定5秒、无材料；领取时创建唯一永久角色 |
| 兼容生产队列 | 瓷片30、零件28、污泥12，12秒；材料价值256金币 |
| Lv1→5主路线 | 320战斗XP + 420马桶币 |
| 兼容经验书路线 | 16经验书 + 900旧金币 |
| 1★→3★ | 30 + 60 = 90个`armored`专属碎片 |
| 技能Lv1→3 | 12军团数据 + 240马桶币 |
| 主路线完整培养 | 660马桶币 + 12军团数据 + 90碎片；不强制加配方材料 |

完整公式见 [角色数值与培养规则](../numeric-rules.md)。

**战斗合同（implemented）：** 全星为全体存活友军加35 tick护盾；比例为26%/40%/48%。2★同时
冲击装甲门或当前目标，并给全队300 tick巨炮格挡，炮击伤害减半且反震炮台；3★嘲讽精英25 tick。

**定位：** 巨炮预警内把承压转成反攻窗口。相比维修是预防伤害；相比 Gman是团队防御而非清场。
1-4 的确定性研发链提供关键非随机解法。

**表现/验证：** 护盾、巨炮格挡、反震和嘲讽要有不同反馈。测试全队覆盖、炮击减伤、反震60伤害、
精英目标和移动堡垒协议。

## 优化分析

- **当前效率：** Lv1→5增加699/890/1104 CP；1★约1.66 CP/升级币。
- **同类对比：** Lv5 1★比维修高99 CP，来自A成长；其价值是预防和反炮，维修是战后恢复。
- **目标预算：** 2★按预警释放应显著降低一轮巨炮损失，但不能让全战无视炮击。
- **过强/过弱信号：** 300 tick格挡覆盖整场并消除所有炮击决策为过强；及时施放仍不能保住同等级
  后排为过弱。
- **首选杠杆：** 先调格挡时长、减伤50%和护盾比例，不提高HP成长；Boss固定seed中装甲使团队
  受伤下降25%–40%作为首轮目标，超过55%触发回滚评审。

**风险：** 关键Boss不能只剩装甲唯一解；火箭压炮与维修续航必须可行。
