---
km_id: reference.skill-programming-system-ai-navigation
km_type: reference
domain: game
status: active
last_verified: 2026-07-24
source_of_truth:
  - legacy:project-skills/ai-navigation
validated_by:
  - script:migrate-role-catalog
tags:
  - role:programming
  - axis:system
axis: system
activation: contextual
canonical_role: programming
public_skill: godot-programming
canonical_technical_owner: ai-navigation
source_skill: ai-navigation
content_home: godot-programming/references/systems/ai-navigation/SKILL.md
compatibility: default
routes_to: []
aliases:
  - ai-navigation
---

# ai-navigation

## 目标

通过 程序 岗位知识地图按需读取这项现有能力，不改写原始正文或工件。

## 什么时候读取

用户请求与 `ai-navigation` 直接相关，且本节点是当前任务所需的一到两个最小叶子之一时。

## 职责

- [读取完整保留内容](../../systems/ai-navigation/SKILL.md)
- 按保留内容中的直接链接继续读取脚本、场景、模板或资产。

## 不负责什么

不自动加载同轴其他节点，不复制其他岗位正文，不扩大默认兼容边界。

## 验证

迁移 manifest、catalog baseline 与目标文件 SHA-256 必须一致。
