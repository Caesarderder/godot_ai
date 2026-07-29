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

本表登记当前代码中的稳定角色原型。已实现玩家侧共 24 个（1 名开局指挥官、23 名可招募/研究角色）；
联盟侧按 `StageCatalog` 的
`enemy_archetype` 去重后共 20 个。左右路复制、同型 spawn、临时召唤物和建筑不单列角色。

公共计算口径见 [角色数值与培养规则](numeric-rules.md)。其中区分当前长期成长、兼容训练命令和
旧型号科技路径，禁止把互斥成本重复累加。

## 玩家阵营

以下CP均为无随机职业基准。所有角色等级上限Lv5；Lv1→5主路线统一为320战斗XP+420马桶币，
技能Lv1→3统一为12军团数据+240马桶币。

| 稳定 ID | 角色 | 评级 | 职责 | Lv1 CP（1/2/3★） | Lv5 CP（1/2/3★） | 满星碎片 | 生产材料价值 |
|---|---|---:|---|---|---|---:|---:|
| `gman` | [Gman 指挥官](player/gman.md) | B | 全线攻坚 | 1638/2049*/2460* | 2238/2821*/3414* | 当前不可正常获取 | 0 |
| `assault` | [冲锋马桶人](player/assault.md) | B | 前线突破 | 1724/2139/2574 | 2385/2996/3617 | 60 | 112 |
| `sonic` | [音波马桶人](player/sonic.md) | A | 群体控制 | 1644/2042/2460 | 2354/2960/3569 | 90 | 147 |
| `rocket` | [火箭飞行马桶人](player/rocket.md) | B | 远程攻城 | 1419/1736/2053 | 1815/2203/2621 | 60 | 200 |
| `bomber` | [自爆飞行马桶人](player/bomber.md) | A | 范围爆发 | 1419/1736/2053 | 1889/2300/2741 | 90 | 198 |
| `armored` | [装甲冲城马桶人](player/armored.md) | A | 承压反炮 | 1638/2049/2460 | 2337/2939/3564 | 90 | 256 |
| `saw` | [双锯重装马桶人](player/saw.md) | S | 精英斩杀 | 2294/2893/3502 | 3483/4438/5393 | 120 | 275 |
| `repair` | [维修马桶人](player/repair.md) | B | 续航救援 | 1638/2049/2460 | 2238/2821/3414 | 60 | 242 |
| `parasite` | [寄生母体马桶人](player/parasite.md) | S | 召唤策反 | 2168/2748/3338 | 3293/4196/5092 | 120 | 243 |

`*` Gman高星仅为公式投影。生产材料价值属于兼容生产队列，不是主研究获取的首次角色成本。

## 后续玩家角色（implemented）

以下 5 人均已复用当前职业、评级、四阵营、专属碎片和科技分支合同接入运行时；CP为公式投影，
技能行为有确定性测试，玩家偏好仍未由真人试玩证明。

| 稳定 ID | 角色 | 评级 | 分支 / 阵营 | 新战术动词 | Lv1 CP（1/2/3★） | 首次教学 |
|---|---|---:|---|---|---|---|
| `signal_purifier` | [信号净化马桶人](player/signal-purifier.md) | A | ordinary / 干扰增殖 | 净化 | 1644/2042/2460 | 3-2 |
| `anchor_bastion` | [锚桩堡垒马桶人](player/anchor-bastion.md) | B | heavy / 钢铁防线 | 锚定 | 1638/2049/2460 | 3-3 |
| `magnetic_conductor` | [磁轨牵引马桶人](player/magnetic-conductor.md) | A | flying / 远程轰炸 | 聚拢 | 1419/1736/2053 | 4-2 |
| `phase_tunneler` | [相位钻袭马桶人](player/phase-tunneler.md) | B | ordinary / 快攻破城 | 绕后 | 1724/2139/2574 | 4-3 |
| `protocol_weaver` | [协议编织母体](player/protocol-weaver.md) | S | special / 干扰增殖 | 夺取 | 2168/2748/3338 | 4-4 |

完整机器可校验规格位于 `docs/references/characters/specs/`。五人分别通过3-1、3-2、4-1、4-2、
4-3首通确定性获得图纸，也进入长期信号招募；其中原基础候选继续保留，后续追加角色按下节的一小时
阵营候选合同进入同一免费十连。

## 追加十名玩家角色（implemented）

十名角色均有独立技能Resource、战斗分支、专属碎片、科技树条目、长期招募和4–5章首通补领图纸。
B/A八人可在首章结束的同评级、跨阵营核心二选一出现，并随候选重复图纸立即获得2★所需碎片；
S两人只作为标准2%/保底信号惊喜，第二章主线不要求随机获得。
玩家偏好与长期阵容使用率仍为 `unknown`。

| ID | 角色 | 评级 | 分支 / 阵营 | 战术动词 | Lv1 CP（1/2/3★） | 一小时获取 / 后期补领 |
|---|---|---:|---|---|---|---|
| `ram_breaker` | [破盾撞角马桶人](player/ram-breaker.md) | B | ordinary / 快攻破城 | 碎盾 | 1724/2139/2574 | 阵营十连候选 / 4-4 |
| `smoke_screen` | [烟幕喷射马桶人](player/smoke-screen.md) | A | special / 干扰增殖 | 遮蔽 | 1644/2042/2460 | 阵营十连候选 / 4-5 |
| `mortar` | [曲射臼炮马桶人](player/mortar.md) | B | flying / 远程轰炸 | 曲射 | 1419/1736/2053 | 阵营十连候选 / 4-7 |
| `interceptor` | [预警截击马桶人](player/interceptor.md) | A | flying / 远程轰炸 | 截击 | 1419/1736/2053 | 阵营十连候选 / 4-8 |
| `bulwark` | [联结壁垒马桶人](player/bulwark.md) | B | heavy / 钢铁防线 | 联结 | 1638/2049/2460 | 阵营十连候选 / 4-10 |
| `crusher` | [液压粉碎马桶人](player/crusher.md) | A | heavy / 快攻破城 | 处决 | 1724/2139/2574 | 阵营十连候选 / 4-11 |
| `echo_mimic` | [回声拟态母体](player/echo-mimic.md) | S | special / 干扰增殖 | 回响 | 2168/2748/3338 | 标准信号惊喜 / 4-12 |
| `drain_engine` | [虹吸引擎马桶人](player/drain-engine.md) | A | heavy / 钢铁防线 | 虹吸 | 1638/2049/2460 | 阵营十连候选 / 5-3 |
| `swarm_beacon` | [群落信标马桶人](player/swarm-beacon.md) | B | special / 干扰增殖 | 诱饵 | 1644/2042/2460 | 阵营十连候选 / 5-6 |
| `chronolock` | [时序锁定母体](player/chronolock.md) | S | special / 干扰增殖 | 冻结 | 2168/2748/3338 | 标准信号惊喜 / 5-9 |

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

联盟没有等级与培养消耗。角色页按
`基础HP/攻/防 × enemy_power_bp`列出关卡实战值，并统计同型数量后的整组HP/攻击预算。第一章
Camera模板固定；第二章Boss倍率180%、第三章270%、第四章335%、第五章400%。射程、攻击周期和
移动不随倍率变化。

## 重要实现边界

`StageCatalog` 为上述敌军保留具体 `enemy_archetype`，但
`BattleSession._make_enemies()` 当前把运行时 `archetype_id` 统一写成 `alliance`。因此 Camera、
Speaker、TV 和联合模块主要由关卡配置驱动，而不是由单个敌军技能驱动。角色文档记录策划身份与
实际基础属性；在运行时透传稳定敌军 archetype 之前，不把关卡级机制伪称为单位独占技能。

## 维护规则

执行 `$toilet-char` 新增、优化、平衡、实现、重命名或移除角色时，必须同步该角色独立文档和本表；
完成后运行 `python3 tools/docs_lint.py`。
