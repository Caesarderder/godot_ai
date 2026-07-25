---
km_id: reference.product-boundaries
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
  - reference:product-boundaries
  - risk:scope-drift
related:
  - domain.product
  - invariant.project-boundaries
  - reference.first-30m-contract
---

# 产品范围与确认边界

## 目标

固定当前“马桶人工厂攻城”方向，区分可以在既定体验内迭代的内容和会改变产品身份、必须再次确认的变化。

历史 deep-interview、fantasy-idle PRD 与 TapTap/2D 分支只保留追溯价值；发生冲突时，以当前 Skibidi 攻城 GDD、产品域和本节点为准。

## 事实

### 已确认的当前产品

- Godot 4.6.3、3D 表现、Compatibility renderer、Web-first、手机横屏、单机可玩。
- 核心循环是“营地目标中心软引导 → 选择配方生产永久英雄 → 领取/离线回收 → 三合一与训练 → 六人 2×3 编队 → 自动攻城 → 结算材料、蓝图、任务与成就进度 → 回厂成长”。
- 八种马桶人原型是配方、外观、职责与技能的统一内容单位，不得在战斗层退化为四职业换皮。
- 生产是显式配方和车间队列，不是随机招募或抽卡。
- 星级与训练属于 P0 培育；星级必须带来技能机制变化。
- 战斗包含联盟普通守军、精英单位、设施和核心，形成单位交战、设施突破、核心攻坚三层。
- 自动战斗是低操作体验，但技能自动开关由玩家控制并持久化。
- 任务与永久一次性成就只作为目标中心软反馈；完成和手动领取分离，不提供蓝图、战力倍率、广告、IAP 或限时/FOMO 收益。

### 可在边界内自主细化

- Godot 架构、目录、GDScript 数据结构、事件、JSON 存档版本与迁移。
- 八原型技能细节、敌军模板、首轮数值、材料成本、生产时长和蓝图解锁里程碑。
- 车间与战斗的灰盒 3D 表现、生产线动画、角色出厂展示、UI 信息层级与触控布局。
- 确定性 seed、测试 fixture、首败再胜的具体成长动作，只要不绕过核心系统。

### 必须先确认

- 改变工厂生产、永久英雄培育、六人编队或三层攻城中的任一核心支柱。
- 把显式配方改为抽卡/随机招募主线，或把单机改为联网服务。
- 商业化、付费货币、广告强度、IP 授权、公开发行平台与账号体系。
- PvP、公会、排行榜、云存档、多队大地图等显著扩大范围的系统。
- 大幅改变美术主题、目标平台组合或手机横屏交互方式。

### 当前 P0 不包含

- 旧四人编队、随机招募主线、装备保底驱动的首 30 分钟。
- 复杂装备词条/强化、酒馆/铁匠/训练场三设施、重任务线；这些可作为 P1/P2 候选，但不能抢占当前核心闭环。
- 自由建造、人口模拟、复杂物流、转职、套装、重剧情/立绘、PvP、公会、联网排行、云存档、多语言和商业化。

## 入口或路径

[KM:reference.skibidi-toilet-idle-siege-gdd](../product-design/skibidi-toilet-idle-siege-gdd.md)、[KM:reference.first-30m-contract](first-30m-contract.md)。

## 验证

每次里程碑回看首 30 分钟合同：若新增功能不能加强生产选择、永久培育、六人编队、三层攻城或失败后成长再胜，应降级或移出 P0。

## 相关节点

[KM:domain.product](../../domains/product.md)、[KM:invariant.project-boundaries](../../map/invariants.md)。
