---
km_id: memory.index
km_type: memory
domain: agent-memory
status: active
owner: maintainers
last_verified: 2026-07-24
source_of_truth:
  - docs/workflows/knowledge-map-maintenance.md
  - docs/references/constraints/implementation-status.md
validated_by:
  - python3 tools/docs_lint.py
  - godot --headless --path project-a -s tools/run_meta_tests.gd
tags:
  - memory:index
related:
  - workflow.knowledge-map-maintenance
  - quality.stale-docs
---

# 项目记忆入口

## 目标

只保存经过验证、会改变未来工作方式的重复经验；不保存聊天记录、猜测或一次性 debug 过程。

## 已验证经验

- 用户已明确当前实现根为 `project-a/`，使用 Godot 4.6.3、3D 表现、Web-first 发布并主要在手机浏览器运行。
- `taptap/` 仅保留为历史原型；当前 Godot 工程已使用 GL Compatibility，并已实现和验证 v2 Meta、工厂/培育、六人编队和三阶段战斗内核。
- Compatibility 配置不能替代 Web 交付证据；在 export preset、PWA、浏览器持久性探测、音频解锁、WebLifecycle 和真机 smoke 落地前，不得宣称 Web M0 已通过。
- `inventory/camp/quests/pity/stage_progress` 的可持久化字段目前只是扩展骨架，不得据此宣称完整装备、营地、任务、掉落、离线或长期关卡平衡已实现。

## 触发条件

出现重复误判、稳定操作经验、确认过的技术债或新事实推翻旧节点时。

## 以后怎么做

先更新对应 workflow/domain/reference；只有跨任务仍有价值的反馈才新增 memory 节点。

## 验证依据

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

## 相关节点

[KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md)。
