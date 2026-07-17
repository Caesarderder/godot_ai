---
km_id: runbook.docs-lint
km_type: runbook
domain: quality
status: active
owner: verification
last_verified: 2026-07-17
source_of_truth:
  - tools/docs_lint.py
validated_by:
  - python3 tools/docs_lint.py
tags:
  - lint:docs-lint
  - quality:docs-validation
related:
  - quality.lint-rules
  - workflow.knowledge-map-maintenance
---

# 文档 Lint Runbook

## 目标

用一个可失败命令验证知识地图结构、引用和事实路径。

## 前置条件

在仓库根目录运行；只需要 Python 3 标准库。

## docs-lint

```bash
python3 tools/docs_lint.py
```

辅助枚举：

```bash
rg '^km_id:' docs
rg 'KM:|CODE:|CMD:' docs
find docs -name '*.md' -print
```

## 预期结果

退出码 0，并输出节点数、链接数和 `docs lint: OK`。

## 失败处理

按错误中的文件与行号修复；不允许跳过缺失 frontmatter、重复 id、broken link、缺失命令锚点或不存在的事实路径。

## 相关节点

[KM:quality.lint-rules](../quality/lint-rules.md)。
