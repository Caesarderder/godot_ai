---
km_id: reference.character-player-anchor-bastion
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - docs/references/characters/specs/anchor-bastion.json
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

# 巨型飞行马桶人

> 状态：`implemented`。目录、长期招募、3-2首通图纸、研究、编队、战斗技能、科技树与程序化表现均已接入；玩家偏好仍为 `unknown`。

| 字段 | 生产合同 |
|---|---|
| ID / 分支 / 配方 | `anchor_bastion` / `heavy` / `heavy.anchor_bastion`（target） |
| 评级 / 职业 / 阵营 | B / `guardian` / 钢铁防线 |
| 职责 / 承诺 | 锚定；抵抗换位并把冲击变成反击窗口 |
| 获取 | 3-2后确定性图纸机会；研究5秒；重复转20专属碎片（target） |
| 同类取舍 | 比装甲更专门抵抗位移但不减纯伤；比维修能预防阵型破坏但不能回复生命 |

## 数值生产表

| Lv | HP | 攻 | 防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 190 | 21 | 40 | 84000 | 800 | 1638 | 2049 | 2460 |
| 2 | 210 | 23 | 44 | 85600 | 820 | 1783 | 2222 | 2681 |
| 3 | 230 | 25 | 48 | 87200 | 840 | 1928 | 2415 | 2922 |
| 4 | 250 | 28 | 52 | 88800 | 860 | 2093 | 2628 | 3173 |
| 5 | 270 | 30 | 56 | 90400 | 880 | 2238 | 2821 | 3414 |

Lv5星级属性：1★`270/30/56`，2★`351/39/72`，3★`432/48/89`。目标射程34、移动8/tick、
攻击周期6 tick、基础技能约30 tick且可因受击提前。技能Lv1/2/3将转盾量或失衡输出按
100%/120%/140%缩放，不改变免位移范围；100能量。

| 星级 | 技能质变（target） |
|---:|---|
| 1★ | 自身与相邻1人12 tick免位移，首次冲击50%伤害转盾 |
| 2★ | 扩为阶段锚区；抵抗后令最近敌人短暂失衡 |
| 3★ | 每场首次抵抗精英/Boss位移后反扣施法者，延长恢复并开放集火 |

## 培养与内容

主路线为320战斗XP、660币、12数据、20+40=60专属碎片；经验书替代路线16书+900旧金币。
首次研究无材料；兼容生产成本 `unknown`。

教学链：3-3单次换位 → 3-4换位加护盾 → 4-1保住被标记者 → 4-5取消换位但不取消Boss伤害。
回退为装甲、维修/音波、装甲/寄生、装甲/维修/双锯。表现用宽底盘、四根红白锚桩、折断位移箭头
和绷紧钢索声。

## 效率、风险与验收

- `target`预算：仅在位移关优于装甲；无位移关应因技能空转明显吃亏。
- `playtest hypothesis`：正确锚定保存一次完整输出窗口；若常驻锚区让换位机制失去决策即回滚。
- 首调持续12 tick、转盾50%、反扣恢复窗；禁止先加guardian基础属性。
- 实现需显式位移事件、锚区归属、相邻/阶段规则、Boss免疫边界、技能与全套目录/招募/UI接线。
- 测试纯伤不减、位移取消、转盾一次、2★范围、3★每场一次、回退seed、存档与844×390箭头语义。

最大未知：当前“换位”是关卡模块还是单位行为；角色只能拦截事件，不得直接删除整关模块。
