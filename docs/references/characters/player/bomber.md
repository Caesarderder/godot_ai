---
km_id: reference.character-player-bomber
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

# 自爆飞行马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `bomber` / `flying.bomber` |
| 评级/职业/阵营 | A / `ranger` / 远程轰炸 |
| 1★/2★/3★ CP | 1419 / 1736 / 2053 |
| 主动技能 | `suicide_dive` 舍身俯冲 |
| 工厂成本 | 瓷片12、零件18、污泥22；8秒 |

## 等级与战力（derived，职业基准）

| Lv | 基础HP | 基础攻 | 基础防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 130 | 24 | 21 | 112000 | 11.50% | 1419 | 1736 | 2053 |
| 2 | 136 | 26 | 22 | 121200 | 12.65% | 1516 | 1836 | 2189 |
| 3 | 143 | 29 | 23 | 130400 | 13.80% | 1637 | 1983 | 2362 |
| 4 | 150 | 32 | 25 | 139600 | 14.95% | 1768 | 2153 | 2568 |
| 5 | 157 | 35 | 26 | 148800 | 16.10% | 1889 | 2300 | 2741 |

Lv5派生属性：1★`157/35/26`，2★`204/45/33`，3★`251/56/41`。射程86；移动10→12/tick；
攻击周期5→4 tick；基础技能循环约25→20 tick。

## 培养成本（implemented）

| 项目 | 当前成本 |
|---|---|
| 主获取：图纸研究 | 固定5秒、无材料；领取时创建唯一永久角色 |
| 兼容生产队列 | 瓷片12、零件18、污泥22，8秒；材料价值198金币 |
| Lv1→5主路线 | 320战斗XP + 420马桶币 |
| 兼容经验书路线 | 16经验书 + 900旧金币 |
| 1★→3★ | 30 + 60 = 90个`bomber`专属碎片 |
| 技能Lv1→3 | 12军团数据 + 240马桶币 |
| 主路线完整培养 | 660马桶币 + 12军团数据 + 90碎片；不强制加配方材料 |

完整公式见 [角色数值与培养规则](../numeric-rules.md)。

**战斗合同（implemented）：** 1★对当前目标造成4倍攻击并把生命压到不高于35%；2★主击8倍、
对同阶段其余目标造成2倍伤害，并把生命压到不高于85%；3★取消角色自损。

**定位：** 密集增援出现时用生存换即时范围爆发。相比火箭更偏一次性波峰；相比音波没有减伤
控制。永久角色战后恢复，自损不产生跨局损失。

**表现/验证：** 俯冲主体与可消耗爆破载荷要避免表达为永久死亡。测试残血上限、溅射去重、
3★无自损和第四章防空扫描。

## 优化分析

- **当前效率：** Lv1→5增加470/564/688 CP；A评级成长使其后期面板略高于火箭。
- **同类对比：** 与火箭成本接近；自爆用生命风险换8倍主击和溅射，火箭以结构倍率/破甲换稳定性。
- **目标预算：** 1–2★施放后必须产生可见风险，3★质变取消风险但不能同时压过所有范围输出。
- **过强/过弱信号：** 2★自损后仍长期满血等于风险失效；1★施放后在正常波次必死且维修无法
  挽救则过弱。
- **首选杠杆：** 调自损保留35%/85%与溅射2倍，不先加主击；3★固定seed总伤领先火箭超过35%
  时触发回滚评审（playtest hypothesis）。

**风险：** 名称与永久角色合同冲突；第四章防空会降低纯飞行阵容可靠性。
