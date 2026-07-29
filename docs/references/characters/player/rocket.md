---
km_id: reference.character-player-rocket
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

# 飞行四发射器马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `rocket` / `flying.rocket` |
| 评级/职业/阵营 | B / `ranger` / 远程轰炸 |
| 1★/2★/3★ CP | 1419 / 1736 / 2053 |
| 主动技能 | `rocket_salvo` 火箭齐射 |
| 工厂成本 | 瓷片10、零件24、污泥18；10秒 |

## 等级与战力（derived，职业基准）

| Lv | 基础HP | 基础攻 | 基础防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 130 | 24 | 21 | 112000 | 11.50% | 1419 | 1736 | 2053 |
| 2 | 136 | 26 | 22 | 120000 | 12.50% | 1513 | 1833 | 2186 |
| 3 | 142 | 28 | 23 | 128000 | 13.50% | 1607 | 1953 | 2312 |
| 4 | 148 | 31 | 24 | 136000 | 14.50% | 1721 | 2103 | 2485 |
| 5 | 154 | 33 | 25 | 144000 | 15.50% | 1815 | 2203 | 2621 |

Lv5派生属性：1★`154/33/25`，2★`200/42/32`，3★`246/52/40`。射程110；移动10→12/tick；
攻击周期5→4 tick；基础技能循环约25→20 tick，是当前最快循环组之一。

## 培养成本（implemented）

| 项目 | 当前成本 |
|---|---|
| 主获取：图纸研究 | 固定5秒、无材料；领取时创建唯一永久角色 |
| 兼容生产队列 | 瓷片10、零件24、污泥18，10秒；材料价值200金币 |
| Lv1→5主路线 | 320战斗XP + 420马桶币 |
| 兼容经验书路线 | 16经验书 + 900旧金币 |
| 1★→3★ | 20 + 40 = 60个`rocket`专属碎片 |
| 技能Lv1→3 | 12军团数据 + 240马桶币 |
| 主路线完整培养 | 660马桶币 + 12军团数据 + 60碎片；不强制加配方材料 |

完整公式见 [角色数值与培养规则](../numeric-rules.md)。

**战斗合同（implemented）：** 1★轰击当前目标；2★齐射当前阶段全部目标，并对结构使用更高
倍率；3★命中结构时施加30 tick破甲，默认使后续承伤提高25%。

**定位：** 在设施层或 Boss 外甲暴露时快速拆塔。相比自爆，持续攻城且无自损；相比双锯，覆盖
结构和多目标而非优先精英。远程轰炸协议进一步标定结构。

**表现/验证：** 飞行轮廓、弹道、范围爆炸和结构破甲必须可读。测试多目标、结构倍率、破甲计时、
关卡防空扫描停火但不伤害永久角色。

## 优化分析

- **当前效率：** Lv1→5增加396/467/568 CP，面板成长最低；价值集中在速度、结构倍率和破甲。
- **同类对比：** Lv5 1★比自爆低74 CP但生产价值高2；优势应是稳定拆塔而非爆发。
- **目标预算：** 2★结构齐射是章节软解，3★破甲应提高团队拆塔而非独自秒核心。
- **过强/过弱信号：** 3★使Boss核心有效承伤长期提高超过25%配置为实现异常；同投入下结构阶段
  用时未比非攻城位缩短15%则定位偏弱（playtest hypothesis）。
- **首选杠杆：** 优先调结构倍率55/10与破甲时长30 tick，不提高基础攻击；回滚阈值为关键结构
  被单次齐射跨阶段击毁。

**风险：** CP低估技能价值；第四章必须保留地面替代。
