---
km_id: reference.skill-producer-practice-game-project-contract
km_type: reference
domain: game
status: active
last_verified: 2026-07-24
source_of_truth:
  - repo:project-skills/godot-producer/references/practices/game-project-contract
validated_by:
  - script:validate-role-skill-routes
  - script:validate-contract
tags:
  - role:producer
  - axis:practice
axis: practice
activation: contextual
canonical_role: producer
public_skill: godot-producer
canonical_technical_owner: game-project-contract
source_skill: game-project-contract
content_home: godot-producer/references/practices/game-project-contract/SKILL.md
compatibility: default
routes_to: []
aliases:
  - game-project-contract
---

# game-project-contract

## 目标

为六岗位提供唯一 canonical 的项目契约、状态证据、角色写权限和漂移交接协议。

## 什么时候读取

仅用于新项目或里程碑、实质范围或规则变化、跨岗位交接、文档与实现冲突，以及里程碑或
发布验收。孤立 bug、无语义变化的视觉微调和纯重构不得触发完整治理。

## 职责

- [读取项目契约协议](../../practices/game-project-contract/SKILL.md)
- 按当前岗位只读取相关契约项和直接证据。

## 不负责什么

不新增第七个公共 Skill，不复制六份规范，不把 `implemented` 当成 `verified`，也不声称静态
validator 能理解所有自然语言或数值漂移。

## 验证

运行 bundle 内的 `scripts/validate-contract.mjs`，并保持五个非 producer 岗位的 contract
preflight 都路由回本节点。
