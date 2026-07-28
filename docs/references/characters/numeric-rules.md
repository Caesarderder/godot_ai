---
km_id: reference.character-numeric-rules
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - project-a/game/scripts/domain/progression/hero_progression.gd
  - project-a/game/scripts/domain/progression/combat_power.gd
  - project-a/game/scripts/domain/factory/logistics_service.gd
  - project-a/game/scripts/domain/economy/economy_valuation.gd
  - project-a/game/scripts/domain/content/stage_catalog.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - project-a/tools/run_balance_tests.gd
  - project-a/tools/run_battle_tests.gd
  - python3 tools/docs_lint.py
tags:
  - reference:character-production
  - domain:hero-formation
related:
  - reference.character-roster-index
  - reference.character-tech-tree-content-production
---

# 角色数值与培养规则

本页是每个角色文档的公共计算口径。角色页必须仍提供该角色自己的逐级数值、成本和调优结论。

## 等级与经验

| 等级 | 累计经验阈值 | 从上一级新增经验 | 从0累计经验书 | 显式升级金币 |
|---:|---:|---:|---:|---:|
| 1 | 0 | — | 0 | 0 |
| 2 | 40 | 40 | 2 | 60马桶币 |
| 3 | 100 | 60 | 5 | 90马桶币 |
| 4 | 200 | 100 | 10 | 120马桶币 |
| 5 | 320 | 120 | 16 | 150马桶币 |

- 战斗结算：胜利每名参战永久角色 +30 XP，失败 +8 XP，上限320。
- 显式升级路线：达到阈值后逐级升级，Lv1→5合计420马桶币。
- 兼容训练路线：16本经验书直接把0 XP角色训练至Lv5，同时按当前等级逐本扣旧 `gold`，合计900
  旧金币。它与显式升级是两条实现路径，不能写成总计1320。
- 当前产品边界不把旧 `gold/xp_books` 作为长期成长预算；优化建议优先使用战斗XP+马桶币路线，
  但兼容命令仍属 implemented。

## 属性、星级与战力

等级成长按职业成长量 × 评级成长系数逐级累加并保留千分余数。B/A/S成长系数分别为
100%/115%/130%。星级对HP/攻击/防御使用100%/130%/160%；速度与暴击不受星级影响。S评级另有
140%稀有度基础倍率，B/A为100%。

角色页的逐级表使用职业基准属性，适合做平衡基线。真实永久实例由稳定seed额外产生
HP ±10、攻击 ±3、防御 ±2、速度 ±4000、暴击 ±50基点的确定性浮动，然后从该实例值继续成长。
因此基准CP不是每个存档角色的绝对CP；验收时必须同时跑多个seed并报告区间。

`CP = HP×3 + 攻击×20 + 防御×10 + 速度/500 + 暴击基点/10`。CP不计技能、控制、治疗、召唤、
目标覆盖、阵营协议和自损。

| 主动技能等级 | 执行倍率 | 单级成本 | 研究门槛 |
|---:|---:|---|---|
| 1 | 100% | 初始 | 无 |
| 2 | 120% | 80马桶币 + 4军团数据 | 研究所Lv1可研究 |
| 3 | 140% | 160马桶币 + 8军团数据 | 研究所至少Lv2 |

技能Lv1→3总计240马桶币、12军团数据。所有主动技能耗100能量，普通攻击每次获得20能量，因此
无受击回能和阵营协议时最早约5次攻击形成一次技能。

## 升星与生产

| 评级 | 2★碎片 | 3★碎片 | 1★→3★合计 |
|---|---:|---:|---:|
| B | 20 | 40 | 60 |
| A | 30 | 60 | 90 |
| S | 40 | 80 | 120 |

正常长期成长只消费型号专属碎片。旧 `model_tech_stars` 的10/30图纸数据与200/600马桶币，以及
旧同星合成路径属于并存/兼容实现，不加入正常培养总成本，除非当前玩家入口重新选用它们。

工业材料估值只用于比较时间和机会成本：瓷片3.2、零件4、污泥4金币价值/份。当前图纸研究固定
5秒且不扣配方材料；`duration_seconds` 和材料成本属于生产队列。主产品合同与基础/阵营核心流程
由研究领取创建唯一永久角色；生产队列仍可按配方创建额外实例，是并存兼容路径。两条获取路径不得
相加为“首次角色总成本”，后续应收敛多实例生产与唯一永久角色合同的冲突。

## 联盟缩放

第二章以后，敌军 `HP/攻击/防御 = 未缩放模板值 × enemy_power_bp / 10000`，向下取整；射程、
攻击周期和移动速度不缩放。第一章特殊关与固定模板可能绕过或覆盖缩放。敌军不培养，优化时比较
单体预算、同型数量、整波总HP/攻击和关卡模块叠加，而不是套用玩家CP。
