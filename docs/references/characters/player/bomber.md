---
km_id: reference.character-player-bomber
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/content/faction_catalog.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:python3 .codex/skills/toilet-character-production/scripts/character_design.py snapshot --project-root project-a
  - python3 tools/docs_lint.py
tags:
  - reference:character-profile
  - domain:hero-formation
related:
  - reference.character-roster-index
---

# 自爆飞行马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `bomber` / `flying.bomber` |
| 评级/职业/阵营 | A / `ranger` / 远程轰炸 |
| 1★/2★/3★ CP | 1419 / 1736 / 2053 |
| 主动技能 | `suicide_dive` 舍身俯冲 |
| 工厂成本 | 瓷片12、零件18、污泥22；8秒 |

**战斗合同（implemented）：** 1★对当前目标造成4倍攻击并把生命压到不高于35%；2★主击8倍、
对同阶段其余目标造成2倍伤害，并把生命压到不高于85%；3★取消角色自损。

**定位：** 密集增援出现时用生存换即时范围爆发。相比火箭更偏一次性波峰；相比音波没有减伤
控制。永久角色战后恢复，自损不产生跨局损失。

**表现/验证：** 俯冲主体与可消耗爆破载荷要避免表达为永久死亡。测试残血上限、溅射去重、
3★无自损和第四章防空扫描。

**风险：** “自爆”叙事与永久拥有合同冲突，表现必须强调载荷而非角色死亡。
