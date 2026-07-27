---
km_id: reference.skill-qa-release-practice-gd-agentic-platform-web
km_type: reference
domain: game
status: active
last_verified: 2026-07-24
source_of_truth:
  - legacy:project-skills/gd-agentic-web-runtime
validated_by:
  - script:migrate-role-catalog
tags:
  - role:qa-release
  - axis:practice
axis: practice
activation: contextual
canonical_role: qa-release
public_skill: godot-qa-release
canonical_technical_owner: gd-agentic-platform-web
source_skill: gd-agentic-web-runtime
content_home: godot-qa-release/references/gd-agentic-platform-web.md
compatibility: default
routes_to: []
aliases:
  - gd-agentic-platform-web
---

# gd-agentic-platform-web

## 目标

通过 测试发布 岗位知识地图按需读取这项现有能力，不改写原始正文或工件。

## 什么时候读取

用户请求与 `gd-agentic-platform-web` 直接相关，且本节点是当前任务所需的一到两个最小叶子之一时。

## 职责

- [读取完整保留内容](../../gd-agentic-platform-web.md)
- 按保留内容中的直接链接继续读取脚本、场景、模板或资产。

## 不负责什么

不自动加载同轴其他节点，不复制其他岗位正文，不扩大默认兼容边界。

## 验证

迁移 manifest、catalog baseline 与目标文件 SHA-256 必须一致。
