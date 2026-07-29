---
km_id: reference.character-player-interceptor
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-29
source_of_truth:
  - docs/references/characters/specs/interceptor.json
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:godot --headless --path project-a --script res://tools/run_new_character_tests.gd
tags:
  - reference:character-profile
related:
  - reference.character-roster-index
---
# 预警截击马桶人
`implemented`：A级 ranger / 远程轰炸 / `flying.interceptor`；
首章阵营十连可作为A级核心候选并同时获得30碎片；4-8首通为后期确定性补领。Lv1–5=`130/24/21/112000/1150 → 136/27/22/122580/1282 → 143/30/23/133160/1414 → 150/34/25/143740/1546 → 157/37/26/154320/1678`；Lv1 CP=`1419/1736/2053`，Lv5目标CP需快照复核（unknown）。
1★截击两人，2★全队，3★反击精英；100能量、100/120/140%。总成本320XP+660币+12数据+90碎片。
一小时教学2-1→2-2→2-4→2-5，回退装甲/锚桩。双翼雷达与锁定三连音负责预警；无炮击时价值必须低于装甲，若90 tick炮击守护覆盖两轮以上则回滚至60。
