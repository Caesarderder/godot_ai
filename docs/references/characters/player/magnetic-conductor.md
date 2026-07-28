---
km_id: reference.character-player-magnetic-conductor
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - docs/references/characters/specs/magnetic-conductor.json
  - project-a/game/scripts/domain/progression/hero_progression.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/domain/factory/factory_catalog.gd
validated_by:
  - command:godot --headless --path project-a --script res://tools/run_new_character_tests.gd
  - python3 tools/docs_lint.py
tags:
  - reference:character-profile
  - reference:character-proposal
related:
  - reference.character-roster-index
---

# 磁轨牵引马桶人

> 状态：`implemented`。目录、长期招募、4-1首通图纸、研究、编队、战斗技能、科技树与程序化表现均已接入；玩家偏好仍为 `unknown`。

| 字段 | 生产合同 |
|---|---|
| ID / 分支 / 配方 | `magnetic_conductor` / `flying` / `flying.magnetic_conductor`（target） |
| 评级 / 职业 / 阵营 | A / `ranger` / 远程轰炸 |
| 职责 / 承诺 | 聚拢；分散火力出现时，把守军收束为一次范围爆发窗口 |
| 获取 | 3-5后确定性科技预览；图纸研究5秒；重复图纸转30专属碎片（target） |
| 同类取舍 | 比音波更改位置但不持续虚弱；比火箭更强协同但单体和结构输出更低 |

## 数值生产表

基础属性和CP为 `derived`；技能尚为 `target`。速度显示为千分值，暴击为基点。

| Lv | HP | 攻 | 防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 130 | 24 | 21 | 112000 | 1150 | 1419 | 1736 | 2053 |
| 2 | 136 | 26 | 22 | 121200 | 1265 | 1516 | 1836 | 2189 |
| 3 | 143 | 29 | 23 | 130400 | 1380 | 1637 | 1983 | 2362 |
| 4 | 150 | 32 | 25 | 139600 | 1495 | 1768 | 2153 | 2568 |
| 5 | 157 | 35 | 26 | 148800 | 1610 | 1889 | 2300 | 2741 |

Lv5星级属性：1★`157/35/26`，2★`204/45/33`，3★`251/56/41`。目标射程110、移动10→12/tick、
攻击周期5→4 tick；100能量，基础约25→20 tick一轮。技能Lv1/2/3对连锁冲击输出采用
100%/120%/140%，不提高牵引上限；费用为初始 / 80币+4数据 / 160币+8数据。

| 星级 | 技能质变（target） |
|---:|---|
| 1★ | 牵引至多2名普通守军并标记12 tick；Boss、结构、锚定精英免疫 |
| 2★ | 扩为当前阶段普通守军；首次范围命中触发一次连锁 |
| 3★ | 首名标记者倒下触发坍缩并返40能量，每次施放一次 |

## 培养与内容

Lv1→5为320战斗XP+420币；技能满级为240币+12数据；1★→3★为30+60=90专属碎片；
主路线合计660币+12数据+90碎片。经验书兼容路线为16书+900旧金币，不能与主路线相加。
首次研究不扣材料；兼容生产配方的材料、时长和价值均为 `unknown`，实现前必须定表。

教学链：4-2双线安全聚拢 → 4-3聚拢接火箭/自爆 → 4-4轮换防线高光 → 4-5只牵护卫、
不牵Boss。回退分别为音波、火箭/音波、自爆/双锯、装甲/火箭/维修。远景用U形磁轭、青色拉线，
声音用双音锁定—低频吸合—坍缩脆响。

## 效率、风险与验收

- `target`预算：同星火箭负责拆结构，本角色负责让两个以上敌人进入AOE；单体不得优于火箭。
- `playtest hypothesis`：合理释放应令交叉火力存续时间下降20%–35%；超过50%或让Boss护卫永久失能即回滚。
- 调参先改目标上限、标记12 tick、返能40，不先改职业基础属性。
- 需实现目录、招募、碎片、技能Resource、战斗目标移动/免疫、模型、科技树、推荐与本地化。
- 测试：固定seed复现、1★两目标、2★连锁一次、3★返能一次、免疫目标、存档回环、同预算回退；
  844×390检查拉线、免疫字样、星级文案和技能目标；真人问题是“何时你宁愿带火箭或音波？”

最大未知：敌人运行时稳定archetype尚未透传，锚定精英判定需要先修正该身份边界。
