---
km_id: reference.product-boundaries
km_type: reference
domain: product
status: active
owner: product-design
last_verified: 2026-07-17
source_of_truth:
  - .omx/specs/deep-interview-fantasy-idle-expedition.md
validated_by:
  - deep-interview
  - user-confirmation
tags:
  - reference:product-boundaries
  - risk:scope-drift
related:
  - domain.product
  - invariant.project-boundaries
---

# 产品范围与确认边界

## 目标

区分代理可自主细化的内容和必须再次询问用户的方向变化。

## 事实

### 可决定并频繁沟通

- Godot 架构、目录、GDScript 数据结构、事件、存档格式。
- 首版职业/数值/掉率/任务节奏初值。
- UI 信息层级、灰盒布局、测试方案。

### 必须先确认

- 核心循环。
- 英雄/编队/装备/营地的主次。
- 随机英雄模型。
- 美术主题与表现方向。
- 商业化方式。
- 目标平台组合或单机边界。

### 首版明确不做

任务硬门槛、固定角色抽卡、重剧情/立绘、复杂营地、多队、转职、星级、套装、联网排行、公会、PvP、云存档、多语言和商业化。

## 入口或路径

[CODE:source-spec](../../../.omx/specs/deep-interview-fantasy-idle-expedition.md)。

## 验证

任何范围变化先对照本节点和 [KM:invariant.project-boundaries](../../map/invariants.md)。

## 相关节点

[KM:domain.product](../../domains/product.md)。
