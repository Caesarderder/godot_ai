---
km_id: reference.earth-skibidi-act1-campaign
km_type: reference
domain: product
status: active
owner: product-design
last_verified: 2026-07-29
source_of_truth:
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/references/product-design/skibidi-toilet-lore-research.md
  - docs/references/product-design/campaign-60-stage-progression.md
  - project-a/game/scripts/domain/content/stage_catalog.gd
validated_by:
  - godot --headless --path project-a -s tools/run_campaign_60_stage_tests.gd
  - python3 tools/docs_lint.py
tags:
  - domain:product
  - decision:core-loop
  - reference:act-1-campaign
  - risk:canon-drift
related:
  - domain.product
  - reference.campaign-60-stage-progression
  - reference.skibidi-toilet-lore-research
---

# 第一幕正史时间线战役

## 权威范围

第一幕使用原编号 E07–E73 作为五章 60 个可玩关卡的时间线锚点。E74 太空马桶人舰队来袭是不可玩尾声，
由 `StageCatalog.epilogue_contract()` 单独声明。旧版秘密工厂平行线、原创地点、原创组织和原创
终局首领已删除，不再作为剧情或角色依据。

关卡中的三段攻城、核心巨炮、推荐战力、图纸研究和星级成长属于玩法改编。它们不能被写成原作事件。

## 五章顺序

| 章 | 可玩范围 | 原作边界 | 实现约束 |
|---|---:|---|---|
| 1 | E07–E20 | 监控人反击、监控泰坦登场、首次泰坦战 | 只使用监控人敌军与普通炮火；没有电视人、闪屏或战术墨镜 |
| 2 | E21–E32 | E24 音响人登场，E31 普通音响人被感染，E32 音响泰坦被感染 | 2-1～2-3 仍使用监控人敌军；2-4 起才启用音响人敌军与声波机制 |
| 3 | E33–E49 | 感染泰坦推进、E39 电视人、反寄生、E47 电影泰坦与 Gman | 3-1～3-3 不出现电视人敌军或电视人机制；3-4 起才启用 |
| 4 | E50–E57 | 升级监控泰坦回归、E57 解除音响泰坦感染 | 联盟反攻，不改写为马桶人同盟 |
| 5 | E58–E73 | 阿尔法山、首席科学家死亡、G小队、拘留者、三泰坦追击 | 5-12 仍是 E73 联盟撤离战；不得把太空马桶人设为可攻击结构 |

## 尾声

E74 只展示太空马桶人舰队来袭，结束地球双方原有战争阶段。第一幕不提前演绎 E75 之后的临时合作，
也不把 E74 舰队做成联盟核心的换名皮肤。

## 角色边界

- Gman是唯一初始角色，不进入可重复配方。
- 可重复制造与招募只使用原作族群名，例如马桶人、飞行四发射器马桶人、喷气背包马桶人、
  马桶人科学家、寄生虫马桶人和突变马桶人。
- 音响马桶人、故障闪电马桶人、圆锯突变马桶人、狂战士突变马桶人、维修马桶人和首席科学家是具名唯一角色；
  当前可重复池不得使用这些显示名。
- 稳定内部角色原型、配方、技能和存档键继续保留。若现有技能没有正史一一对应，玩家说明必须
  标记“玩法改编”，不得为族群补写原作不存在的生平。

## 实现与验证

- 关卡事实、敌军家族、机制开启时点：`project-a/game/scripts/domain/content/stage_catalog.gd`
- 角色族群显示与兼容 ID：`project-a/game/scripts/domain/factory/factory_catalog.gd`
- 60 关集数范围、敌军时点与不可玩尾声：`project-a/tools/run_campaign_60_stage_tests.gd`
- 完整节奏与奖励合同：[60 关持续战役](campaign-60-stage-progression.md)
