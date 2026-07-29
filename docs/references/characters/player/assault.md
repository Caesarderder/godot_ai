---
km_id: reference.character-player-assault
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

# 普通马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `assault` / `ordinary.assault` |
| 评级/职业/阵营 | B / `fighter` / 快攻破城 |
| 1★/2★/3★ CP | 1724 / 2139 / 2574（derived，不含技能价值） |
| 主动技能 | `plunger_charge` 皮搋冲锋 |
| 工厂成本 | 瓷片20、零件8、污泥4；5秒 |

## 等级与战力（derived，职业基准）

| Lv | 基础HP | 基础攻 | 基础防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 150 | 36 | 28 | 92000 | 9.00% | 1724 | 2139 | 2574 |
| 2 | 160 | 41 | 30 | 95200 | 9.40% | 1884 | 2358 | 2832 |
| 3 | 170 | 46 | 32 | 98400 | 9.80% | 2044 | 2547 | 3080 |
| 4 | 180 | 52 | 34 | 101600 | 10.20% | 2225 | 2787 | 3369 |
| 5 | 190 | 57 | 36 | 104800 | 10.60% | 2385 | 2996 | 3617 |

Lv5派生属性：1★`190/57/36`，2★`247/74/46`，3★`304/91/57`（HP/攻/防）。射程34；
移动9→9/tick；攻击周期6→5 tick；最早基础技能循环约30→25 tick。

## 培养成本（implemented）

| 项目 | 当前成本 |
|---|---|
| 主获取：图纸研究 | 固定5秒、无材料；领取时创建唯一永久角色 |
| 兼容生产队列 | 瓷片20、零件8、污泥4，5秒；材料价值112金币 |
| Lv1→5主路线 | 320战斗XP + 420马桶币 |
| 兼容经验书路线 | 16经验书 + 900旧金币（互斥替代） |
| 1★→3★ | 20 + 40 = 60个`assault`专属碎片 |
| 技能Lv1→3 | 12军团数据 + 240马桶币 |
| 主路线完整培养 | 660马桶币 + 12军团数据 + 60碎片；不强制加配方材料 |

完整公式见 [角色数值与培养规则](../numeric-rules.md)。

**战斗合同（implemented）：** 1★重击最近守军；2★顺劈当前阶段敌军；3★提高主击倍率并眩晕
首名存活守军 10 tick。阵营协议提供开局能量，服务首次快速爆发。

**定位：** 用最低理解成本解决“守军挡住推进”。比双锯更普及、偏群体；比音波更直接，但缺少
持续削弱。首次蓝图与 1-4 失败—研究—反攻链绑定。

**表现/验证：** 皮搋突进、命中与顺劈对象必须可辨。测试首目标选择、2★额外命中、3★眩晕、
科技协议能量和关键关不依赖随机抽取。

## 优化分析

- **当前效率：** Lv1→5增加661/857/1043 CP（1/2/3★）；1★约1.57 CP/升级币。
- **同类对比：** Lv5 1★比双锯低1098 CP，但成本评级更低且2★获得群体清线。
- **目标预算：** B级确定性清线位；2★应在2个以上守军时明显优于1★，但对单精英弱于双锯。
- **过强/过弱信号：** 若2★顺劈在Boss单体仍胜双锯为过强；若1-4确定性反攻仍无法清普通守军为
  过弱。
- **首选杠杆：** 调顺劈倍率或目标上限；不先动基础fighter成长。回滚阈值为1-4教学链失败。

**风险：** 与双锯同分支，技能目标差异是主要身份；玩家喜爱度unknown。
