---
km_id: map.glossary
km_type: map
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-17
source_of_truth:
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - manual-plan-review
tags:
  - reference:glossary
related:
  - domain.product
  - reference.state-command-lifecycle
---

# 术语表

| 术语 | 含义 |
|---|---|
| Vertical Slice | 可完整试玩并验证核心价值的纵向切片；首个目标为 30 分钟 |
| 随机英雄 | 由职业模板和随机姓名、资质、特质等生成的运行实例，不是固定角色卡 |
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
