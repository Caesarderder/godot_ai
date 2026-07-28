---
km_id: reference.character-player-parasite
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

# 寄生母体马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `parasite` / `special.parasite` |
| 评级/职业/阵营 | S / `arcanist` / 干扰增殖 |
| 1★/2★/3★ CP | 2168 / 2748 / 3338 |
| 主动技能 | `parasite_swarm` 寄生虫群 |
| 工厂成本 | 瓷片16、零件18、污泥30；18秒 |

**战斗合同（implemented）：** 1★召唤寄生幼体分担火力；2★增加召唤规模；3★优先短暂策反
普通守军，无法策反时回退到召唤。临时单位不进入永久角色与CP合同。

**定位：** 精英波次或持续炮火时用额外单位改变目标分配。相比音波需要展开但能吸引火力；相比
维修不直接恢复主力。第四章净化只伤害幼体和策反单位，不伤永久角色。

**表现/验证：** 母体、幼体、策反归属和净化反馈必须易读。测试召唤数量、普通/精英筛选、回退、
临时单位结算清理与净化伤害边界。

**风险：** 召唤和控制不计入CP；不得以隐藏战力补偿或宣称已平衡。
