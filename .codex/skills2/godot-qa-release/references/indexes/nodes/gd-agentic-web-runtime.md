---
km_id: reference.skill-qa-release-provenance-gd-agentic-web-runtime
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
  - axis:provenance
axis: provenance
activation: evidence-only
canonical_role: qa-release
public_skill: godot-qa-release
canonical_technical_owner: gd-agentic-web-runtime
source_skill: gd-agentic-web-runtime
content_home: godot-qa-release/references/provenance/raw/gd-agentic-web-runtime/SKILL.md
compatibility: reference-only
routes_to: []
aliases:
  - gd-agentic-web-runtime
---

# gd-agentic-web-runtime

## 目标

保留该混合来源的审计证据；它不是可激活 leaf，也不参与默认路由。

## 什么时候读取

仅在追踪迁移来源、许可证、哈希或历史实现时读取；产品任务必须选择四个正式 axis 上的 canonical leaf。

## 职责

- [读取完整保留内容](../../provenance/raw/gd-agentic-web-runtime/SKILL.md)
- 按保留内容中的直接链接继续读取脚本、场景、模板或资产。

## 不负责什么

不自动加载同轴其他节点，不复制其他岗位正文，不扩大默认兼容边界。

## 验证

迁移 manifest、catalog baseline 与目标文件 SHA-256 必须一致。
