---
km_id: reference.character-player-mortar
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-29
source_of_truth:
  - docs/references/characters/specs/mortar.json
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:godot --headless --path project-a --script res://tools/run_new_character_tests.gd
tags:
  - reference:character-profile
related:
  - reference.character-roster-index
---
# 曲射臼炮马桶人
`implemented`：B级 ranger / 远程轰炸 / `flying.mortar`；
首章阵营十连可作为B级核心候选并同时获得20碎片；4-7首通为后期确定性补领。Lv1–5：`130/24/21/112000/1150 → 136/26/22/121200/1265 → 143/29/23/130400/1380 → 150/32/25/139600/1495 → 157/35/26/148800/1610`；Lv1 CP=`1419/1736/2053`，Lv5=`1815/2203/2621`（derived）。
1★曲射最远目标，2★溅射守军，3★结构破甲45 tick；100能量、100/120/140%。总成本320XP+660币+12数据+60碎片；兼容书路线另算。
一小时教学2-1→2-2→2-3→2-5，回退火箭/相位钻袭。短粗炮管、抛物线和先闷响后爆裂负责反馈；若单体拆塔快于同星火箭则先把4倍倍率降至3倍。
