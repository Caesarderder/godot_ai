---
km_id: reference.character-tech-tree-content-production
km_type: reference
domain: product
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - project-a/game/scripts/domain/progression/combat_power.gd
  - project-a/game/scripts/domain/recruitment/hero_generator.gd
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/content/faction_catalog.gd
  - project-a/game/scripts/domain/content/stage_catalog.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - .codex/skills/toilet-character-production/SKILL.md
validated_by:
  - python3 .codex/skills/toilet-character-production/scripts/character_design.py snapshot --project-root project-a
  - python3 .codex/skills/toilet-character-production/scripts/character_design.py validate --project-root project-a --spec .codex/skills/toilet-character-production/assets/magnetic-conductor.example.json
tags:
  - reference:character-production
  - reference:technology-tree
  - reference:stage-cadence
  - risk:content-repetition
related:
  - reference.post-30m-faction-progression
  - reference.objective-hurdle-reward-ladder
  - reference.game-contract
---

# 角色科技树与持续内容生产

## 结论

当前八名可招募角色已经覆盖突破、控场、攻城、爆发、承压、斩杀、维修和召唤八个战术动词；
B/A/S、专属碎片与 2★/3★质变的运行时基础成立。科技树此前存在三项玩家问题：

1. 同分支两个独立角色用箭头连接，错误暗示前置关系；
2. 节点只显示研发状态，不能支持阵营与升星规划；
3. 音波、自爆、装甲、维修的部分三星文案与真实战斗行为不一致。

本轮已把科技树改成“独立研发路线图”：每个节点同时显示评级、阵营、职责、完整 1★价值、
2★/3★质变、图纸来源和研发状态，并删除错误的前置箭头。文案以 `BattleSession` 真实行为为准。
第二章 Boss 首通后，研发说明会让位给抽取核心对应的阵营科技预览；该预览只承担长期目标承接，
明确标注第三章推进后开放且当前不增加战力，不伪装成已经可操作的常驻成长系统。

## 当前角色战力快照

标签：`derived`，使用无随机浮动的职业基准属性；技能价值不计入 CP。

| 角色 | 评级 | 职责 | 1★ | 2★ | 3★ |
|---|---|---|---:|---:|---:|
| 冲锋 | B | 突破 | 1724 | 2139 | 2574 |
| 音波 | A | 控场 | 1644 | 2042 | 2460 |
| 火箭 | B | 攻城 | 1419 | 1736 | 2053 |
| 自爆 | A | 爆发 | 1419 | 1736 | 2053 |
| 装甲 | A | 承压 | 1638 | 2049 | 2460 |
| 双锯 | S | 斩杀 | 2294 | 2893 | 3502 |
| 维修 | B | 续航 | 1638 | 2049 | 2460 |
| 寄生 | S | 召唤 | 2168 | 2748 | 3338 |

S 级 1★的基础 CP 已高于相同职业 B/A 2★基准，符合“一星即可上阵”的合同。控制、治疗、召唤、
目标覆盖、自损和操作窗口不进入 CP，必须用战斗事件与固定 seed 验证，不能靠隐藏战力补分。

## 关卡审查

当前 25 关具有单调递增推荐战力、章节 Boss 墙、章节机制、角色推荐和非付费回退路线。
首章具备明确的教学—失败—研究—编队—反攻—Boss 验证链。第 2–5 章主要复用同一敌人和结构
拓扑，通过章节周期机制、敌人家族、倍率和 Boss 参数形成差异。

因此当前证据能证明数值可达与关卡状态完整，不能证明长期内容足够丰富。继续制作时不得只追加
战力与血量；每章至少增加一个敌人动作、一个结构/危害交互、一个空间或时机变化和一个改变操作的
Boss 重组。

## 持续生产语法

每个新角色绑定一条七拍内容链：

`预告需求 → 暴露旧阵容短板 → 提供/预览角色 → 安全练习 → 组合验证 → 可选高光 → Boss 重组`

硬规则：

- 1★拥有完整可用技能，重复抽取不是修复残缺角色；
- 2★改变范围、时机、安全、位置或协同；
- 3★创造可复述的高光，而非只提高百分比；
- 关键关不能要求随机抽到指定角色；
- Boss 至少保留一条现有角色替代路线；
- 解锁必须早于教学和推荐；
- 奖励应在后续两关内得到验证；
- 自动测试只证明规则，真人盲测才能证明理解与喜欢。

仓库 Skill：`.codex/skills/toilet-character-production/`。它会从当前代码抽取角色 CP、阵营、升星和
25 关推荐曲线，验证新角色规格，并输出实现与关卡投放合同。

## 示例试产

示例“A级磁轨牵引马桶人”使用“聚拢”作为新战术动词：

- 1★牵引至多两名分散守军，制造范围爆发窗口；
- 2★扩展为当前阶段群体聚拢与可引爆标记；
- 3★首名标记目标倒下时触发坍缩并返还能量；
- 对 Boss 和固定结构不能直接牵引，避免成为万能解；
- 音波可作为控场替代，火箭可作为远程清场替代，装甲/维修可作为 Boss 稳定替代。

基准 CP 为 `1419 / 1736 / 2053`；规格已通过 Skill 校验。技能实战价值与玩家喜爱度仍分别是
`target` 和 `unknown`，只有实现后的固定 seed 对照与无引导试玩才能升级证据等级。
