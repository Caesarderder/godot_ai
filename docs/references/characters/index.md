---
km_id: reference.character-roster-index
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/content/faction_catalog.gd
  - project-a/game/scripts/domain/content/stage_catalog.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - command:python3 .codex/skills/toilet-character-production/scripts/character_design.py snapshot --project-root project-a
  - python3 tools/docs_lint.py
tags:
  - reference:character-roster
  - domain:hero-formation
related:
  - reference.character-tech-tree-content-production
---

# 角色表与知识地图索引

本表只登记当前代码中的稳定角色原型。玩家侧共 9 个（1 名开局指挥官、8 名可招募/研究角色）；
联盟侧按 `StageCatalog` 的 `enemy_archetype` 去重后共 20 个。左右路复制、同型 spawn、临时召唤物
和建筑不单列角色。

## 玩家阵营

| 稳定 ID | 角色 | 评级 | 阵营 | 职责 | 证据 |
|---|---|---:|---|---|---|
| `gman` | [Gman 指挥官](player/gman.md) | B | 钢铁防线 | 全线攻坚/开局统帅 | implemented |
| `assault` | [冲锋马桶人](player/assault.md) | B | 快攻破城 | 前线突破 | implemented |
| `sonic` | [音波马桶人](player/sonic.md) | A | 干扰增殖 | 群体控制 | implemented |
| `rocket` | [火箭飞行马桶人](player/rocket.md) | B | 远程轰炸 | 远程攻城 | implemented |
| `bomber` | [自爆飞行马桶人](player/bomber.md) | A | 远程轰炸 | 范围爆发 | implemented |
| `armored` | [装甲冲城马桶人](player/armored.md) | A | 钢铁防线 | 承压反炮 | implemented |
| `saw` | [双锯重装马桶人](player/saw.md) | S | 快攻破城 | 精英斩杀 | implemented |
| `repair` | [维修马桶人](player/repair.md) | B | 钢铁防线 | 续航救援 | implemented |
| `parasite` | [寄生母体马桶人](player/parasite.md) | S | 干扰增殖 | 召唤策反 | implemented |

## 联盟敌军

| 稳定 archetype | 角色 | 家族/章节 | 战术职责 | 证据 |
|---|---|---|---|---|
| `camera_sentry` | [远程摄像警卫](alliance/camera-sentry.md) | Camera / 1-2 | 首次远程警戒 | implemented |
| `camera_trooper` | [联盟摄像兵](alliance/camera-trooper.md) | Camera / 1-3 | 交叉火力 | implemented |
| `camera_field_captain` | [联盟临时队长](alliance/camera-field-captain.md) | Camera / 1-3 | 首次精英承压 | implemented |
| `camera_grunt` | [Camera 基础兵](alliance/camera-grunt.md) | Camera / 第一章 | 近距推进 | implemented |
| `camera_support` | [Camera 射手](alliance/camera-support.md) | Camera / 第一章 | 侧翼远程 | implemented |
| `camera_elite` | [摄像盾卫](alliance/camera-elite.md) | Camera / 第一章 | 中线精英 | implemented |
| `camera_overseer` | [摄像监军](alliance/camera-overseer.md) | Camera / 第一章 | 后线高伤精英 | implemented |
| `speaker_grunt` | [联盟音箱兵](alliance/speaker-grunt.md) | Speaker / 第二章 | 近距节奏压力 | implemented |
| `speaker_support` | [音箱射手](alliance/speaker-support.md) | Speaker / 第二章 | 远程声波支援 | implemented |
| `speaker_elite` | [大型音箱兵](alliance/speaker-elite.md) | Speaker / 第二章 | 高耐久精英 | implemented |
| `speaker_overseer` | [大型音箱监军](alliance/speaker-overseer.md) | Speaker / 第二章 | 后线能量干扰主题 | implemented |
| `tv_grunt` | [电视特工](alliance/tv-grunt.md) | TV / 第三章 | 基础信号干扰 | implemented |
| `tv_support` | [电视特工射手](alliance/tv-support.md) | TV / 第三章 | 远程目标扰乱 | implemented |
| `tv_elite` | [电视监军](alliance/tv-elite.md) | TV / 第三章 | 传送/护盾主题精英 | implemented |
| `tv_overseer` | [电视监军高阶型](alliance/tv-overseer.md) | TV / 第三章 | 后线控制主题 | implemented |
| `alliance_grunt` | [联盟联合兵](alliance/alliance-grunt.md) | 联合 / 四至五章 | 混编基础线 | implemented |
| `alliance_support` | [联盟联合射手](alliance/alliance-support.md) | 联合 / 四至五章 | 远程混编 | implemented |
| `alliance_elite` | [联合核心近卫](alliance/alliance-elite.md) | 联合 / 四至五章 | 高耐久精英 | implemented |
| `alliance_overseer` | [联合核心监军](alliance/alliance-overseer.md) | 联合 / 四至五章 | 模块轮换承载 | implemented |
| `core_guard` | [核心近卫](alliance/core-guard.md) | 全章节 | 核心前最终门卫 | implemented |

## 重要实现边界

`StageCatalog` 为上述敌军保留具体 `enemy_archetype`，但
`BattleSession._make_enemies()` 当前把运行时 `archetype_id` 统一写成 `alliance`。因此 Camera、
Speaker、TV 和联合模块主要由关卡配置驱动，而不是由单个敌军技能驱动。角色文档记录策划身份与
实际基础属性；在运行时透传稳定敌军 archetype 之前，不把关卡级机制伪称为单位独占技能。

## 维护规则

执行 `$toilet-char` 新增、优化、平衡、实现、重命名或移除角色时，必须同步该角色独立文档和本表；
完成后运行 `python3 tools/docs_lint.py`。
