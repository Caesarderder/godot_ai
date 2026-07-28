---
km_id: reference.character-player-sonic
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

# 音波马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `sonic` / `ordinary.sonic` |
| 评级/职业/阵营 | A / `arcanist` / 干扰增殖 |
| 1★/2★/3★ CP | 1644 / 2042 / 2460 |
| 主动技能 | `sonic_disruptor` 音波干扰 |
| 工厂成本 | 瓷片16、零件14、污泥10；7秒 |

**战斗合同（implemented）：** 1★伤害并虚弱同路守军 22 tick；2★覆盖全线并延长到35 tick；
3★提高伤害并对普通守军追加5 tick眩晕，精英不被该眩晕命中。

**定位：** 守军火力高峰前把危险窗口变成安全输出窗口。相比冲锋，牺牲直接击杀换全线减压；
相比寄生，反馈更即时、没有召唤展开时间。

**表现/验证：** 音波扩散圈、虚弱状态与三星短控必须区分。测试跨线目标数、精英免眩晕、
失序扩散协议和技能等级只缩放执行输出。

**风险：** CP 不计控制价值；不可仅靠面板判断强弱。
