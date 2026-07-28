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

# 冲锋马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `assault` / `ordinary.assault` |
| 评级/职业/阵营 | B / `fighter` / 快攻破城 |
| 1★/2★/3★ CP | 1724 / 2139 / 2574（derived，不含技能价值） |
| 主动技能 | `plunger_charge` 皮搋冲锋 |
| 工厂成本 | 瓷片20、零件8、污泥4；5秒 |

**战斗合同（implemented）：** 1★重击最近守军；2★顺劈当前阶段敌军；3★提高主击倍率并眩晕
首名存活守军 10 tick。阵营协议提供开局能量，服务首次快速爆发。

**定位：** 用最低理解成本解决“守军挡住推进”。比双锯更普及、偏群体；比音波更直接，但缺少
持续削弱。首次蓝图与 1-4 失败—研究—反攻链绑定。

**表现/验证：** 皮搋突进、命中与顺劈对象必须可辨。测试首目标选择、2★额外命中、3★眩晕、
科技协议能量和关键关不依赖随机抽取。

**风险：** 与双锯同属快攻分支；文案必须强调“清线突破”而非“精英斩杀”。
