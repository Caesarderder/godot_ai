---
km_id: reference.character-alliance-camera-overseer
km_type: reference
domain: battle-progression
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - project-a/game/scripts/domain/content/stage_catalog.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - project-a/tools/run_battle_tests.gd
  - python3 tools/docs_lint.py
tags:
  - reference:character-profile
  - domain:battle-progression
related:
  - reference.character-roster-index
---

# 摄像监军

| 字段 | 当前事实 |
|---|---|
| 稳定 archetype | `camera_overseer` |
| 投放 | 第一章第4关起的第三战斗带 |
| 职业/精英 | `arcanist` / 是 |
| 未缩放基准 | HP240、攻34、防11、射程96、攻击周期8 tick |

## 数值与预算

第一章第4关起固定1名：HP240、攻击34、防11；移动4/tick、1.6秒攻击一次。相比盾卫HP+26%、
攻击+17%、射程+153%。无培养成本；增加监军轮廓和远程信号表现。

**战斗问题：** 后线高伤精英惩罚只处理前排的阵容，并把压力延续到核心前。

**反馈与反制：** 高位镜头、监军信号和远程攻击要区别于盾卫；双锯斩杀、火箭跨区输出、装甲承压
均可处理。

**优化规划：** 监军应是第一章优先目标而非最高耐久墙。若其实际输出低于普通射手整组则存在感
不足；若玩家没有远程/斩杀时无法接近则过强。优先调射程96或攻击34，不再叠加光环。

**边界：** 监军没有独占光环；第一章关卡级机制与核心炮另行结算。
