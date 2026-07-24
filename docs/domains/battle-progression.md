---
km_id: domain.battle-progression
km_type: domain
domain: battle-progression
status: active
owner: gameplay
last_verified: 2026-07-24
source_of_truth:
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/presentation_3d/battle_world.gd
  - project-a/scripts/main.gd
  - project-a/tools/run_battle_tests.gd
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
validated_by:
  - godot --headless --path project-a -s tools/run_battle_tests.gd
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

> 当前 Godot 版本已实现六人三阶段 3D 攻城：独立 5Hz `BattleSession`、自动推进、联盟普通守军与精英、7 个结构目标、八原型 canonical 技能、星级技能质变、核心巨炮预警/落点、程序化 3D 投影和一次性持久结算。跨帧率 digest、paired 1000、Web 真机性能与长期章节平衡仍未完成。

## 目标

用低频、可复现的自动战斗承载“先失败 -> 理解差异 -> 调整 -> 再胜”。

## 什么时候读

实现战斗状态、目标选择、技能、关卡、战斗回放、平衡模拟或结算时。

## 职责

- 5Hz 固定逻辑 tick；画面是战斗状态的投影，可丢动画，不丢逻辑 tick。
- 战斗当前不依赖全局随机；核心状态由 5Hz tick、单位数组、结构数组、技能请求和炮击预警队列驱动。
- `BattleSession/BattleState` 是临时状态；只有不可变 `BattleResult` 可进入持久结算。
- 当前切片使用一场 `stage_1_1` 攻城；胜利由摧毁 `alliance_core` 触发，失败由主力全灭或 300 tick 超时触发。
- Node3D、动画、物理、导航和 VFX 只投影 `BattleState` 与 presentation events，不参与逻辑判定。
- 主要游玩场景是手机浏览器横屏；六名主力沿一条宽阔城市大道自动移动、索敌和攻击，依次突破城市外围、火力封锁区和联盟基地广场。
- 玩家在战斗中不移动角色、不选敌方目标、不标记集火、不控制镜头；唯一即时输入是设置自动技能，或关闭自动后点击角色头像施法。
- 自动技能默认关闭，由玩家主动开启；技能目标由确定性战斗规则自动选择。
- 自动技能偏好按永久英雄实例持久化，跨战斗和存档读取保持；战斗快照只读取该偏好，不把临时能量写回存档。
- 三层目标拥有硬门控：当前阶段先清联盟守军/精英，再攻击设施；基地广场必须依次击破左右电池、核心外甲和联盟核心，范围技能不能提前穿透外甲伤核。
- 第一章 Boss 是与联盟基地融为一体的核心巨炮。它持续轰炸全场并随阶段提高压力，玩家依靠阵容承压与输出效率在主力全灭或超时前摧毁基地。
- 视觉层采用阴沉白天逐步转入黄昏战火的风格化写实战争质感；建筑使用完整、重度受损、摧毁三段预制状态，远景爆炸和短时物理碎片只制造表现，不参与伤害与胜负判定。
- 逻辑仍采用低频确定性 tick；持续轰炸的密度、烟火、镜头震动和连续坍塌属于高频表现节奏，不能反向改变 `BattleState`。
- 长期主线先由地球 Skibidi 攻打 Alliance；联盟反攻摧毁旧工厂后进入移动工厂重建，Astro 入侵后主线转为地球军团抵抗外星势力和保护临时盟友。
- Astro 可玩内容在地球主线通关后作为独立征服战役解锁，不在中途替换玩家已有阵容；当前 `stage_1_1` 不包含这些长期章节。
- 第一幕目标结构是五章二十五关；当前 `stage_1_1` 是混合三族敌人的纵向切片，正式内容化时应作为第一章 Boss 模板，而不是继续充当最终教学关。

## 不是本层职责

不绕过 GameState 写持久值、不发任务奖励、不持有 UI Widget 作为持久真值。

## 不变量

相同六人快照必须得到相同结果；全局随机函数禁止进入领域战斗。后续补跨帧率 digest 前，不得声称战斗已通过完整确定性门禁。

## 入口

[CODE:battle-session](../../project-a/game/scripts/domain/battle/battle_session.gd)、[CODE:battle-world](../../project-a/game/scripts/presentation_3d/battle_world.gd)、[KM:reference.skibidi-toilet-idle-siege-gdd](../references/product-design/skibidi-toilet-idle-siege-gdd.md)。

## 验证

`tools/run_battle_tests.gd` 当前覆盖：必须传入 6 人、未知原型拒绝、强六人队完成三阶段攻城、普通守军接战、精英击破、阶段切换、7 个结构目标摧毁、左右电池/核心外甲/核心不可越层伤害、手动与自动技能、八原型 canonical 技能、冲锋/火箭/寄生的星级机制变化与装甲护盾 tier、核心巨炮预警/命中、结构损伤事件、同一快照同结果、超时语义。后续继续补其余四原型的逐技能机制回归、hash/tie-break golden、30/60/120 FPS digest、禁用 3D 投影后的相同 digest、同一 manifest 的 paired 1000 与绝对胜率区间。

## 相关节点

[KM:reference.first-30m-contract](../references/constraints/first-30m-contract.md)。
