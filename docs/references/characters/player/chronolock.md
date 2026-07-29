---
km_id: reference.character-player-chronolock
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-29
source_of_truth:
  - docs/references/characters/specs/chronolock.json
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:godot --headless --path project-a --script res://tools/run_new_character_tests.gd
tags:
  - reference:character-profile
related:
  - reference.character-roster-index
---
# 时序锁定母体
`implemented`：S级 arcanist / 干扰增殖 / `special.chronolock`；
首章后标准信号池可作为2% S级惊喜，1★已完整；5-9首通为后期确定性补领，重复40碎片。Lv1–5=`120/42/17/92000/900 → 125/50/18/95640/946 → 131/58/19/99280/992 → 138/66/20/102920/1038 → 145/74/21/106560/1084`，S倍率后Lv1 CP=`2168/2748/3338`、Lv5=`3293/4196/5092`（derived）。
1★普通守军冻结10 tick，2★含精英18 tick，3★附20 tick虚弱；Boss与结构免疫。技能100能量、100/120/140%；总成本320XP+660币+12数据+120碎片。
若一小时内抽到，教学2-1→2-2→2-4→2-5，回退音波/锚桩；主线不要求随机获得。多环时钟和节拍骤停负责反馈；若全阶段有效停摆超过20%战斗时长或Boss护卫无反击机会，二星降至14 tick。
