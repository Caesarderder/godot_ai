---
km_id: reference.character-player-drain-engine
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-29
source_of_truth:
  - docs/references/characters/specs/drain-engine.json
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:godot --headless --path project-a --script res://tools/run_new_character_tests.gd
tags:
  - reference:character-profile
related:
  - reference.character-roster-index
---
# 虹吸引擎马桶人
`implemented`：A级 guardian / 钢铁防线 / `heavy.drain_engine`；
首章阵营十连可作为A级核心候选并同时获得30碎片；5-3首通为后期确定性补领。Lv1–5=`190/21/40/84000/800 → 201/23/44/86875/846 → 212/26/48/89750/892 → 223/28/52/92625/938 → 234/31/56/95500/984`；Lv1 CP=`1638/2049/2460`，Lv5目标CP待快照补证（unknown）。
1★充能一人45，2★两人，3★虚弱精英24 tick；100能量、100/120/140%。总成本320XP+660币+12数据+90碎片。
一小时教学2-1→2-2→2-4→2-5，回退音波/维修。旋转涡轮和由低至高充能音负责反馈；不能给自己形成无限循环。若使两名核心每轮少于3次攻击即可放技，充能降至30。
