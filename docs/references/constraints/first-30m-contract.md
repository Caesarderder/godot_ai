---
km_id: reference.first-30m-contract
km_type: reference
domain: product
status: active
owner: product-design
last_verified: 2026-07-24
source_of_truth:
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/domains/product.md
validated_by:
  - user-correction-review-2026-07-24
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

- 0-2 分钟：标题进入基地，直接看到四个车间分区；普通车间可用，其余车间以锁定预览展示。玩家选择一个 5 秒教学配方并领取首名出厂英雄。
- 2-5 分钟：查看八种马桶人原型的职责、主动技能与蓝图条件，理解“指定配方生产永久英雄”，而非随机招募。
- 5-8 分钟：以默认六人编队、自动技能默认关闭挑战同一个联盟基地；战斗明确展示普通守军、精英单位、设施和核心，首战确定性失败或超时并说明原因。
- 8-14 分钟：回到工厂完成指定生产，执行一次同原型同星级三合一；若有训练书，可训练一名英雄。升至二星后，技能必须产生机制变化，不只是数值线性增长。
- 14-18 分钟：调整六人 2×3 编队，并按英雄设置自动技能偏好；该偏好在后续战斗及重新载入后继续生效。
- 18-22 分钟：重试同一关卡，依靠已验收的生产、合成、训练或换阵路径确定性获胜。
- 22-30 分钟：领取胜利材料，看到至少一个新蓝图解锁或解锁进度，作出第二次生产决策，并预览下一场精英遭遇。

### 必须证明的玩法合同

- 八种原型各有唯一、可由配方追溯的战斗职责和 canonical 主动技能；战斗不得再按四个职业把它们折叠成四套技能。
- 二星和三星至少各带来一次可观察的技能质变，例如新增目标、范围、控制、护盾联动或额外触发；单纯增加百分比不算质变。
- 同一固定 seed、同一内容版本下：初始默认路径失败；执行指定成长步骤后重试同一关卡获胜。
- 战斗体验依次包含单位交战、设施突破和核心攻坚，联盟普通守军与精英单位参与结算而非仅作背景模型。
- 自动技能默认关闭；玩家修改后跨战斗、跨存档读取保持，直到再次主动修改。
- 离线生产使用绝对时间：订单在退出后到期，重新进入可领取且只能领取一次。
- Web 手机横屏在 844×390 视口下可用触控或指针完成生产、培育、编队、战斗与结算；Android Chrome 和 iOS Safari 真机仍是独立发布门禁。

### 数值与证据纪律

- 首败与再胜使用同一个固定 seed、关卡定义和内容 hash，不得换 seed 粉饰结果。
- 验收脚本必须记录首战结果、成长命令、战力/技能变化、再战结果、奖励和关卡完成状态。
- 生产、领取、合成、训练、蓝图解锁和战斗结算均遵守 claim-once / exact-once；失败重试不能复制资源。
- 具体成本、时长和伤害系数可调，但不得破坏上述可观察路径。

## 入口或路径

[KM:reference.skibidi-toilet-idle-siege-gdd](../product-design/skibidi-toilet-idle-siege-gdd.md)、[KM:domain.product](../../domains/product.md)。

## 验证

Godot headless 元系统测试、战斗测试、完整生命周期测试和 Web 844×390 浏览器 smoke 必须绑定同一提交；目标手机真机结果单独记录。

## 相关节点

[KM:reference.verification-matrix](../indexes/verification-matrix.md)。
