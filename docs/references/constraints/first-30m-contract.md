---
km_id: reference.first-30m-contract
km_type: reference
domain: product
status: active
owner: product-design
last_verified: 2026-07-25
source_of_truth:
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/domains/product.md
validated_by:
  - user-correction-review-2026-07-24
  - godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
  - godot --headless --path project-a -s tools/run_lifecycle_tests.gd
tags:
  - reference:first-30m-contract
  - quality:acceptance-gate
related:
  - domain.product
  - domain.factory-cultivation
  - domain.hero-formation
  - domain.battle-progression
  - reference.verification-matrix
---

# 首个 30 分钟验收合同

## 目标

固定“马桶人工厂攻城”首个可玩切片的体验证据：玩家必须理解生产选择，经历一次可信失败，通过培育和布阵形成可观察的战力变化，并在同一目标上再战获胜。

旧版“四名初始英雄 → 随机招募 → 装备保底 → 三设施”的路线属于历史 fantasy-idle 方案，不再是当前 P0 验收标准。

## 事实

### 玩家旅程

- 0-5 分钟：标题进入营地，动态行动卡推荐“出征侦察”；玩家以默认六人编队、自动技能默认关闭挑战同一个联盟基地。战斗展示守军、设施和核心，首战失败或超时后明确说明失败原因，并保证小额残骸不会让成长路径硬锁。
- 5-10 分钟：营地行动卡根据首败、已有蓝图、英雄数量和生产队列纯派生下一步；反制蓝图已开放时引导玩家进入工厂指定生产，订单完成则优先引导领取。行动卡只导航，不发奖励、不改变存档 revision。
- 10-14 分钟：领取永久英雄并执行一次同原型同星级三合一；若已有二星英雄与训练书，则进入培育完成一次训练。升至二星后的技能必须产生机制变化，而不只是数值线性增长。
- 14-18 分钟：检查六人 2×3 编队，并决定是否主动开启自动技能；偏好在后续战斗及重新载入后继续生效。
- 18-22 分钟：动态行动卡引导重试同一关卡，依靠已验收的生产、合成、训练或换阵路径获胜。
- 22-30 分钟：结果页展示唯一推荐动作、下一关威胁和蓝图用途；营地继续指向最高已解锁关卡，玩家作出下一次生产或出征决策。
- 营地只有一个“目标”入口承载任务与成就分页；首 30 分钟只允许展示“大战役任务/永久成就已完成但待领取”和最多 3 个无时限循环小任务。目标入口不得抢走动态行动卡的下一步成长建议，不得出现每日/周常倒计时、广告刷新、付费轨或蓝图奖励。

### 必须证明的玩法合同

- 八种原型各有唯一、可由配方追溯的战斗职责和 canonical 主动技能；战斗不得再按四个职业把它们折叠成四套技能。
- 二星和三星至少各带来一次可观察的技能质变，例如新增目标、范围、控制、护盾联动或额外触发；单纯增加百分比不算质变。
- 同一固定 seed、同一内容版本下：初始默认路径失败；执行指定成长步骤后重试同一关卡获胜。
- 战斗体验依次包含单位交战、设施突破和核心攻坚，联盟普通守军与精英单位参与结算而非仅作背景模型。
- 自动技能默认关闭；玩家修改后跨战斗、跨存档读取保持，直到再次主动修改。
- 动态行动卡和失败后建议只能读取现有状态并导航；不得额外写入任务状态、暗发奖励或因打开界面改变 revision。
- 任务、成就与战功属于软反馈层：25 个大战役任务只由关卡首次胜利完成，3 槽循环小任务只由新领域事件推进，24 个永久一次性成就分为战役 6、工厂 3、培育 7、收集 8，战功等级只在 `1–30` 提供等级奖励；30 级后累计战功继续记录但不得增加无限等级、战力倍率或卡关必需收益。
- 离线生产使用绝对时间：订单在退出后到期，重新进入可领取且只能领取一次。
- Web 手机横屏在 844×390 视口下可用触控或指针完成生产、培育、编队、战斗与结算；Android Chrome 和 iOS Safari 真机仍是独立发布门禁。

### 数值与证据纪律

- 首败与再胜使用同一个固定 seed、关卡定义和内容 hash，不得换 seed 粉饰结果。
- 验收脚本必须记录首战结果、成长命令、战力/技能变化、再战结果、奖励和关卡完成状态。
- 生产、领取、合成、训练、蓝图解锁和战斗结算均遵守 claim-once / exact-once；失败重试不能复制资源。
- 任务/成就完成和领取必须分离；完成只改变状态，领取才发放奖励。任务和成就领奖必须通过命令和幂等流水记录 generation、request/business key 与 claimed 状态；重放同一战斗、同一生产事件、同一成就事件或同一领奖命令不得复制奖励。普通大战役任务奖励假设为大战功 `60` + 金币 `20`，Boss 为大战功 `160` + 金币 `50` + 训练书 `1`；循环 minor 奖励保守小额且以实现 catalog 为准。成就奖励只允许大战功、金币和训练书，不允许蓝图、战力倍率、广告、IAP 或限时/FOMO 收益；全部数值未真人验证。
- 具体成本、时长和伤害系数可调，但不得破坏上述可观察路径。

## 入口或路径

[KM:reference.skibidi-toilet-idle-siege-gdd](../product-design/skibidi-toilet-idle-siege-gdd.md)、[KM:domain.product](../../domains/product.md)。

## 验证

Godot headless 元系统测试、战斗测试、完整生命周期测试和 Web 844×390 浏览器 smoke 必须绑定同一提交；目标手机真机结果单独记录。

## 相关节点

[KM:reference.verification-matrix](../indexes/verification-matrix.md)。
