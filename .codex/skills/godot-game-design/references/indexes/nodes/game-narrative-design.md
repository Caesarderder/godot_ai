---
km_id: reference.skill-game-design-system-game-narrative-design
km_type: reference
domain: game
status: active
last_verified: 2026-07-24
source_of_truth:
  - legacy:project-skills/game-narrative-design
validated_by:
  - script:migrate-role-catalog
tags:
  - role:game-design
  - axis:system
axis: system
activation: contextual
canonical_role: game-design
public_skill: godot-game-design
canonical_technical_owner: game-narrative-design
source_skill: game-narrative-design
content_home: godot-game-design/references/systems/game-narrative-design/SKILL.md
compatibility: default
routes_to: []
aliases:
  - game-narrative-design
---

# game-narrative-design

## 目标

通过 策划 岗位知识地图按需读取这项现有能力，不改写原始正文或工件。

## 什么时候读取

用户请求与 `game-narrative-design` 直接相关，且本节点是当前任务所需的一到两个最小叶子之一时。

## 职责

- [读取完整保留内容](../../systems/game-narrative-design/SKILL.md)
- 按保留内容中的直接链接继续读取脚本、场景、模板或资产。

保留正文中的 explicit-only 文案是历史源合同；当前是否发现本 leaf 以此 wrapper 的
`activation: contextual` 与 scope guard 为准，不能把源 frontmatter 当作平级可调用 Skill。

## 不负责什么

不自动加载同轴其他节点，不复制其他岗位正文，不扩大默认兼容边界。

## 验证

迁移 manifest、catalog baseline 与目标文件 SHA-256 必须一致。
