---
km_id: reference.character-player-bulwark
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-29
source_of_truth:
  - docs/references/characters/specs/bulwark.json
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:godot --headless --path project-a --script res://tools/run_new_character_tests.gd
tags:
  - reference:character-profile
related:
  - reference.character-roster-index
---
# 联结壁垒马桶人
`implemented`：B级 guardian / 钢铁防线 / `heavy.bulwark`；
首章阵营十连可作为B级核心候选并同时获得20碎片；4-10首通为后期确定性补领。Lv1–5=`190/21/40/84000/800 → 200/23/43/86500/840 → 210/25/46/89000/880 → 220/27/49/91500/920 → 230/29/52/94000/960`；Lv1 CP=`1638/2049/2460`，Lv5=`2238/2821/3414`（derived）。
1★联结两名低血，2★全队，3★即时治疗；100能量、100/120/140%。总成本320XP+660币+12数据+60碎片。
一小时教学2-1→2-2→2-4→2-5，回退装甲/维修。蓝色联结管与低频压力脉冲负责反馈；当前实现以护盾近似分摊，真实伤害分流仍为unknown，若与维修叠加使全队无损则削盾。
