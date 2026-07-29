---
km_id: reference.character-roster-index
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-29
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

本表登记当前代码中的稳定角色原型。已实现玩家侧共 24 个（1 名开局指挥官、23 名可招募/研究角色）；
联盟侧按 `StageCatalog` 的
`enemy_archetype` 去重后共 20 个。左右路复制、同型 spawn、临时召唤物和建筑不单列角色。

公共计算口径见 [角色数值与培养规则](numeric-rules.md)。其中区分当前长期成长、兼容训练命令和
旧型号科技路径，禁止把互斥成本重复累加。

## 玩家阵营

以下战力均为无随机职业基准。所有角色等级上限 5 级；1→5 级主路线统一为 320 战斗经验加 420 马桶币，
技能 1→3 级统一为 12 军团数据加 240 马桶币。

| 稳定 ID | 角色 | 评级 | 职责 | 1级战力（1/2/3★） | 5级战力（1/2/3★） | 满星碎片 | 生产材料价值 |
|---|---|---:|---|---|---|---:|---:|
| `gman` | [Gman](player/gman.md) | B | 全线攻坚 | 1638/2049*/2460* | 2238/2821*/3414* | 当前不可正常获取 | 0 |
| `assault` | [普通马桶人](player/assault.md) | B | 前线突破 | 1724/2139/2574 | 2385/2996/3617 | 60 | 112 |
| `sonic` | [故障闪电马桶人](player/sonic.md) | A | 群体控制（玩法改编） | 1644/2042/2460 | 2354/2960/3569 | 90 | 147 |
| `rocket` | [飞行四发射器马桶人](player/rocket.md) | B | 远程攻城 | 1419/1736/2053 | 1815/2203/2621 | 60 | 200 |
| `bomber` | [炸弹桶马桶人](player/bomber.md) | A | 范围爆发 | 1419/1736/2053 | 1889/2300/2741 | 90 | 198 |
| `armored` | [激光火箭筒马桶人](player/armored.md) | A | 承压反炮 | 1638/2049/2460 | 2337/2939/3564 | 90 | 256 |
| `saw` | [飞行双圆锯马桶人](player/saw.md) | S | 精英斩杀 | 2294/2893/3502 | 3483/4438/5393 | 120 | 275 |
| `repair` | [研究员马桶人](player/repair.md) | B | 续航救援（玩法改编） | 1638/2049*/2460* | 2238/2821*/3414* | 60 | 242 |
| `parasite` | [大型寄生虫马桶人](player/parasite.md) | S | 召唤策反 | 2168/2748/3338 | 3293/4196/5092 | 120 | 243 |

`*` Gman高星仅为公式投影。生产材料价值属于兼容生产队列，不是主研究获取的首次角色成本。

## 后续玩家角色（implemented）

以下 15 人均已复用当前职业、评级、四阵营、专属碎片和科技分支合同接入运行时；CP为公式投影，
技能行为有确定性测试，玩家偏好仍未由真人试玩证明。

| 稳定 ID | 角色 | 评级 | 分支 / 阵营 | 新战术动词 | 1级战力（1/2/3★） | 首次教学 |
|---|---|---:|---|---|---|---|
| `signal_purifier` | [钢爪马桶人科学家](player/signal-purifier.md) | A | 普通 / 干扰增殖 | 净化（玩法改编） | 1644/2042/2460 | 3-2 |
| `anchor_bastion` | [巨型飞行马桶人](player/anchor-bastion.md) | B | 重装 / 钢铁防线 | 锚定（玩法改编） | 1638/2049/2460 | 3-3 |
| `magnetic_conductor` | [冲击波直升机马桶人](player/magnetic-conductor.md) | A | 飞行 / 远程轰炸 | 聚拢（玩法改编） | 1419/1736/2053 | 4-2 |
| `phase_tunneler` | [武士刀蜘蛛马桶人](player/phase-tunneler.md) | B | 普通 / 快攻破城 | 绕后（玩法改编） | 1724/2139/2574 | 4-3 |
| `protocol_weaver` | [寄生虫马桶人](player/protocol-weaver.md) | S | 特殊 / 干扰增殖 | 夺取（玩法改编） | 2168/2748/3338 | 4-4 |
| `ram_breaker` | [喷气背包钢爪马桶人](player/ram-breaker.md) | B | 普通 / 快攻破城 | 破盾（玩法改编） | 1724/2139/2574 | 信号招募 |
| `smoke_screen` | [硫酸桶马桶人](player/smoke-screen.md) | A | 特殊 / 干扰增殖 | 烟幕（玩法改编） | 1644/2042/2460 | 4-4 |
| `mortar` | [喷气背包六发射器马桶人](player/mortar.md) | B | 飞行 / 远程轰炸 | 曲射（玩法改编） | 1419/1736/2053 | 信号招募 |
| `interceptor` | [直升机马桶人](player/interceptor.md) | A | 飞行 / 远程轰炸 | 截击（玩法改编） | 1419/1736/2053 | 4-5 |
| `bulwark` | [多头马桶人](player/bulwark.md) | B | 重装 / 钢铁防线 | 联结（玩法改编） | 1638/2049/2460 | 5-1 |
| `crusher` | [圆锯突变马桶人](player/crusher.md) | A | 重装 / 快攻破城 | 处决（玩法改编） | 1724/2139/2574 | 5-1 |
| `echo_mimic` | [DJ马桶人](player/echo-mimic.md) | S | 特殊 / 干扰增殖 | 回响（玩法改编） | 2168/2748/3338 | 5-2 |
| `drain_engine` | [吸尘小便池人](player/drain-engine.md) | A | 重装 / 钢铁防线 | 充能（玩法改编） | 1638/2049/2460 | 5-2 |
| `swarm_beacon` | [直升机寄生虫马桶人](player/swarm-beacon.md) | B | 特殊 / 干扰增殖 | 诱饵（玩法改编） | 1644/2042/2460 | 5-3 |
| `chronolock` | [硫酸骷髅马桶人](player/chronolock.md) | S | 特殊 / 干扰增殖 | 冻结（玩法改编） | 2168/2748/3338 | 5-4 |

完整机器可校验规格位于 `docs/references/characters/specs/`。首章免费阵营十连继续只使用原基础候选，
避免提前打乱教学。每个稳定原型最多创建一名永久角色；重复图纸转为其专属碎片，不再用同一个族群名
包装多个不同技能。中文名称来自社区 Wiki 的整理条目，不能当作官方命名；超出页面明示能力的战斗效果
统一标记“玩法改编”，内部 ID 保持不变以兼容存档。

## 联盟敌军

| 稳定 archetype | 角色 | 家族/章节 | 战术职责 | 证据 |
|---|---|---|---|---|
| `camera_sentry` | [远程摄像警卫](alliance/camera-sentry.md) | 监控人 / 1-2 | 首次远程警戒 | 已实现 |
| `camera_trooper` | [联盟摄像兵](alliance/camera-trooper.md) | 监控人 / 1-3 | 交叉火力 | 已实现 |
| `camera_field_captain` | [联盟临时队长](alliance/camera-field-captain.md) | 监控人 / 1-3 | 首次精英承压 | 已实现 |
| `camera_grunt` | [监控人基础兵](alliance/camera-grunt.md) | 监控人 / 第一章 | 近距推进 | 已实现 |
| `camera_support` | [监控人射手](alliance/camera-support.md) | 监控人 / 第一章 | 侧翼远程 | 已实现 |
| `camera_elite` | [摄像盾卫](alliance/camera-elite.md) | 监控人 / 第一章 | 中线精英 | 已实现 |
| `camera_overseer` | [摄像监军](alliance/camera-overseer.md) | 监控人 / 第一章 | 后线高伤精英 | 已实现 |
| `speaker_grunt` | [联盟音箱兵](alliance/speaker-grunt.md) | 音响人 / 第二章 | 近距节奏压力 | 已实现 |
| `speaker_support` | [音箱射手](alliance/speaker-support.md) | 音响人 / 第二章 | 远程声波支援 | 已实现 |
| `speaker_elite` | [大型音箱兵](alliance/speaker-elite.md) | 音响人 / 第二章 | 高耐久精英 | 已实现 |
| `speaker_overseer` | [大型音箱监军](alliance/speaker-overseer.md) | 音响人 / 第二章 | 后线能量干扰主题 | 已实现 |
| `tv_grunt` | [电视特工](alliance/tv-grunt.md) | 电视人 / 第三章 | 基础信号干扰 | 已实现 |
| `tv_support` | [电视特工射手](alliance/tv-support.md) | 电视人 / 第三章 | 远程目标扰乱 | 已实现 |
| `tv_elite` | [电视监军](alliance/tv-elite.md) | 电视人 / 第三章 | 传送/护盾主题精英 | 已实现 |
| `tv_overseer` | [电视监军高阶型](alliance/tv-overseer.md) | 电视人 / 第三章 | 后线控制主题 | 已实现 |
| `alliance_grunt` | [联盟联合兵](alliance/alliance-grunt.md) | 联合 / 四至五章 | 混编基础线 | 已实现 |
| `alliance_support` | [联盟联合射手](alliance/alliance-support.md) | 联合 / 四至五章 | 远程混编 | 已实现 |
| `alliance_elite` | [联合核心近卫](alliance/alliance-elite.md) | 联合 / 四至五章 | 高耐久精英 | 已实现 |
| `alliance_overseer` | [联合核心监军](alliance/alliance-overseer.md) | 联合 / 四至五章 | 模块轮换承载 | 已实现 |
| `core_guard` | [核心近卫](alliance/core-guard.md) | 全章节 | 核心前最终门卫 | 已实现 |

联盟没有等级与培养消耗。角色页按
`基础HP/攻/防 × enemy_power_bp`列出关卡实战值，并统计同型数量后的整组HP/攻击预算。第一章
监控人模板固定；第二章首领倍率 180%、第三章 270%、第四章 335%、第五章 400%。射程、攻击周期和
移动不随倍率变化。

## 重要实现边界

`StageCatalog` 为上述敌军保留具体 `enemy_archetype`，但
`BattleSession._make_enemies()` 当前把运行时 `archetype_id` 统一写成 `alliance`。因此监控人、
音响人、电视人和联合模块主要由关卡配置驱动，而不是由单个敌军技能驱动。角色文档记录策划身份与
实际基础属性；在运行时透传稳定敌军 archetype 之前，不把关卡级机制伪称为单位独占技能。

## 维护规则

执行 `$toilet-char` 新增、优化、平衡、实现、重命名或移除角色时，必须同步该角色独立文档和本表；
完成后运行 `python3 tools/docs_lint.py`。
