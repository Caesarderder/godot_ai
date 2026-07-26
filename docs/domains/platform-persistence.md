---
km_id: domain.platform-persistence
km_type: domain
domain: platform-persistence
status: active
owner: platform
last_verified: 2026-07-26
source_of_truth:
  - docs/game-contract.md
  - docs/references/architecture/toilet-factory-technical-design.md
  - project-a/game/scripts/persistence/save_manager.gd
  - project-a/game/scripts/platform/web_runtime.gd
validated_by:
  - manual-migration-preflight-2026-07-26
tags:
  - domain:platform-persistence
  - risk:save-migration
related:
  - domain.product
  - reference.implementation-status
  - reference.toilet-factory-refactor-plan
---

# 平台与持久化领域

## 目标

在 Godot Web 单线程环境中安全保存永久角色、设施、资源、城镇进度和离线时间，并从旧 schema 原子迁移。

## 职责

- 保存角色等级/经验/星级/技能与派驻；旧战备字段只作迁移兼容；
- 保存设施等级、资源、容量、加工状态与最后结算时间；旧维修订单迁移后不得影响当前玩法；
- 保存金币、工业技术、突破资源、编队、关卡和 durable receipts；
- v6 → 新 schema 迁移必须先备份，失败回滚，不允许部分覆盖；
- 时间回拨不产生负产出或复制收益；
- 页面刷新、关闭和失焦保持先存后提交与战斗暂停语义；
- 浏览器存储状态必须对玩家可见，并提供经过同一 schema 管线校验的本地备份导出/二次确认恢复；
- 旧马桶钻、图纸、保底和库存单位仅作 legacy migration input。

## 不是本层职责

不决定成长数值、维修配方、战斗结果、支付后端或 UI 布局。

## 不变量

UI 不直接写状态；保存失败不能报告价值操作成功；离线结算、维修、升级和战斗结算必须幂等；
本地存档不能承担真实支付权益。

## 验证

覆盖 v6 golden save、迁移回滚、主备恢复、导出/导入、不兼容备份拒绝、刷新/关闭、时间回拨、
离线容量、重复 receipt 和严格 JSON。
