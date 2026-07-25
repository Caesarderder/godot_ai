---
km_id: domain.product
km_type: domain
domain: product
status: active
owner: product-design
last_verified: 2026-07-24
source_of_truth:
  - .omx/specs/deep-interview-fantasy-idle-expedition.md
  - .omx/plans/prd-fantasy-idle-expedition.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/references/product-design/skibidi-toilet-lore-research.md
validated_by:
  - deep-interview
  - ralplan-consensus
  - user-confirmed-design-session
  - python3 tools/docs_lint.py
tags:
  - domain:product
  - decision:core-loop
related:
  - domain.factory-cultivation
  - domain.hero-formation
  - domain.equipment-economy
  - domain.camp-quests
  - reference.product-boundaries
  - reference.skibidi-toilet-idle-siege-gdd
  - reference.skibidi-toilet-lore-research
  - reference.earth-skibidi-act1-campaign
  - reference.earth-war-character-roster
---

# 产品领域

## 目标

做一款手机端 Web-first 3D 单机休闲放置游戏，让玩家通过马桶人工厂生产、永久升星、六人队伍编成和自动攻城，获得清晰目标、正反馈和“这支军团是我造出来的”体验。

## 什么时候读

改变玩法循环、系统深度、首局节奏、内容范围、商业化或平台前。

## 职责

- 当前核心循环：营地 -> 目标中心软引导 -> 工厂生产 -> 领取永久马桶人 -> 同原型同星 3 合 1 培育 -> 六人 2×3 编队 -> 三阶段自动攻城 -> 结算材料/任务/成就进度 -> 回到工厂。
- 系统优先级：工厂/培育/编队/攻城 P0，营地目标中心与战功软反馈 P0.5，装备 P1，设施扩展和离线收益 P2。
- 当前可玩切片目标：8 个初始马桶人、三材料八配方、最多 3 个生产订单、六人出征、一次失败后通过生产或升星再战，并在单一“目标”入口内展示任务与永久一次性成就。
- 后续长期目标仍包含装备、设施扩展、离线收益和手机浏览器真机证据。
- 长期采用双战役结构：地球 Skibidi 主线经历扩张、联盟反攻摧毁旧工厂、移动工厂重建和 Astro 入侵；通关后另行解锁不覆盖地球养成的 Astro 征服战役。
- 第一幕《地球战争》按五章二十五关规划，依次引入 Cameramen、Speakermen、TV Men、三族联合防线和中央基地；每章必须用一种新敌方机制推动一个工厂解锁或培育选择。

## 不是本层职责

不决定具体 GDScript 类、场景树、存档算法或 UI 节点结构。

## 不变量

任务和成就不得硬锁后续关卡；生产、合成、任务领奖和成就领奖不得绕过命令事务；装备不得取代英雄本身；营地不得膨胀为复杂经营。

## 入口

[KM:reference.product-boundaries](../references/constraints/product-boundaries.md)、[KM:reference.first-30m-contract](../references/constraints/first-30m-contract.md)。

第一幕完整内容入口：[KM:reference.earth-skibidi-act1-campaign](../references/product-design/earth-skibidi-act1-campaign.md)；角色名册入口：[KM:reference.earth-war-character-roster](../references/product-design/earth-war-character-roster.md)。

## 分支级候选方向

`codex/toilet-man-3d-idle` 的公开免费 Web 同人方向已成为当前 `project-a` 第一幕本地发行候选的产品方向。它使用原作世界观、阵营和标志性角色讲述原创平行战争线，不逐集复述原作。主要场景是手机浏览器横屏 3D，核心展示是军团沿城市大道线性推进并摧毁联盟基地；战斗采用低操作自动推进，自动技能默认关闭，关闭时玩家只需点击头像手动施法，不手动移动、选目标或控制镜头。第一幕以五章 25 关逐步从阴沉白天进入黄昏战火，五个基地级 Boss 在最终基地阶段启用可压制核心巨炮，形成“输出够则压制炮击、输出不够则承受命中”的竞速压力，但不新增操作按钮、货币、奖励、存档字段、任务或成就。长期主线始终培养地球 Skibidi：联盟反攻可以摧毁旧工厂并推动移动工厂重建，但不得清空永久角色、星级、关键蓝图和收藏；Astro 入侵后仍沿用地球军团，通关后才解锁独立 Astro 征服战役。完整契约见 [KM:reference.skibidi-toilet-idle-siege-gdd](../references/product-design/skibidi-toilet-idle-siege-gdd.md)；当前实现边界见 [KM:reference.implementation-status](../references/constraints/implementation-status.md)。

## 验证

对照 5 人预注册观察：关键项至少 4/5，总 checkpoint 至少 45/50。

## 相关节点

[KM:invariant.project-boundaries](../map/invariants.md)。
