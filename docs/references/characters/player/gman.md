---
km_id: reference.character-player-gman
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - project-a/game/scripts/domain/factory/factory_catalog.gd
  - project-a/game/scripts/domain/recruitment/hero_generator.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/resources/definitions/skills/active/gman_overrun.tres
validated_by:
  - project-a/tools/run_battle_tests.gd
  - python3 tools/docs_lint.py
tags:
  - reference:character-profile
  - domain:hero-formation
related:
  - reference.character-roster-index
---

# Gman 指挥官

| 字段 | 当前事实 |
|---|---|
| 稳定 ID | `gman` |
| 获取/评级 | 开局唯一永久角色；B |
| 职业/阵营 | `guardian`；钢铁防线 |
| 职责 | 全线攻坚、开局教学、短时自保 |
| 主动技能 | `gman_overrun` 统帅碾压 |
| 科技树 | 阵营成员，但不是工厂配方节点 |

## 等级与战力（derived，职业基准）

| Lv | 基础HP | 基础攻 | 基础防 | 速度 | 暴击 | 1★CP | 2★CP* | 3★CP* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 190 | 21 | 40 | 84000 | 8.00% | 1638 | 2049 | 2460 |
| 2 | 210 | 23 | 44 | 85600 | 8.20% | 1783 | 2222 | 2681 |
| 3 | 230 | 25 | 48 | 87200 | 8.40% | 1928 | 2415 | 2922 |
| 4 | 250 | 28 | 52 | 88800 | 8.60% | 2093 | 2628 | 3173 |
| 5 | 270 | 30 | 56 | 90400 | 8.80% | 2238 | 2821 | 3414 |

`*` 2★/3★只是公式投影；当前Gman没有正常碎片升星来源。Lv1→5的1★实际战斗属性从
`190/21/40`成长为`270/30/56`。射程110；移动8→8/tick；攻击周期6→6 tick；无额外回能时约
30 tick（6秒）形成一次技能。真实实例受seed属性浮动，区间规则见公共数值页。

## 培养成本（implemented）

| 项目 | 当前成本 |
|---|---|
| 获取/生产 | 开局免费；无图纸、无生产材料 |
| Lv1→5主路线 | 320战斗XP + 420马桶币；约11场胜利达到经验上限 |
| 兼容经验书路线 | 16经验书 + 900旧金币；不再另加420马桶币 |
| 主动技能Lv1→3 | 12军团数据 + 240马桶币 |
| 当前可达总投入 | 660马桶币 + 12军团数据；星级不计 |

完整公式见 [角色数值与培养规则](../numeric-rules.md)。

**战斗合同（implemented）：** 技能伤害当前阶段全部敌人与结构并获得 80 点、20 tick 护盾；首次
施放可读取关卡开场倍率，后续回到基础倍率。前三关承担单人教学，1-4 之后让位给编队与成长。

**玩家承诺：** 防线集中出现时，用全线碾压一次打开推进窗口。与火箭的区别是覆盖敌人与结构且
兼具护盾；与装甲的区别是主攻而非长期承炮。

**表现与验证：** 巨型指挥官轮廓、整段冲击和护盾必须同时可读。验证首发强化只触发一次、阶段
目标覆盖、护盾持续时间、1-1 至 1-3 单人链，以及 844×390 技能说明。

## 优化分析

- **当前效率：** Lv1→5增加600 CP，约1.43 CP/马桶币（只按显式升级420币）；技能升级不增加CP。
- **目标预算：** 前三关保持统帅压制，1-4以后不应同时替代坦克、清线与攻城专职。
- **过强信号：** 进入第二章后仍只带Gman即可稳定越推荐战力通关，或全线技能压过同投入火箭。
- **过弱信号：** 1-3前玩家必须额外培养或首次技能仍无法明显推进阶段。
- **首选杠杆：** 先调首次倍率/护盾时长，不改职业成长；回滚阈值为前三关任一基线固定seed失去
  单人可通性。

**风险/未知：** 快照工具不把 Gman 纳入八名可招募角色 CP 表；玩家偏好仍为unknown。
