---
km_id: domain.factory-cultivation
km_type: domain
domain: factory-cultivation
status: active
owner: gameplay
last_verified: 2026-07-26
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/tools/run_research_onboarding_tests.gd
validated_by:
  - user-confirmed-redesign-session-2026-07-26
  - python3 tools/docs_lint.py
  - godot --headless --path project-a -s tools/run_research_onboarding_tests.gd
  - godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
tags:
  - domain:factory-cultivation
  - decision:p0-system
related:
  - domain.product
  - domain.hero-formation
  - domain.equipment-economy
  - reference.implementation-status
  - reference.game-state-measurement-framework
---

# 工厂与培育领域

## 目标

让可点击的 3D 工厂持续生产后勤资源，并通过建造、加工、研究和设施升级支持永久角色成长与连续攻城。

## 职责

- 指挥中心控制设施、角色与章节功能上限；
- 新设施通过“选择建筑类型 → 打开网格 → 选择空格 → 二次确认”开工；确认前的预览不扣款、不写存档，
  确认后进入有结束时间的施工队列，到点验收后才落成并启用；
- 已建设施的网格坐标属于工厂持久状态，越界或占用格不得提交；
- 首次工业备战的任务入口直接进入三座资源设施选择，显示当前库存与紧邻成长需求；建成后任务
  入口定位到该设施的投产收取，不得循环刷新行动页或让非资源设施抢占首次选择；
- 陶瓷厂、能源站持续生产基础资源，零件车间加工机械零件；
- 三座资源建筑拥有独立生产锚点与可领取状态，点击建筑只领取其自身资源；
- 指挥与研究建筑点击后进入各自管理面板，建筑等级和当前选择在 3D 场景中可见；
- 新档研究所锁定；1-4 第一次战斗失败只幂等开放研究所建造资格，玩家完成选址、施工与验收后，
  才开放冲锋、装甲两张基础蓝图；
- 点击研究所进入带主干、四条树枝和前后节点连线的科技蓝图 UI，展示目录中的全部马桶人型号；
  两张基础蓝图分别进入 45 秒研发队列，到点领取后才确定性授予一名永久冲锋马桶人和装甲马桶人，
  随后通过现有六槽编队命令上阵；
- 后续型号节点继续由各自进度来源开放；研究所同时承担技能、星级节点和工业科技；
- 设施派驻由角色星级专长强化，同一角色只强化一座设施，但不禁止主线出战；
- 离线结算由产速、容量和时间决定，基础容量目标覆盖 8–12 小时；
- 所有收取、加工、建造、升级、研发与验收都通过 durable command；进行中订单跨刷新持久化，
  重复请求不得重复产出、授予或扣款。
- 工厂健康使用有效产速、存满时间、领取损失率、压力向量、维修/成长负载和可支持出征数解释，
  不能只显示库存或总产量。

## 不是本层职责

不生产量产马桶人，不执行自动扫荡，不决定战斗伤害、城镇胜负或角色战斗技能。

## 不变量

- 工厂最低产能不能被清零；
- 重要设施等级必须带来可感知能力或容量变化；
- UI 不能直接修改资源和设施状态；
- 1-4 首败只开放研究所建造资格，不自动落成；玩家主动建成后才开放两个确定性基础蓝图节点；
- 当前 schema v6 单位生产仅作迁移输入，不是新产品权威。

## 入口

[KM:reference.skibidi-toilet-idle-siege-gdd](../references/product-design/skibidi-toilet-idle-siege-gdd.md)、
[KM:reference.toilet-factory-technical-design](../references/architecture/toilet-factory-technical-design.md)。
[KM:reference.game-state-measurement-framework](../references/product-design/game-state-measurement-framework.md)。

## 验证

覆盖离线结算上限、容量溢出、加工守恒、升级门禁、派驻唯一、余额不足、首败研究所资格与主动建造、
八型号蓝图树、基础角色唯一授予、编队上阵和死锁恢复。
