---
km_id: domain.battle-progression
km_type: domain
domain: battle-progression
status: active
owner: gameplay
last_verified: 2026-07-25
source_of_truth:
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/domain/content/stage_catalog.gd
  - project-a/game/scripts/presentation_3d/battle_world.gd
  - project-a/scripts/main.gd
  - project-a/tools/run_battle_tests.gd
  - project-a/tools/run_campaign_tests.gd
  - project-a/tools/run_ui_smoke_tests.gd
  - project-a/tools/run_presentation_tests.gd
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
validated_by:
  - godot --headless --path project-a -s tools/run_battle_tests.gd
  - godot --headless --path project-a -s tools/run_campaign_tests.gd
  - godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
  - godot --headless --path project-a -s tools/run_presentation_tests.gd
tags:
  - domain:battle-progression
  - risk:determinism
related:
  - domain.hero-formation
  - reference.architecture-overview
  - reference.verification-matrix
  - reference.skibidi-toilet-idle-siege-gdd
  - reference.earth-skibidi-act1-campaign
---

# 战斗与关卡推进领域

> 当前 Godot 版本已实现第一幕五章二十五关的六人三阶段 3D 攻城：独立 5Hz `BattleSession`、数据化敌人/结构/奖励/解锁、章节机制、八原型技能、章节 Boss、可压制核心巨炮、程序化 3D 战争投影和一次性持久结算。跨帧率 digest、paired 1000、Web 真机性能与长期平衡仍未完成。

## 目标

用低频、可复现的自动战斗承载“先失败 -> 理解差异 -> 调整 -> 再胜”。

## 什么时候读

实现战斗状态、目标选择、技能、关卡、战斗回放、平衡模拟或结算时。

## 职责

- 5Hz 固定逻辑 tick；画面是战斗状态的投影，可丢动画，不丢逻辑 tick。
- 战斗当前不依赖全局随机；核心状态由 5Hz tick、单位数组、结构数组、技能请求和炮击预警队列驱动。
- `BattleSession/BattleState` 是临时状态；只有不可变 `BattleResult` 可进入持久结算。
- `StageCatalog` 定义 `stage_1_1` 至 `stage_5_5`；胜利由摧毁当前关卡的最终结构触发，失败由主力全灭或关卡时限耗尽触发。
- 可压制核心巨炮只在章节 Boss 关启用，即 `stage_in_chapter == 5` 且战斗进入最终基地阶段时生效；普通关仍保留不可压制的传统 `artillery_warning`→`artillery_impact` 炮击语义。
- Boss 巨炮预警窗口为 `20` ticks；按 5Hz 战斗逻辑约等于 `4` 秒。窗口内只累计对当前基地阶段结构造成的实际伤害，达到本章 `cannon_suppression_target` 后发送 `cannon_suppressed` 并取消该次炮击；未达标则保留 `artillery_impact`。
- 当前五章 Boss 压制目标为 `70/85/100/115/130`，分别对应第一至第五章；这些是待人工平衡验证的首轮数值，不得宣称已证明节奏好玩或长期平衡成立。
- 巨炮压制不新增战斗操作按钮；玩家仍只管理自动技能开关或在自动关闭时点击头像施法。压制系统也不新增货币、奖励、存档字段、任务或成就。
- HUD 暴露巨炮压制进度、剩余时间与待机状态；结算页显示本局压制次数和炮击命中次数，用于解释输出竞速结果，而不是发放额外奖励。
- 每关必须同时提供威胁摘要、反制提示、章节反馈和解锁预览；出征前展示这些信息，失败结果将领域失败原因与当前可执行成长动作合并，胜利结果预告下一关威胁。
- 战术战报属于战斗结果解释层：它把 `BattleResult`、关卡提示、玩家当前可执行成长动作合并成一条建议，但不能成为奖励事实源、任务进度源或隐藏结算入口。
- 联盟残骸免费兑换属于首版经济扩展合同：残骸只从首次胜利发放，普通关 `5`、章节 Boss `15`，兑换固定跟随 `SalvageCatalog` 的瓷片补给 `8→瓷片40`、混合零件 `12→零件28+污泥20`、训练补给 `15→金币120+训练书2`；这些数值为未真人验证假设。残骸不得来自付费、本地伪支付、强制广告或概率抽卡，也不得提前解锁蓝图；蓝图补给和生产加速券仅可作为延期候选重新评审。
- 战役任务可以消费战斗结算事件，但不能反向改变战斗胜负、关卡解锁或蓝图解锁。第一幕合同为 25 个大战役任务对应 25 关首次胜利；普通关奖励假设为大战功 `60` + 金币 `20`，Boss 奖励假设为大战功 `160` + 金币 `50` + 训练书 `1`，全部数值未真人验证。
- Node3D、动画、物理、导航和 VFX 只投影 `BattleState` 与 presentation events，不参与逻辑判定。
- 主要游玩场景是手机浏览器横屏；六名主力沿一条宽阔城市大道自动移动、索敌和攻击，依次突破城市外围、火力封锁区和联盟基地广场。
- 玩家在战斗中不移动角色、不选敌方目标、不标记集火、不控制镜头；唯一即时输入是设置自动技能，或关闭自动后点击角色头像施法。
- 自动技能默认关闭，由玩家主动开启；技能目标由确定性战斗规则自动选择。
- 自动技能偏好按永久英雄实例持久化，跨战斗和存档读取保持；战斗快照只读取该偏好，不把临时能量写回存档。
- 三层目标拥有硬门控：当前阶段先清联盟守军/精英，再攻击设施；基地广场必须依次击破左右电池、核心外甲和联盟核心，范围技能不能提前穿透外甲伤核。
- 五章结构 Boss 依次是灰镜核心巨炮、共振堡垒核心、黑屏中继塔、三联军械库核心和审判之门；它们共享“最终基地阶段可压制核心巨炮”的输出竞速压力，共振压制、屏幕控制和模块护盾从第二章起叠加战场差异。
- 视觉层采用阴沉白天逐步转入黄昏战火的风格化写实战争质感；建筑使用完整、重度受损、摧毁三段预制状态，远景爆炸和短时物理碎片只制造表现，不参与伤害与胜负判定。
- 逻辑仍采用低频确定性 tick；持续轰炸的密度、烟火、镜头震动和连续坍塌属于高频表现节奏，不能反向改变 `BattleState`。
- 长期主线先由地球 Skibidi 攻打 Alliance；联盟反攻摧毁旧工厂后进入移动工厂重建，Astro 入侵后主线转为地球军团抵抗外星势力和保护临时盟友。
- Astro 可玩内容在地球主线通关后作为独立征服战役解锁，不在中途替换玩家已有阵容；当前发行候选只实现地球战争第一幕。
- `stage_5_5` 结算触发“联盟反推、旧工厂遭袭、移动工厂撤离”的幕末剧情钩子，不清空永久角色、星级、蓝图或资源。

## 不是本层职责

不绕过 GameState 写持久值、不直接发任务奖励、不持有 UI Widget 作为持久真值；不实现 P2W、强制广告、概率抽卡、本地伪支付、每日/周常/FOMO、付费任务轨、广告刷新任务、蓝图任务奖励、战力倍率或任何会跳过攻城主循环的商业化入口。

## 不变量

相同六人快照必须得到相同结果；全局随机函数禁止进入领域战斗。后续补跨帧率 digest 前，不得声称战斗已通过完整确定性门禁。

## 入口

[CODE:battle-session](../../project-a/game/scripts/domain/battle/battle_session.gd)、[CODE:battle-world](../../project-a/game/scripts/presentation_3d/battle_world.gd)、[KM:reference.skibidi-toilet-idle-siege-gdd](../references/product-design/skibidi-toilet-idle-siege-gdd.md)。

## 验证

`run_battle_tests.gd` 覆盖三阶段、硬门控、技能、星级机制、巨炮、Boss 巨炮压制窗口、高输出压制、低输出命中、普通关无压制、结构事件、同输入同结果与超时；`run_campaign_tests.gd` 验证 25 关链、章节 Boss 才启用可压制巨炮、20 tick 预警窗口、五章压制目标 `70/85/100/115/130`、关卡数据与可读字段完整性、关键蓝图预览、三星期望阵容全通与一星阵容不能越过 5-5；`run_ui_smoke_tests.gd` 验证新档行动卡、任务正式 schema、战术战报标签、首胜残骸反馈、巨炮压制 HUD、结算压制/命中次数、无新增巨炮操作按钮、三项回收入口和 CTA 不改变 revision；`run_presentation_tests.gd` 验证 `cannon_suppressed` 反馈和低/减少动态预算。`run_meta_tests.gd` 已覆盖联盟残骸与任务战功：25 首胜任务、3 槽循环 generation、完成/领取分离、幂等流水、奖励篡改拒绝、30 级后累计战功继续但无无限战力。后续补真人任务理解与长期留存、hash/tie-break golden、30/60/120 FPS digest、禁用 3D 投影后的相同 digest、同一 manifest 的 paired 1000 与真人长期平衡。

## 相关节点

[KM:reference.first-30m-contract](../references/constraints/first-30m-contract.md)。
