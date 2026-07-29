---
km_id: reference.character-player-echo-mimic
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-29
source_of_truth:
  - docs/references/characters/specs/echo-mimic.json
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:godot --headless --path project-a --script res://tools/run_new_character_tests.gd
tags:
  - reference:character-profile
related:
  - reference.character-roster-index
---
# 回声拟态母体
`implemented`：S级 arcanist / 干扰增殖 / `special.echo_mimic`；
首章后标准信号池可作为2% S级惊喜，1★已完整；4-12首通为后期确定性补领，重复40碎片。Lv1–5基础职业值同arcanist，S稀有倍率生效：`120/42/17/92000/900`起，等级路径`125/50/18/95640/946 → 131/58/19/99280/992 → 138/66/20/102920/1038 → 145/74/21/106560/1084`；Lv1 CP=`2168/2748/3338`，Lv5=`3293/4196/5092`（derived）。
1★单目标回响，2★多目标，3★每场首次立即再蓄能；100能量、100/120/140%。总成本320XP+660币+12数据+120碎片。
若一小时内抽到，教学2-1→2-2→2-4→2-5，回退音波/双锯；主线不要求随机获得。环形共鸣器和前次技能低八度重放负责反馈；当前回响为稳定战术冲击而非任意技能复制，避免递归。若三星产生三连施放则将返能降至60。
