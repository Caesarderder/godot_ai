---
km_id: map.glossary
km_type: map
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-26
source_of_truth:
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
validated_by:
  - manual-plan-review
tags:
  - reference:glossary
related:
  - domain.product
  - reference.state-command-lifecycle
  - reference.game-state-measurement-framework
---

# 术语表

| 术语 | 含义 |
|---|---|
| Vertical Slice | 可完整试玩并验证核心价值的纵向切片；首个目标为 30 分钟 |
| 永久角色 | 玩家长期拥有的马桶人核心资产，不会因战败永久删除 |
| 角色等级 | 消耗金币与工业资源获得的高频数值成长 |
| 角色星级 | 使用碎片/核心数据解锁技能、被动、机制质变和工厂专长 |
| 战备度 | 0–100 的战后持续状态；不同于单场战斗中的实时 HP |
| 快速整备 | 立即恢复到安全战备阈值，速度快但资源效率较差 |
| 完全维修 | 恢复全部战备并清除重伤/设备故障，成本较高 |
| 工业资源 | 陶瓷、机械零件、污水能源；由工厂生产并用于成长、维修和扩建 |
| 工业技术 | 主要由城镇战果获得，用于解锁设施行为和等级上限 |
| 连续推关 | 无体力限制地在结算后选择带伤继续、维修、升级或进入下一关 |
| 软引导 | 任务提示方向并给奖励，但不直接锁死关卡或功能 |
| GameState | 需要跨重启保存的唯一持久状态 |
| BattleSession | 只存在于当前战斗的临时状态；途中退出不结算 |
| DURABLE_VALUE | 消耗资源、生成随机实例或发放奖励的命令，必须先持久化 |
| INTERNAL_DURABLE | pause/resume/heartbeat 使用的受控内部耐久命令 |
| Receipt | 命令去重与重放凭证，绑定 canonical fingerprint |
| offline anchor | 离线收益唯一计时起点 `offline_anchor_unix` |
| paired 1000 | 同一 1000 个预注册 seed 上，仅改变一个干预变量的成对验证 |
| 灰盒 | 使用临时视觉资产验证玩法与信息层级，不代表最终美术 |
| 知识地图 | 人和智能体共享的仓库事实、工作流、索引和验证系统 |
| FM / 工厂分钟 | L1 对应生产设施运行一分钟的产出基准 |
| TFA | 从当前库存与产速出发，凑齐一组成本所需的最长并行等待时间 |
| FL / 工厂负载 | 一组工业成本占用的三设施生产分钟之和 |
| MGE | 可见成长事件；改变推进、选择、恢复或功能，而不只是不可察觉的数值上涨 |
| CP_formation | 当前上阵角色按唯一 `CombatPower` 公式相加的编队战力 |
| CP_stage | 再计入关卡机制、克制和职责覆盖后的对关有效战力 |
| CR / 能力比 | 对关有效战力除以该关需求，用于估计风险而非保证胜利 |
| Growth ETA | 从当前库存、产速和可重复战果出发，获得下一次有效永久成长所需时间 |
| 资源压力 | 规划窗内需求除以库存与预计来源，用于识别真正瓶颈 |
| Content Runway | 剩余可见成长事件数量乘以成长事件间隔，用于估计内容寿命 |
