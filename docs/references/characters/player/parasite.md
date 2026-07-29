---
km_id: reference.character-player-parasite
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

# 大型寄生虫马桶人

| 字段 | 当前事实 |
|---|---|
| 稳定 ID / 配方 | `parasite` / `special.parasite` |
| 评级/职业/阵营 | S / `arcanist` / 干扰增殖 |
| 1★/2★/3★ CP | 2168 / 2748 / 3338 |
| 主动技能 | `parasite_swarm` 寄生虫群 |
| 工厂成本 | 瓷片16、零件18、污泥30；18秒 |

## 等级与战力（derived，职业基准）

| Lv | 基础HP | 基础攻 | 基础防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 120 | 42 | 17 | 92000 | 9.00% | 2168 | 2748 | 3338 |
| 2 | 126 | 50 | 18 | 95640 | 9.45% | 2463 | 3112 | 3771 |
| 3 | 133 | 58 | 19 | 99280 | 9.91% | 2735 | 3463 | 4188 |
| 4 | 139 | 66 | 20 | 102920 | 10.36% | 3010 | 3824 | 4621 |
| 5 | 146 | 74 | 22 | 106560 | 10.82% | 3293 | 4196 | 5092 |

S稀有度下，Lv1 1★派生属性为`168/58/23`，Lv5 1★为`204/103/30`，Lv5 3★为
`327/165/49`。射程110；移动9→10/tick；攻击周期6→5 tick；技能循环约30→25 tick。

## 培养成本（implemented）

| 项目 | 当前成本 |
|---|---|
| 主获取：图纸研究 | 固定5秒、无材料；领取时创建唯一永久角色 |
| 兼容生产队列 | 瓷片16、零件18、污泥30，18秒；材料价值243金币 |
| Lv1→5主路线 | 320战斗XP + 420马桶币 |
| 兼容经验书路线 | 16经验书 + 900旧金币 |
| 1★→3★ | 40 + 80 = 120个`parasite`专属碎片 |
| 技能Lv1→3 | 12军团数据 + 240马桶币 |
| 主路线完整培养 | 660马桶币 + 12军团数据 + 120碎片；不强制加配方材料 |

完整公式见 [角色数值与培养规则](../numeric-rules.md)。

**战斗合同（implemented）：** 1★召唤寄生幼体分担火力；2★增加召唤规模；3★优先短暂策反
普通守军，无法策反时回退到召唤。临时单位不进入永久角色与CP合同。

**定位：** 精英波次或持续炮火时用额外单位改变目标分配。相比音波需要展开但能吸引火力；相比
维修不直接恢复主力。第四章净化只伤害幼体和策反单位，不伤永久角色。

**表现/验证：** 母体、幼体、策反归属和净化反馈必须易读。测试召唤数量、普通/精英筛选、回退、
临时单位结算清理与净化伤害边界。

## 优化分析

- **当前效率：** Lv1→5增加1125/1448/1754 CP；S面板和召唤价值叠加，实际优势可能高于CP差。
- **同类对比：** 音波即时控场，寄生需要展开但创造额外HP/攻击与目标；净化关中价值主动下降。
- **目标预算：** 1★召唤立即完整，2★扩大分担，3★策反普通兵但不控制精英/Boss。
- **过强/过弱信号：** 幼体承伤+输出使总价值长期超过第二名角色50%以上为过强；一次净化让永久
  主体失去整场职责为过弱。
- **首选杠杆：** 调幼体数量、`owner HP/3`与`owner attack/2`继承、策反时长；固定seed总贡献
  领先同星音波15%–30%可作为S目标，超过45%触发回滚。

**风险：** 召唤/策反不进CP，第四章净化需要明确但不能使角色失效。
