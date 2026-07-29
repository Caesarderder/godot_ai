---
km_id: reference.character-player-ram-breaker
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-29
source_of_truth:
  - docs/references/characters/specs/ram-breaker.json
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:godot --headless --path project-a --script res://tools/run_new_character_tests.gd
tags:
  - reference:character-profile
related:
  - reference.character-roster-index
---
# 破盾撞角马桶人
`implemented`：B级 fighter / 快攻破城 / `ordinary.ram_breaker`；
首章阵营十连可作为B级核心候选并同时获得20碎片；4-4首通为后期确定性补领。承诺是在护盾亮起时碎盾，取舍是无盾目标收益低于双锯。基础成长（HP/攻/防/速/暴击）Lv1–5：`150/36/28/92000/900 → 157/42/29/96220/940 → 165/48/30/100440/980 → 173/54/31/104660/1020 → 181/60/32/108880/1060`；Lv1 CP 1/2/3★=`1724/2139/2574`，Lv5为 `2385/2996/3617`（derived）。
技能100能量，Lv1/2/3为100%/120%/140%；1★碎单盾，2★同阶段，3★碎盾返40能。培养为320战斗XP+420币、技能240币+12数据、升星20+40碎片；经验书16本+900旧金币是互斥兼容路线。
一小时教学2-1→2-2→2-3→2-5，回退双锯/协议编织。撞角与陶瓷碎裂声负责读招；若无盾也优于冲锋或返能使循环少于20 tick则回滚。
