---
km_id: workflow.code-locating
km_type: workflow
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-21
source_of_truth:
  - docs/references/indexes/file-ownership.md
validated_by:
  - python3 tools/docs_lint.py
tags:
  - workflow:code-locating
related:
  - reference.file-ownership
  - reference.implementation-status
---

# 代码定位工作流

## 目标

从领域职责落到真实文件，同时避免把规划目录当作现有源码。

## 输入

功能、事件、状态字段、测试或故障现象。

## 步骤

1. 在 [KM:map.domains](../map/domains.md) 确认主领域。
2. 读 [KM:reference.file-ownership](../references/indexes/file-ownership.md)。
3. 使用 `rg --files project-a/game project-a/tests project-a/tools` 或在这些路径中 `rg '<symbol>'` 验证当前玩法路径和符号；同时检查 `project-a/project.godot` 的场景、插件与 Autoload 配置。
4. 如果 `project-a/game/**` 候选路径不存在，结论写“PRD 规划落点（draft）”；不得把暂停的 TapTap 原型或 `project-a/addons/godot_ai/**` 工具代码误当成当前领域实现。
5. 检查相关测试和 [KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。

## 停止条件

找到真实 owner、入口、测试和验证命令；或证实当前只有规划、没有实现。

## 验证

禁止只依据文件名推断。路径必须由 `rg --files`、配置或测试确认。

## 相关节点

[KM:reference.architecture-overview](../references/architecture/architecture-overview.md)。
