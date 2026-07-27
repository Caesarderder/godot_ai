---
km_id: invariant.project-boundaries
km_type: invariant
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-26
source_of_truth:
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/references/constraints/product-boundaries.md
validated_by:
  - ralplan-consensus
  - manual-plan-review
tags:
  - risk:product-drift
  - risk:state-consistency
related:
  - reference.product-boundaries
  - reference.state-command-lifecycle
  - reference.game-state-measurement-framework
---

# 项目不变量

## 产品不变量

- 手机横屏、Web-first、3D、低操作自动攻城；工厂经营服务于持续推关。
- 核心马桶人永久拥有；战斗内 HP 只决定本局胜负，结算后恢复为 100% 可出征，不得产生跨局战备损失或永久删除角色。
- 出征最多六名永久角色，采用前后 `2×3`；每个槽必须对应稳定 `hero_id`。
- 工厂只生产后勤资源，不生产量产马桶人，不执行自动首次推图或扫荡。
- 城镇战果提供金币、工业技术和受控突破资源；工厂资源提供角色成长和设施建设。兼容字段中的旧 `gold/xp_books` 不得作为当前成长建议或关卡预算。
- 不设体力、扫荡券、维修等待或每日挑战次数；结算支持升级、调整编队或继续下一关。
- 工业资源的每次消费必须形成永久成长，不得通过恢复型消耗回收已经拥有的战力。
- 马桶钻与付费抽取退出当前范围；首章完成后允许游戏内招募券驱动的 B/A/S 概率信号抽取，
  但通关必需职责必须由主线确定性提供，重复结果只进入型号专属碎片。
- 商业部署必须先获得商业 IP 授权，并完成目标地区发行、支付、未成年人保护、退款和隐私合规。
- 未经用户确认，不改变上述核心循环、永久角色、工厂后勤、主动攻城、战后无损或目标平台。
- `CombatPower` 是 UI、成长预览和关卡能力比的唯一展示战力口径；只统计当前编队，不得用账号总战力或页面私有公式承诺可通关关卡。
- 角色等级升级必须通过同一领域成长函数原子地更新等级、经验和基础属性，并能产生可验证的正向 `ΔCP`；不得只修改显示等级。
- 工业资源按时间价格、生产负载和局部成长价值比较；金币没有无条件工厂产速，不设跨章节固定汇率。
- 新系统不得无预算增加独立常驻乘区；新货币必须证明独立门禁和至少两个有决策价值的用途。
- 商业化不得修复人为制造的死锁、容量惩罚或失败挫折，非付费闭环必须先成立。

## 技术不变量

- `project-a/` 是当前 Godot 4.6.3 实现根；使用 GDScript、3D 表现、Web-first 发布。`taptap/` 是历史参考，不是当前交付入口。
- 旧 PRD/Test Spec 和当前代码只证明上一版实现，不再高于新 GDD 的产品事实；迁移完成前必须显式区分目标设计与旧实现。
- Web 使用 Compatibility / WebGL 2.0；默认单线程导出。Forward+、C#、原生移动插件和没有 Web 构建的 GDExtension 不得成为当前版本依赖。
- 3D 场景只投影领域战斗；物理、导航、动画和帧率不得决定命中、伤害、掉落或胜负。
- UI 必须适配浏览器 viewport、安全区和 DPI，主要触控目标不得低于 48 基准像素。
- 静态角色定义与永久角色实例分离；运行状态保存稳定 hero ID、成长、技能和派驻。战备度仅作旧存档兼容输入，当前运行时归一为 100。
- executor 是 GameState 唯一写入口；价值命令先持久化再报告成功。
- 离线生产只认受控时间锚；战斗只认稳定 seed 和 5Hz tick。
- UI 是状态投影，不直接修改领域状态。
- 浏览器后台不依赖持续 Tick；恢复只通过 sealed internal command 结算离线收益。
- 实现事实必须由代码、测试和命令重新验证；计划路径不等于已存在路径。
