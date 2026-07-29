---
km_id: reference.character-player-swarm-beacon
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-29
source_of_truth:
  - docs/references/characters/specs/swarm-beacon.json
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:godot --headless --path project-a --script res://tools/run_new_character_tests.gd
tags:
  - reference:character-profile
related:
  - reference.character-roster-index
---
# 群落信标马桶人
`implemented`：B级 arcanist / 干扰增殖 / `special.swarm_beacon`；
首章阵营十连可作为B级核心候选并同时获得20碎片；5-6首通为后期确定性补领。Lv1–5=`120/42/17/92000/900 → 125/48/18/94800/940 → 130/54/19/97600/980 → 135/60/20/100400/1020 → 140/66/21/103200/1060`；Lv1 CP=`1644/2042/2460`，Lv5基准约`2248/2828/3428`（derived，待快照复核）。
1★一诱饵，2★两诱饵，3★登场虚弱12 tick；100能量、100/120/140%。总成本320XP+660币+12数据+60碎片。
一小时教学2-1→2-2→2-4→2-5，回退寄生/装甲。蜂巢信标与短促召集声负责反馈；诱饵是临时单位且不进入培养。若召唤体造成伤害超过本体或拖延Boss超过20秒则削生命。
