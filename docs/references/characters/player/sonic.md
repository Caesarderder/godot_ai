---
km_id: reference.character-player-sonic
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

# 故障闪电马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `sonic` / `ordinary.sonic` |
| 评级/职业/阵营 | A / `arcanist` / 干扰增殖 |
| 1★/2★/3★ CP | 1644 / 2042 / 2460 |
| 主动技能 | `sonic_disruptor` 音波干扰 |
| 工厂成本 | 瓷片16、零件14、污泥10；7秒 |

## 等级与战力（derived，职业基准）

| Lv | 基础HP | 基础攻 | 基础防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 120 | 42 | 17 | 92000 | 9.00% | 1644 | 2042 | 2460 |
| 2 | 125 | 49 | 18 | 95220 | 9.40% | 1819 | 2260 | 2724 |
| 3 | 131 | 56 | 19 | 98440 | 9.80% | 1997 | 2484 | 3001 |
| 4 | 137 | 63 | 20 | 101660 | 10.20% | 2176 | 2719 | 3282 |
| 5 | 143 | 70 | 21 | 104880 | 10.61% | 2354 | 2960 | 3569 |

Lv5派生属性：1★`143/70/21`，2★`185/91/27`，3★`228/112/33`。射程110；移动9→9/tick；
攻击周期6→5 tick；基础技能循环约30→25 tick。

## 培养成本（implemented）

| 项目 | 当前成本 |
|---|---|
| 主获取：图纸研究 | 固定5秒、无材料；领取时创建唯一永久角色 |
| 兼容生产队列 | 瓷片16、零件14、污泥10，7秒；材料价值147金币 |
| Lv1→5主路线 | 320战斗XP + 420马桶币 |
| 兼容经验书路线 | 16经验书 + 900旧金币（互斥替代） |
| 1★→3★ | 30 + 60 = 90个`sonic`专属碎片 |
| 技能Lv1→3 | 12军团数据 + 240马桶币 |
| 主路线完整培养 | 660马桶币 + 12军团数据 + 90碎片；不强制加配方材料 |

完整公式见 [角色数值与培养规则](../numeric-rules.md)。

**战斗合同（implemented）：** 1★伤害并虚弱同路守军 22 tick；2★覆盖全线并延长到35 tick；
3★提高伤害并对普通守军追加5 tick眩晕，精英不被该眩晕命中。

**定位：** 守军火力高峰前把危险窗口变成安全输出窗口。相比冲锋，牺牲直接击杀换全线减压；
相比寄生，反馈更即时、没有召唤展开时间。

**表现/验证：** 音波扩散圈、虚弱状态与三星短控必须区分。测试跨线目标数、精英免眩晕、
失序扩散协议和技能等级只缩放执行输出。

## 优化分析

- **当前效率：** Lv1→5增加710/918/1109 CP；1★约1.69 CP/升级币。
- **同类对比：** Lv5 1★CP仅比冲锋低31，但控制价值未计入CP，实际强度可能更高。
- **目标预算：** A级控场骨干；2★价值来自跨线覆盖，3★只压普通兵，不能锁死精英/Boss。
- **过强/过弱信号：** 若无伤害阵容仅靠虚弱可无限拖Boss为过强；若2★跨线在三路波次无法减少
  实际受伤为过弱。
- **首选杠杆：** 先调虚弱时长22/35或目标范围，再调伤害倍率；固定seed受伤下降20%–35%作为
  首轮playtest hypothesis，超出50%触发回滚评审。

**风险：** CP不计控制价值；必须用事件与实际受伤对照，玩家理解度unknown。
