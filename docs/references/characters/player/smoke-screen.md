---
km_id: reference.character-player-smoke-screen
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-29
source_of_truth:
  - docs/references/characters/specs/smoke-screen.json
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:godot --headless --path project-a --script res://tools/run_new_character_tests.gd
tags:
  - reference:character-profile
related:
  - reference.character-roster-index
---
# 烟幕喷射马桶人
`implemented`：A级 arcanist / 干扰增殖 / `special.smoke_screen`；
首章阵营十连可作为A级核心候选并同时获得30碎片；4-5首通为后期确定性补领。Lv1–5基础为 `120/42/17/92000/900 → 125/49/18/95220/940 → 131/56/19/98440/980 → 137/63/20/101660/1020 → 143/70/21/104880/1061`；Lv1 CP=`1644/2042/2460`，Lv5=`2354/2960/3569`（derived）。
1★保护最低血，2★全队烟幕，3★虚弱精英；100能量，技能等级100/120/140%。成长总计320XP+660币+12数据+90碎片；经验书路线互斥。
一小时教学2-1→2-2→2-4→2-5，回退维修/装甲；双烟罐和灰蓝喷雾负责可读性。烟幕不能回血；若平均吸收超过装甲盾或使集火机制无效则先削护盾20%。
